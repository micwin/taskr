package main

import (
	"context"
	"crypto/sha256"
	"errors"
	"fmt"
	"io/fs"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/mattn/go-shellwords"
	"github.com/spf13/cobra"
)

const (
	siteWatchPollInterval = 500 * time.Millisecond
	siteWatchDebounce     = 250 * time.Millisecond
)

type siteOpenOptions struct {
	regenerate bool
	watch      bool
	noBrowser  bool
	port       int
}

type sitePreviewHandler struct {
	directory  string
	watch      bool
	generation atomic.Uint64
}

func runSiteOpen(cmd *cobra.Command, rootPath, configFile string, terms []string, options siteOpenOptions) error {
	if options.port < 0 || options.port > 65535 {
		return exitError{code: 2, msg: fmt.Sprintf("invalid port %d", options.port)}
	}
	t, err := loadTree(rootPath)
	if err != nil {
		return err
	}
	target, ok := t.Config.siteDirectory(t.Root)
	if !ok {
		return exitError{code: 2, msg: "site is not initialized; run taskr site init <site-directory>"}
	}
	if options.regenerate {
		if _, _, err := generateSite(t, time.Now().UTC()); err != nil {
			return err
		}
	}
	if err := validateGeneratedSiteIndex(target); err != nil {
		return err
	}

	var browser []string
	if !options.noBrowser {
		browser, err = browserCommand(configFile)
		if err != nil {
			return err
		}
	}
	listener, err := sitePreviewListener(options.port)
	if err != nil {
		return err
	}
	defer listener.Close()

	selectedPort := listener.Addr().(*net.TCPAddr).Port
	page := "/index.html"
	if query := strings.TrimSpace(strings.Join(terms, " ")); query != "" {
		page = "/results.html?q=" + url.QueryEscape(query)
	}
	openURL := fmt.Sprintf("http://127.0.0.1:%d%s", selectedPort, page)
	fmt.Fprintf(cmd.OutOrStdout(), "serving site url=%s watch=%t\n", openURL, options.watch)

	handler := &sitePreviewHandler{directory: target, watch: options.watch}
	server := &http.Server{Handler: handler, ReadHeaderTimeout: 5 * time.Second}
	serverErrors := make(chan error, 1)
	go func() {
		err := server.Serve(listener)
		if errors.Is(err, http.ErrServerClosed) {
			err = nil
		}
		serverErrors <- err
	}()

	shutdown := func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		_ = server.Shutdown(ctx)
	}
	if !options.noBrowser {
		if err := startBrowser(browser, openURL); err != nil {
			shutdown()
			return err
		}
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	var watchErrors <-chan error
	if options.watch {
		fatal := make(chan error, 1)
		watchErrors = fatal
		go watchTaskrSite(ctx, cmd, t.Root, target, handler, fatal)
	}

	select {
	case <-ctx.Done():
		shutdown()
		return nil
	case err := <-serverErrors:
		if err == nil {
			return nil
		}
		return fmt.Errorf("site preview server failed: %w", err)
	case err := <-watchErrors:
		shutdown()
		return err
	}
}

func validateGeneratedSiteIndex(target string) error {
	if err := validateSiteMarker(target); err != nil {
		return err
	}
	info, err := os.Stat(filepath.Join(target, "index.html"))
	if errors.Is(err, fs.ErrNotExist) {
		return exitError{code: 2, msg: "generated site index is missing; run taskr site generate or use taskr site open --regenerate"}
	}
	if err != nil {
		return err
	}
	if !info.Mode().IsRegular() {
		return exitError{code: 2, msg: "generated site index is not a regular file; run taskr site generate"}
	}
	return nil
}

func sitePreviewListener(port int) (net.Listener, error) {
	if port != 0 {
		listener, err := net.Listen("tcp", net.JoinHostPort("127.0.0.1", strconv.Itoa(port)))
		if err != nil {
			return nil, fmt.Errorf("cannot bind requested site preview port %d: %w", port, err)
		}
		return listener, nil
	}
	listener, err := net.Listen("tcp", "127.0.0.1:80")
	if err == nil {
		return listener, nil
	}
	listener, fallbackErr := net.Listen("tcp", "127.0.0.1:0")
	if fallbackErr != nil {
		return nil, fmt.Errorf("cannot start site preview server: port 80: %v; dynamic port: %w", err, fallbackErr)
	}
	return listener, nil
}

func browserCommand(configFile string) ([]string, error) {
	config, err := loadPersonalConfig(configFile)
	if err != nil {
		return nil, err
	}
	command := config.Browser
	if command == "" {
		command = strings.TrimSpace(os.Getenv("BROWSER"))
	}
	if command == "" {
		return systemBrowserCommand(), nil
	}
	parser := shellwords.NewParser()
	arguments, err := parser.Parse(command)
	if err != nil {
		return nil, exitError{code: 2, msg: fmt.Sprintf("invalid browser command: %v", err)}
	}
	if len(arguments) == 0 {
		return nil, exitError{code: 2, msg: "browser command is empty"}
	}
	placeholders := 0
	for _, argument := range arguments {
		placeholders += strings.Count(argument, "{url}")
	}
	if placeholders > 1 {
		return nil, exitError{code: 2, msg: "browser command may contain at most one {url} placeholder"}
	}
	if _, err := exec.LookPath(arguments[0]); err != nil {
		return nil, exitError{code: 1, msg: fmt.Sprintf("browser executable %q not found in PATH", arguments[0])}
	}
	return arguments, nil
}

