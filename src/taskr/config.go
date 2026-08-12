package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/pelletier/go-toml/v2"
)

const projectConfigName = "taskr.toml"

const (
	siteMarkerName    = ".taskr-site"
	siteMarkerContent = "taskr-site-v1\n"
)

type projectConfig struct {
	Site *siteProjectConfig `toml:"site"`
}

type siteProjectConfig struct {
	Directory string `toml:"directory"`
}

func loadProjectConfig(root string) (projectConfig, error) {
	path := filepath.Join(root, projectConfigName)
	f, err := os.Open(path)
	if errors.Is(err, fs.ErrNotExist) {
		return projectConfig{}, nil
	}
	if err != nil {
		return projectConfig{}, exitError{code: 2, msg: fmt.Sprintf("%s: cannot read project configuration: %v", path, err)}
	}
	defer f.Close()

	var config projectConfig
	decoder := toml.NewDecoder(f)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&config); err != nil {
		return projectConfig{}, exitError{code: 2, msg: fmt.Sprintf("%s: invalid project configuration: %s", path, projectConfigError(err))}
	}
	if config.Site != nil {
		if strings.TrimSpace(config.Site.Directory) == "" {
			return projectConfig{}, exitError{code: 2, msg: fmt.Sprintf("%s: site.directory must not be empty", path)}
		}
		if strings.ContainsRune(config.Site.Directory, '\x00') {
			return projectConfig{}, exitError{code: 2, msg: fmt.Sprintf("%s: site.directory contains a NUL byte", path)}
		}
	}
	return config, nil
}

func projectConfigError(err error) string {
	var unknown *toml.StrictMissingError
	if errors.As(err, &unknown) {
		keys := make([]string, 0, len(unknown.Errors))
		for i := range unknown.Errors {
			keys = append(keys, strings.Join(unknown.Errors[i].Key(), "."))
		}
		sort.Strings(keys)
		return fmt.Sprintf("unknown project configuration key %q", strings.Join(keys, ", "))
	}
	return err.Error()
}

func (config projectConfig) siteDirectory(root string) (string, bool) {
	if config.Site == nil {
		return "", false
	}
	directory := config.Site.Directory
	if !filepath.IsAbs(directory) {
		directory = filepath.Join(root, directory)
	}
	return filepath.Clean(directory), true
}

func validateConfiguredSite(root string, config projectConfig) error {
	directory, ok := config.siteDirectory(root)
	if !ok {
		return nil
	}
	if pathsOverlap(root, directory) {
		return exitError{code: 2, msg: fmt.Sprintf("unsafe site directory overlaps Taskr root: %s", directory)}
	}

	info, err := os.Lstat(directory)
	if errors.Is(err, fs.ErrNotExist) {
		return nil
	}
	if err != nil {
		return exitError{code: 2, msg: fmt.Sprintf("cannot inspect site directory %s: %v", directory, err)}
	}
	if info.Mode()&os.ModeSymlink != 0 {
		return exitError{code: 2, msg: fmt.Sprintf("site directory must not be a symlink: %s", directory)}
	}
	if !info.IsDir() {
		return exitError{code: 2, msg: fmt.Sprintf("site directory is not a directory: %s", directory)}
	}
	entries, err := os.ReadDir(directory)
	if err != nil {
		return exitError{code: 2, msg: fmt.Sprintf("cannot read site directory %s: %v", directory, err)}
	}
	if len(entries) == 0 {
		return nil
	}
	return validateSiteMarker(directory)
}

func initializeSite(root, argument string, createIfMissing bool) (string, bool, bool, error) {
	storedDirectory := filepath.Clean(argument)
	target := storedDirectory
	if !filepath.IsAbs(target) {
		target = filepath.Join(root, target)
	}
	target, err := filepath.Abs(target)
	if err != nil {
		return "", false, false, err
	}
	target = filepath.Clean(target)
	if pathsOverlap(root, target) {
		return "", false, false, exitError{code: 2, msg: fmt.Sprintf("site directory must not overlap Taskr root: %s", target)}
	}

	config, err := loadProjectConfig(root)
	if err != nil {
		return "", false, false, err
	}
	if configured, ok := config.siteDirectory(root); ok && filepath.Clean(configured) != target {
		return "", false, false, exitError{code: 2, msg: fmt.Sprintf("site is already initialized with directory %s", configured)}
	}

	created := false
	creationRoot := ""
	markerNeeded := false
	info, err := os.Lstat(target)
	if errors.Is(err, fs.ErrNotExist) {
		if !createIfMissing {
			return "", false, false, exitError{code: 2, msg: fmt.Sprintf("site directory does not exist: %s (use --create-if-missing)", target)}
		}
		creationRoot = firstMissingPath(target)
		if err := os.MkdirAll(target, 0o755); err != nil {
			return "", false, false, fmt.Errorf("create site directory %s: %w", target, err)
		}
		created = true
		markerNeeded = true
	} else if err != nil {
		return "", false, false, exitError{code: 2, msg: fmt.Sprintf("cannot inspect site directory %s: %v", target, err)}
	} else {
		if info.Mode()&os.ModeSymlink != 0 {
			return "", false, false, exitError{code: 2, msg: fmt.Sprintf("site directory must not be a symlink: %s", target)}
		}
		if !info.IsDir() {
			return "", false, false, exitError{code: 2, msg: fmt.Sprintf("site path is not a directory: %s", target)}
		}
		entries, readErr := os.ReadDir(target)
		if readErr != nil {
			return "", false, false, exitError{code: 2, msg: fmt.Sprintf("cannot read site directory %s: %v", target, readErr)}
		}
		if len(entries) == 0 {
			markerNeeded = true
		} else if err := validateSiteMarker(target); err != nil {
			return "", false, false, err
		}
	}

	markerChanged := false
	if markerNeeded {
		if err := os.WriteFile(filepath.Join(target, siteMarkerName), []byte(siteMarkerContent), 0o644); err != nil {
			rollbackCreatedPath(creationRoot)
			return "", false, false, fmt.Errorf("write site ownership marker: %w", err)
		}
		markerChanged = true
	}

	configChanged := config.Site == nil
	if configChanged {
		if err := appendSiteProjectConfig(root, storedDirectory); err != nil {
			if markerChanged {
				_ = os.Remove(filepath.Join(target, siteMarkerName))
			}
			rollbackCreatedPath(creationRoot)
			return "", false, false, err
		}
	}

	return target, created, created || markerChanged || configChanged, nil
}

