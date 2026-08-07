package main

import (
	"bufio"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

var version = "dev"
var commit = ""
var builtAt = ""

var markerTypes = map[string]string{
	"milestone.md": "milestone",
	"task.md":      "task",
	"subtask.md":   "subtask",
}

var typeMarkers = map[string]string{
	"milestone": "milestone.md",
	"task":      "task.md",
	"subtask":   "subtask.md",
}

var validStatuses = map[string]bool{
	"open":      true,
	"designing": true,
	"active":    true,
	"blocked":   true,
	"done":      true,
	"cancelled": true,
}

type exitError struct {
	code int
	msg  string
}

func (e exitError) Error() string {
	return e.msg
}

type item struct {
	ID         int
	IDText     string
	Slug       string
	Type       string
	Title      string
	Status     string
	Dir        string
	RelDir     string
	Marker     string
	MarkerPath string
	Parent     *item
	Children   []*item
}

type tree struct {
	Root       string
	Items      []*item
	ByID       map[string][]*item
	FileDirs   []string
	ArchiveDir string
}

func main() {
	rootPath, args := extractRootArg(os.Args[1:])
	cmd := newRootCommand(rootPath)
	cmd.SetArgs(args)

	if err := cmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(errorExitCode(err))
	}
}

func errorExitCode(err error) int {
	var coded exitError
	if errors.As(err, &coded) {
		return coded.code
	}
	return 1
}

func extractRootArg(args []string) (string, []string) {
	if len(args) == 0 {
		return "", args
	}
	if strings.HasPrefix(args[0], "-") || isCommandName(args[0]) {
		return "", args
	}
	return args[0], args[1:]
}

func isCommandName(name string) bool {
	switch name {
	case "archive", "completion", "create", "doctor", "help", "init", "list", "open", "report", "show", "status", "version":
		return true
	default:
		return false
	}
}

func newRootCommand(rootPath string) *cobra.Command {
	var configFile string

	cmd := &cobra.Command{
		Use:           "taskr [root] <command>",
		Short:         "Local-first task management for command-line workflows",
		SilenceErrors: true,
		SilenceUsage:  true,
	}
	cmd.PersistentFlags().StringVar(&configFile, "config-file", "", "personal config file")

	cmd.AddCommand(
		initCommand(rootPath),
		doctorCommand(rootPath),
		createCommand(rootPath),
		showCommand(rootPath),
		listCommand(rootPath),
		statusCommand(rootPath),
		openCommand(rootPath),
		reportCommand(rootPath),
		archiveCommand(rootPath),
		versionCommand(),
	)

	return cmd
}

func initCommand(rootPath string) *cobra.Command {
	return &cobra.Command{
		Use:   "init",
		Short: "Initialize a Taskr worktree",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			root := rootPath
			if root == "" {
				root = "taskr"
			}
			created, err := initializeRoot(root)
			if err != nil {
				return err
			}
			t, err := loadTree(root)
			if err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "initialized root=%s created=%t files=%d\n", t.Root, created, len(t.FileDirs))
			return nil
		},
	}
}

func doctorCommand(rootPath string) *cobra.Command {
	return &cobra.Command{
		Use:   "doctor",
		Short: "Validate a Taskr root",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "ok root=%s items=%d files=%d\n", t.Root, len(t.Items), len(t.FileDirs))
			return nil
		},
	}
}

func createCommand(rootPath string) *cobra.Command {
	var under, slug string
	var edit, noEdit bool

	cmd := &cobra.Command{
		Use:   "create <type> <title>",
		Short: "Create a new item",
		Args:  cobra.MinimumNArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runCreate(cmd, rootPath, args[0], strings.Join(args[1:], " "), under, slug, edit, noEdit)
		},
	}
	cmd.Flags().StringVar(&under, "under", "", "parent item selector")
	cmd.Flags().StringVar(&slug, "slug", "", "directory slug override")
	cmd.Flags().BoolVar(&edit, "edit", false, "open marker in editor after creation")
	cmd.Flags().BoolVar(&noEdit, "no-edit", false, "do not open marker in editor after creation")
	return cmd
}

func showCommand(rootPath string) *cobra.Command {
	return &cobra.Command{
		Use:   "show <selector>",
		Short: "Show one item",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			it, err := resolveItem(t, args[0])
			if err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "id=%s type=%s status=%s title=%q path=%s\n", it.IDText, it.Type, it.Status, it.Title, it.RelDir)
			return nil
		},
	}
}