func systemBrowserCommand() []string {
	switch runtime.GOOS {
	case "darwin":
		return []string{"open"}
	case "windows":
		return []string{"rundll32", "url.dll,FileProtocolHandler"}
	default:
		return []string{"xdg-open"}
	}
}

func startBrowser(command []string, openURL string) error {
	arguments := append([]string(nil), command...)
	placeholder := false
	for index := range arguments {
		if strings.Contains(arguments[index], "{url}") {
			arguments[index] = strings.ReplaceAll(arguments[index], "{url}", openURL)
			placeholder = true
		}
	}
	if !placeholder {
		arguments = append(arguments, openURL)
	}
	path, err := exec.LookPath(arguments[0])
	if err != nil {
		return exitError{code: 1, msg: fmt.Sprintf("browser executable %q not found in PATH", arguments[0])}
	}
	process := exec.Command(path, arguments[1:]...)
	if err := process.Start(); err != nil {
		return fmt.Errorf("start browser: %w", err)
	}
	if err := process.Process.Release(); err != nil {
		return fmt.Errorf("release browser process: %w", err)
	}
	return nil
}

func (handler *sitePreviewHandler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if handler.watch && request.URL.Path == "/__taskr_generation" {
		writer.Header().Set("Cache-Control", "no-store")
		fmt.Fprint(writer, handler.generation.Load())
		return
	}
	if !strings.HasSuffix(request.URL.Path, ".html") {
		http.FileServer(http.Dir(handler.directory)).ServeHTTP(writer, request)
		return
	}
	clean := filepath.Clean(filepath.FromSlash(strings.TrimPrefix(request.URL.Path, "/")))
	if clean == "." || strings.HasPrefix(clean, "..") {
		http.NotFound(writer, request)
		return
	}
	content, err := os.ReadFile(filepath.Join(handler.directory, clean))
	if err != nil {
		http.NotFound(writer, request)
		return
	}
	if handler.watch {
		reload := fmt.Sprintf(`<script id="__taskr_reload">(()=>{let g=%d;setInterval(async()=>{try{const n=Number(await(await fetch('/__taskr_generation',{cache:'no-store'})).text());if(n!==g)location.reload()}catch(e){}},500)})()</script>`, handler.generation.Load())
		content = []byte(strings.Replace(string(content), "</body>", reload+"</body>", 1))
	}
	writer.Header().Set("Content-Type", "text/html; charset=utf-8")
	writer.Header().Set("Cache-Control", "no-store")
	_, _ = writer.Write(content)
}

func watchTaskrSite(ctx context.Context, cmd *cobra.Command, root, target string, handler *sitePreviewHandler, fatal chan<- error) {
	snapshot, err := taskrSourceSnapshot(root)
	if err != nil {
		fatal <- err
		return
	}
	ticker := time.NewTicker(siteWatchPollInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			next, err := taskrSourceSnapshot(root)
			if err != nil {
				fmt.Fprintf(cmd.ErrOrStderr(), "site regeneration failed: %v\n", err)
				continue
			}
			if snapshotsEqual(snapshot, next) {
				continue
			}
			snapshot = next
			select {
			case <-ctx.Done():
				return
			case <-time.After(siteWatchDebounce):
			}
			config, err := loadProjectConfig(root)
			if err != nil {
				fmt.Fprintf(cmd.ErrOrStderr(), "site regeneration failed: %v\n", err)
				continue
			}
			configured, ok := config.siteDirectory(root)
			if !ok || filepath.Clean(configured) != filepath.Clean(target) {
				fatal <- exitError{code: 1, msg: "site directory changed while preview server was running"}
				return
			}
			t, err := loadTree(root)
			if err != nil {
				fmt.Fprintf(cmd.ErrOrStderr(), "site regeneration failed: %v\n", err)
				continue
			}
			index, generatedAt, err := generateSite(t, time.Now().UTC())
			if err != nil {
				fmt.Fprintf(cmd.ErrOrStderr(), "site regeneration failed: %v\n", err)
				continue
			}
			handler.generation.Add(1)
			fmt.Fprintf(cmd.OutOrStdout(), "regenerated site index=%s generated_at=%s\n", index, generatedAt)
		}
	}
}

func taskrSourceSnapshot(root string) (map[string][sha256.Size]byte, error) {
	snapshot := map[string][sha256.Size]byte{}
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			return nil
		}
		name := entry.Name()
		relevant := name == "milestone.md" || name == "task.md" || name == "subtask.md" || path == filepath.Join(root, projectConfigName)
		if !relevant {
			return nil
		}
		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		relative, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		snapshot[relative] = sha256.Sum256(content)
		return nil
	})
	return snapshot, err
}

func snapshotsEqual(left, right map[string][sha256.Size]byte) bool {
	if len(left) != len(right) {
		return false
	}
	for path, digest := range left {
		if right[path] != digest {
			return false
		}
	}
	return true
}