func validateSiteMarker(directory string) error {
	path := filepath.Join(directory, siteMarkerName)
	info, err := os.Lstat(path)
	if errors.Is(err, fs.ErrNotExist) {
		return exitError{code: 2, msg: fmt.Sprintf("nonempty site directory has no Taskr ownership marker: %s", directory)}
	}
	if err != nil {
		return exitError{code: 2, msg: fmt.Sprintf("cannot inspect site ownership marker %s: %v", path, err)}
	}
	if !info.Mode().IsRegular() {
		return exitError{code: 2, msg: fmt.Sprintf("invalid site ownership marker: %s", path)}
	}
	content, err := os.ReadFile(path)
	if err != nil {
		return exitError{code: 2, msg: fmt.Sprintf("cannot read site ownership marker %s: %v", path, err)}
	}
	if string(content) != siteMarkerContent {
		return exitError{code: 2, msg: fmt.Sprintf("invalid site ownership marker: %s", path)}
	}
	return nil
}

func appendSiteProjectConfig(root, directory string) error {
	path := filepath.Join(root, projectConfigName)
	original, err := os.ReadFile(path)
	mode := fs.FileMode(0o644)
	if err == nil {
		if info, statErr := os.Stat(path); statErr == nil {
			mode = info.Mode().Perm()
		}
	} else if !errors.Is(err, fs.ErrNotExist) {
		return fmt.Errorf("read project configuration %s: %w", path, err)
	}

	encodedDirectory, err := json.Marshal(directory)
	if err != nil {
		return fmt.Errorf("encode project configuration: %w", err)
	}
	section := []byte(fmt.Sprintf("[site]\ndirectory = %s\n", encodedDirectory))
	content := append([]byte(nil), original...)
	if len(content) > 0 && content[len(content)-1] != '\n' {
		content = append(content, '\n')
	}
	if len(content) > 0 {
		content = append(content, '\n')
	}
	content = append(content, section...)

	temporary, err := os.CreateTemp(root, ".taskr.toml-*")
	if err != nil {
		return fmt.Errorf("create temporary project configuration: %w", err)
	}
	temporaryPath := temporary.Name()
	defer os.Remove(temporaryPath)
	if err := temporary.Chmod(mode); err != nil {
		temporary.Close()
		return fmt.Errorf("set project configuration permissions: %w", err)
	}
	if _, err := temporary.Write(content); err != nil {
		temporary.Close()
		return fmt.Errorf("write project configuration: %w", err)
	}
	if err := temporary.Close(); err != nil {
		return fmt.Errorf("close project configuration: %w", err)
	}
	if err := os.Rename(temporaryPath, path); err != nil {
		return fmt.Errorf("replace project configuration: %w", err)
	}
	return nil
}

func pathsOverlap(first, second string) bool {
	return pathContains(first, second) || pathContains(second, first)
}

func pathContains(parent, child string) bool {
	relative, err := filepath.Rel(filepath.Clean(parent), filepath.Clean(child))
	if err != nil {
		return false
	}
	return relative == "." || (relative != ".." && !strings.HasPrefix(relative, ".."+string(filepath.Separator)))
}

func firstMissingPath(path string) string {
	missing := filepath.Clean(path)
	for {
		parent := filepath.Dir(missing)
		if _, err := os.Lstat(parent); err == nil {
			return missing
		}
		if parent == missing {
			return path
		}
		missing = parent
	}
}

func rollbackCreatedPath(path string) {
	if path != "" {
		_ = os.RemoveAll(path)
	}
}