func listCommand(rootPath string) *cobra.Command {
	var under, typeFilter, statusFilter string

	cmd := &cobra.Command{
		Use:   "list",
		Short: "List items",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			items, err := filteredItems(t, under, typeFilter, statusFilter)
			if err != nil {
				return err
			}
			writeItemLines(cmd.OutOrStdout(), items, true)
			return nil
		},
	}
	cmd.Flags().StringVar(&under, "under", "", "parent item selector")
	cmd.Flags().StringVar(&typeFilter, "type", "", "item type filter")
	cmd.Flags().StringVar(&statusFilter, "status", "", "item status filter")
	return cmd
}

func statusCommand(rootPath string) *cobra.Command {
	return &cobra.Command{
		Use:   "status <selector> <status>",
		Short: "Change item status",
		Args:  cobra.ExactArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			if !validStatuses[args[1]] {
				return exitError{code: 2, msg: fmt.Sprintf("invalid status %q", args[1])}
			}
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			it, err := resolveItem(t, args[0])
			if err != nil {
				return err
			}
			if args[1] == "done" {
				if blockers := unfinishedChildren(it); len(blockers) > 0 {
					return exitError{code: 2, msg: fmt.Sprintf("unfinished children block done for %s: %s", it.IDText, strings.Join(blockers, ", "))}
				}
			}
			if err := updateMarkerField(it.MarkerPath, "status", args[1]); err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "status id=%s old=%s new=%s\n", it.IDText, it.Status, args[1])
			return nil
		},
	}
}

func openCommand(rootPath string) *cobra.Command {
	var system bool

	cmd := &cobra.Command{
		Use:   "open <selector>",
		Short: "Open an item marker",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			it, err := resolveItem(t, args[0])
			if err != nil {
				return err
			}
			opener := "editor"
			if system {
				opener = "system"
			}
			if err := openPath(it.MarkerPath, system); err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "opened path=%s/%s opener=%s\n", it.RelDir, it.Marker, opener)
			return nil
		},
	}
	cmd.Flags().BoolVar(&system, "system", false, "open with the system opener")
	return cmd
}

func reportCommand(rootPath string) *cobra.Command {
	var under, typeFilter, statusFilter, output string

	cmd := &cobra.Command{
		Use:   "report",
		Short: "Render an item report",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			items, err := filteredItems(t, under, typeFilter, statusFilter)
			if err != nil {
				return err
			}
			var b strings.Builder
			fmt.Fprintf(&b, "report root=%s", t.Root)
			if under != "" {
				fmt.Fprintf(&b, " under=%s", under)
			}
			if typeFilter != "" {
				fmt.Fprintf(&b, " type=%s", typeFilter)
			}
			if statusFilter != "" {
				fmt.Fprintf(&b, " status=%s", statusFilter)
			}
			b.WriteByte('\n')
			writeItemLines(&b, items, false)
			if output != "" {
				if err := os.WriteFile(output, []byte(b.String()), 0o644); err != nil {
					return exitError{code: 1, msg: fmt.Sprintf("write report output %s: %v", output, err)}
				}
				fmt.Fprintf(cmd.OutOrStdout(), "wrote report path=%s\n", output)
				return nil
			}
			fmt.Fprint(cmd.OutOrStdout(), b.String())
			return nil
		},
	}
	cmd.Flags().StringVar(&under, "under", "", "parent item selector")
	cmd.Flags().StringVar(&typeFilter, "type", "", "item type filter")
	cmd.Flags().StringVar(&statusFilter, "status", "", "item status filter")
	cmd.Flags().StringVar(&output, "output", "", "write report to file")
	return cmd
}

func archiveCommand(rootPath string) *cobra.Command {
	var to string

	cmd := &cobra.Command{
		Use:   "archive <selector>",
		Short: "Archive a closed subtree",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			it, err := resolveItem(t, args[0])
			if err != nil {
				return err
			}
			if it.Status != "done" {
				return exitError{code: 2, msg: fmt.Sprintf("cannot archive %s: status is %s, not closed", it.IDText, it.Status)}
			}
			if blockers := unfinishedChildren(it); len(blockers) > 0 {
				return exitError{code: 2, msg: fmt.Sprintf("cannot archive %s: unfinished children %s", it.IDText, strings.Join(blockers, ", "))}
			}
			destRel := filepath.Join(t.ArchiveDir, to, filepath.Base(it.Dir))
			dest := filepath.Join(t.Root, destRel)
			if err := os.MkdirAll(filepath.Dir(dest), 0o755); err != nil {
				return err
			}
			if _, err := os.Stat(dest); err == nil {
				return exitError{code: 2, msg: fmt.Sprintf("archive destination exists: %s", destRel)}
			}
			if err := os.Rename(it.Dir, dest); err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "archived id=%s to=%s\n", it.IDText, filepath.ToSlash(destRel))
			return nil
		},
	}
	cmd.Flags().StringVar(&to, "to", "", "archive destination below root archive directory")
	return cmd
}

func versionCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print Taskr version",
		Args:  cobra.NoArgs,
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Fprintf(cmd.OutOrStdout(), "taskr version %s", version)
			if commit != "" {
				fmt.Fprintf(cmd.OutOrStdout(), " commit=%s", commit)
			}
			if builtAt != "" {
				fmt.Fprintf(cmd.OutOrStdout(), " built_at=%s", builtAt)
			}
			fmt.Fprintln(cmd.OutOrStdout())
		},
	}
}

func initializeRoot(root string) (bool, error) {
	created := false
	if _, err := os.Stat(root); errors.Is(err, fs.ErrNotExist) {
		if err := os.MkdirAll(root, 0o755); err != nil {
			return false, err
		}
		created = true
	} else if err != nil {
		return false, err
	}

	filesDir := filepath.Join(root, "files")
	filesMarker := filepath.Join(filesDir, "files.md")
	if _, err := os.Stat(filesMarker); errors.Is(err, fs.ErrNotExist) {
		if err := os.MkdirAll(filesDir, 0o755); err != nil {
			return false, err
		}
		if err := os.WriteFile(filesMarker, []byte(newFilesMarker("Root files")), 0o644); err != nil {
			return false, err
		}
		created = true
	} else if err != nil {
		return false, err
	}
	return created, nil
}

func runCreate(cmd *cobra.Command, rootPath, itemType, title, under, slug string, edit, noEdit bool) error {
	marker, ok := typeMarkers[itemType]
	if !ok {
		return exitError{code: 2, msg: fmt.Sprintf("invalid item type %q", itemType)}
	}
	t, err := loadTreeAllowEmpty(rootPath)
	if err != nil {
		return err
	}
	var parent *item
	if under != "" {
		parent, err = resolveItem(t, under)
		if err != nil {
			return err
		}
	}
	if err := validateChildType(parent, itemType); err != nil {
		return err
	}
	if slug == "" {
		slug = slugify(title)
	} else {
		slug = slugify(slug)
	}
	if slug == "" {
		return exitError{code: 2, msg: "slug is empty"}
	}
	id := nextID(t.Items)
	idText := fmt.Sprintf("%03d", id)
	baseDir := t.Root
	if parent != nil {
		baseDir = parent.Dir
	}
	if existing := existingSlugDir(baseDir, slug); existing != "" {
		return exitError{code: 2, msg: fmt.Sprintf("duplicate slug or directory exists: %s", existing)}
	}
	dir := filepath.Join(baseDir, idText+"-"+slug)
	if _, err := os.Stat(dir); err == nil {
		return exitError{code: 2, msg: fmt.Sprintf("duplicate slug or directory exists: %s", filepath.Base(dir))}
	} else if !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	markerPath := filepath.Join(dir, marker)
	if err := os.WriteFile(markerPath, []byte(newMarker(title)), 0o644); err != nil {
		return err
	}
	opened := false
	if edit && !noEdit {
		if err := openPath(markerPath, false); err != nil {
			return err
		}
		opened = true
	}
	rel, _ := filepath.Rel(t.Root, dir)
	fmt.Fprintf(cmd.OutOrStdout(), "created item id=%s path=%s marker=%s opened=%t\n", idText, filepath.ToSlash(rel), marker, opened)
	return nil
}

func loadTree(rootPath string) (*tree, error) {
	t, err := loadTreeAllowEmpty(rootPath)
	if err != nil {
		return nil, err
	}
	return t, nil
}

func loadTreeAllowEmpty(rootPath string) (*tree, error) {
	root, err := discoverRoot(rootPath)
	if err != nil {
		return nil, err
	}
	info, err := os.Stat(root)
	if err != nil {
		return nil, exitError{code: 1, msg: fmt.Sprintf("root not found: %s", root)}
	}
	if !info.IsDir() {
		return nil, exitError{code: 1, msg: fmt.Sprintf("root is not a directory: %s", root)}
	}
	abs, err := filepath.Abs(root)
	if err != nil {
		return nil, err
	}
	t := &tree{Root: abs, ByID: map[string][]*item{}, ArchiveDir: "archive"}
	if err := scanDir(t, abs, nil); err != nil {
		return nil, err
	}
	sortItems(t.Items)
	for _, it := range t.Items {
		t.ByID[it.IDText] = append(t.ByID[it.IDText], it)
	}
	for id, items := range t.ByID {
		if len(items) > 1 {
			return nil, exitError{code: 2, msg: fmt.Sprintf("duplicate id %s", id)}
		}
	}
	return t, nil
}

func discoverRoot(rootPath string) (string, error) {
	if rootPath != "" {
		return rootPath, nil
	}
	current := "."
	subdir := "taskr"
	if isTaskrRoot(current) {
		return current, nil
	}
	if isTaskrRoot(subdir) {
		return subdir, nil
	}
	return current, nil
}

func isTaskrRoot(path string) bool {
	info, err := os.Stat(path)
	if err != nil || !info.IsDir() {
		return false
	}
	entries, err := os.ReadDir(path)
	if err != nil {
		return false
	}
	for _, entry := range entries {
		name := entry.Name()
		if !entry.IsDir() {
			if _, ok := markerTypes[name]; ok || name == "files.md" {
				return true
			}
			continue
		}
		childEntries, err := os.ReadDir(filepath.Join(path, name))
		if err != nil {
			continue
		}
		for _, child := range childEntries {
			childName := child.Name()
			if _, ok := markerTypes[childName]; ok || childName == "files.md" {
				return true
			}
		}
	}
	return false
}

func scanDir(t *tree, dir string, parent *item) error {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return err
	}
	markers := make([]string, 0, 2)
	hasFiles := false
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if _, ok := markerTypes[name]; ok {
			markers = append(markers, name)
		}
		if name == "files.md" {
			hasFiles = true
		}
	}
	rel := relPath(t.Root, dir)
	if hasFiles {
		t.FileDirs = append(t.FileDirs, rel)
		return nil
	}
	current := parent
	if len(markers) > 1 {
		return exitError{code: 2, msg: fmt.Sprintf("invalid marker structure in %s: multiple marker files", rel)}
	}
	if len(markers) == 1 {
		it, err := readItem(t.Root, dir, markers[0], parent)
		if err != nil {
			return err
		}
		t.Items = append(t.Items, it)
		if parent != nil {
			parent.Children = append(parent.Children, it)
		}
		current = it
	} else if rel != "." && !isArchivePath(rel) {
		return exitError{code: 2, msg: fmt.Sprintf("invalid marker structure in %s: missing marker file", rel)}
	}
	for _, entry := range entries {
		if entry.IsDir() {
			if err := scanDir(t, filepath.Join(dir, entry.Name()), current); err != nil {
				return err
			}
		}
	}
	return nil
}

func readItem(root, dir, marker string, parent *item) (*item, error) {
	idText, slug, err := parseDirName(filepath.Base(dir))
	if err != nil {
		return nil, exitError{code: 2, msg: fmt.Sprintf("%s: %v", relPath(root, dir), err)}
	}
	id, _ := strconv.Atoi(idText)
	fields, err := parseFrontmatter(filepath.Join(dir, marker))
	if err != nil {
		return nil, err
	}
	title := fields["title"]
	if title == "" {
		return nil, exitError{code: 2, msg: fmt.Sprintf("%s: missing title", relPath(root, dir))}
	}
	status := fields["status"]
	if status == "" {
		status = "open"
	}
	if !validStatuses[status] {
		return nil, exitError{code: 2, msg: fmt.Sprintf("%s: invalid status %q", relPath(root, dir), status)}
	}
	return &item{
		ID:         id,
		IDText:     idText,
		Slug:       slug,
		Type:       markerTypes[marker],
		Title:      title,
		Status:     status,
		Dir:        dir,
		RelDir:     relPath(root, dir),
		Marker:     marker,
		MarkerPath: filepath.Join(dir, marker),
		Parent:     parent,
	}, nil
}

func parseFrontmatter(path string) (map[string]string, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	scanner := bufio.NewScanner(f)
	if !scanner.Scan() || strings.TrimSpace(scanner.Text()) != "---" {
		return nil, exitError{code: 2, msg: fmt.Sprintf("%s: missing frontmatter", path)}
	}
	fields := map[string]string{}
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "---" {
			return fields, scanner.Err()
		}
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, ok := strings.Cut(line, ":")
		if !ok {
			continue
		}
		fields[strings.TrimSpace(key)] = strings.Trim(strings.TrimSpace(value), `"'`)
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return nil, exitError{code: 2, msg: fmt.Sprintf("%s: unterminated frontmatter", path)}
}

func parseDirName(name string) (string, string, error) {
	id, slug, ok := strings.Cut(name, "-")
	if !ok || id == "" || slug == "" {
		return "", "", fmt.Errorf("directory name must start with id-")
	}
	if _, err := strconv.Atoi(id); err != nil {
		return "", "", fmt.Errorf("invalid directory id %q", id)
	}
	return id, slug, nil
}

func resolveItem(t *tree, selector string) (*item, error) {
	selector = strings.TrimSpace(selector)
	if selector == "" {
		return nil, exitError{code: 2, msg: "empty selector"}
	}
	if matches := t.ByID[selector]; len(matches) == 1 {
		return matches[0], nil
	}
	if strings.Contains(selector, "/") {
		clean := filepath.Clean(selector)
		for _, it := range t.Items {
			if it.RelDir == clean || filepath.ToSlash(it.RelDir) == selector {
				return it, nil
			}
		}
		return nil, exitError{code: 2, msg: fmt.Sprintf("no match for selector %q", selector)}
	}
	var matches []*item
	lower := strings.ToLower(selector)
	for _, it := range t.Items {
		if strings.EqualFold(it.Slug, selector) || strings.EqualFold(it.Title, selector) ||
			strings.Contains(strings.ToLower(it.Slug), lower) || strings.Contains(strings.ToLower(it.Title), lower) {
			matches = append(matches, it)
		}
	}
	if len(matches) == 0 {
		return nil, exitError{code: 2, msg: fmt.Sprintf("no match for selector %q", selector)}
	}
	if len(matches) > 1 {
		return nil, exitError{code: 2, msg: fmt.Sprintf("ambiguous selector %q; candidates: %s", selector, candidateList(matches))}
	}
	return matches[0], nil
}

func resolveUnder(t *tree, under string) ([]*item, error) {
	if under == "" {
		return t.Items, nil
	}
	if strings.Contains(under, "/") {
		prefix := filepath.ToSlash(filepath.Clean(under))
		var items []*item
		for _, it := range t.Items {
			rel := filepath.ToSlash(it.RelDir)
			if strings.HasPrefix(rel, prefix+"/") || rel == prefix {
				items = append(items, it)
			}
		}
		if len(items) == 0 {
			return nil, exitError{code: 2, msg: fmt.Sprintf("no match for parent %q", under)}
		}
		return items, nil
	}
	parent, err := resolveItem(t, under)
	if err != nil {
		return nil, err
	}
	return descendants(parent), nil
}

func filteredItems(t *tree, under, typeFilter, statusFilter string) ([]*item, error) {
	if typeFilter != "" {
		if _, ok := typeMarkers[typeFilter]; !ok {
			return nil, exitError{code: 2, msg: fmt.Sprintf("invalid type %q", typeFilter)}
		}
	}
	if statusFilter != "" && !validStatuses[statusFilter] {
		return nil, exitError{code: 2, msg: fmt.Sprintf("invalid status %q", statusFilter)}
	}
	items, err := resolveUnder(t, under)
	if err != nil {
		return nil, err
	}
	var out []*item
	for _, it := range items {
		if typeFilter != "" && it.Type != typeFilter {
			continue
		}
		if statusFilter != "" && it.Status != statusFilter {
			continue
		}
		out = append(out, it)
	}
	sortItems(out)
	return out, nil
}

func descendants(parent *item) []*item {
	var out []*item
	var walk func(*item)
	walk = func(it *item) {
		for _, child := range it.Children {
			out = append(out, child)
			walk(child)
		}
	}
	walk(parent)
	return out
}

func unfinishedChildren(parent *item) []string {
	var blockers []string
	var walk func(*item)
	walk = func(it *item) {
		for _, child := range it.Children {
			if child.Status != "done" {
				blockers = append(blockers, child.IDText)
			}
			walk(child)
		}
	}
	walk(parent)
	return blockers
}

func validateChildType(parent *item, childType string) error {
	if parent == nil {
		if childType != "milestone" {
			return exitError{code: 2, msg: fmt.Sprintf("cannot create %s without parent; use --under", childType)}
		}
		return nil
	}
	allowed := map[string]string{
		"milestone": "task",
		"task":      "subtask",
	}
	if allowed[parent.Type] != childType {
		return exitError{code: 2, msg: fmt.Sprintf("cannot create %s under %s", childType, parent.Type)}
	}
	return nil
}

func nextID(items []*item) int {
	maxID := 0
	for _, it := range items {
		if it.ID > maxID {
			maxID = it.ID
		}
	}
	return maxID + 1
}

func existingSlugDir(baseDir, slug string) string {
	entries, err := os.ReadDir(baseDir)
	if err != nil {
		return ""
	}
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		_, existingSlug, err := parseDirName(entry.Name())
		if err == nil && existingSlug == slug {
			return entry.Name()
		}
	}
	return ""
}

func newMarker(title string) string {
	now := time.Now().UTC().Format(time.RFC3339)
	return fmt.Sprintf(`---
title: %s
status: open
created_at: %s
updated_at: %s
---

# Description

# Acceptance

# Comments

# Outcome
`, title, now, now)
}

func newFilesMarker(title string) string {
	now := time.Now().UTC().Format(time.RFC3339)
	return fmt.Sprintf(`---
title: %s
created_at: %s
updated_at: %s
---

# Description

# Acceptance

# Comments

# Outcome
`, title, now, now)
}

func updateMarkerField(path, key, value string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	lines := strings.Split(string(data), "\n")
	inFrontmatter := false
	updated := false
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if i == 0 && trimmed == "---" {
			inFrontmatter = true
			continue
		}
		if inFrontmatter && trimmed == "---" {
			break
		}
		if inFrontmatter && strings.HasPrefix(trimmed, key+":") {
			lines[i] = key + ": " + value
			updated = true
		}
	}
	if !updated {
		return exitError{code: 2, msg: fmt.Sprintf("%s: missing frontmatter field %s", path, key)}
	}
	return os.WriteFile(path, []byte(strings.Join(lines, "\n")), 0o644)
}

func openPath(path string, system bool) error {
	var command string
	var args []string
	if system {
		command = "xdg-open"
		args = []string{path}
	} else {
		command = os.Getenv("EDITOR")
		if command == "" {
			return exitError{code: 2, msg: "editor opener is not configured"}
		}
		args = []string{path}
	}
	cmd := exec.Command(command, args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return exitError{code: 1, msg: fmt.Sprintf("opener failed: %v", err)}
	}
	return nil
}

func writeItemLines(w interface{ Write([]byte) (int, error) }, items []*item, withType bool) {
	for _, it := range items {
		if withType {
			fmt.Fprintf(w, "%s %s %s %s\n", it.IDText, it.Type, it.Status, it.Title)
		} else {
			fmt.Fprintf(w, "%s %s %s\n", it.IDText, it.Status, it.Title)
		}
	}
}

func sortItems(items []*item) {
	sort.Slice(items, func(i, j int) bool {
		if items[i].ID == items[j].ID {
			return items[i].RelDir < items[j].RelDir
		}
		return items[i].ID < items[j].ID
	})
}

func relPath(root, path string) string {
	rel, err := filepath.Rel(root, path)
	if err != nil {
		return path
	}
	return filepath.ToSlash(rel)
}

func isArchivePath(rel string) bool {
	rel = filepath.ToSlash(rel)
	return rel == "archive" || strings.HasPrefix(rel, "archive/")
}

func candidateList(items []*item) string {
	sortItems(items)
	parts := make([]string, 0, len(items))
	for _, it := range items {
		parts = append(parts, it.IDText)
	}
	return strings.Join(parts, ", ")
}

var nonSlug = regexp.MustCompile(`[^a-z0-9]+`)

func slugify(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	s = nonSlug.ReplaceAllString(s, "-")
	return strings.Trim(s, "-")
}
