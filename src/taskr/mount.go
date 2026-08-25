package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

const (
	mountReadOnly  = "read-only"
	mountReadWrite = "read-write"
)

var mountIDPattern = regexp.MustCompile(`^[a-z][a-z0-9-]*$`)

func validMountID(id string) bool { return mountIDPattern.MatchString(id) }

func validMountMode(mode string) bool {
	return mode == mountReadOnly || mode == mountReadWrite
}

func ensureWritableItem(it *item, operation string) error {
	if it.IsMount {
		return exitError{code: 2, msg: fmt.Sprintf("cannot %s mount object %s", operation, it.IDText)}
	}
	if it.MountID != "" && it.MountMode != mountReadWrite {
		return exitError{code: 2, msg: fmt.Sprintf("cannot %s read-only mounted item %s", operation, it.IDText)}
	}
	return nil
}

func mountedSourcePrefix(it *item) string {
	if it.MountID == "" {
		return ""
	}
	return fmt.Sprintf("source=%s (%s) ", it.MountID, it.MountName)
}

func itemsInRoot(items []*item, root string) []*item {
	var selected []*item
	for _, it := range items {
		if !it.IsMount && filepath.Clean(it.Root) == filepath.Clean(root) {
			selected = append(selected, it)
		}
	}
	return selected
}

func resolveItemForRoot(t *tree, selector, root string) (*item, error) {
	if strings.Contains(selector, ":") || strings.HasPrefix(selector, ".:") {
		it, err := resolveItem(t, selector)
		if err != nil {
			return nil, err
		}
		if filepath.Clean(it.Root) != filepath.Clean(root) {
			return nil, exitError{code: 2, msg: fmt.Sprintf("cross-root selector %q belongs to a different Taskr root", selector)}
		}
		return it, nil
	}
	var matches []*item
	lower := strings.ToLower(selector)
	for _, it := range t.Items {
		if it.IsMount || filepath.Clean(it.Root) != filepath.Clean(root) {
			continue
		}
		if it.LocalID == selector || strings.EqualFold(it.Slug, selector) || strings.EqualFold(it.Title, selector) ||
			strings.Contains(strings.ToLower(it.Slug), lower) || strings.Contains(strings.ToLower(it.Title), lower) {
			matches = append(matches, it)
		}
	}
	if len(matches) == 0 {
		return nil, exitError{code: 2, msg: fmt.Sprintf("no match for selector %q", selector)}
	}
	if len(matches) > 1 {
		return nil, exitError{code: 2, msg: fmt.Sprintf("ambiguous selector %q; candidates:%s", selector, candidateList(matches))}
	}
	return matches[0], nil
}

func mountedRootPath(ownerRoot string, mount mountProjectConfig) (string, error) {
	path := mount.Path
	if !filepath.IsAbs(path) {
		path = filepath.Join(ownerRoot, path)
	}
	abs, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}
	abs = filepath.Clean(abs)
	if isTaskrRoot(abs) {
		return abs, nil
	}
	child := filepath.Join(abs, "taskr")
	if isTaskrRoot(child) {
		return child, nil
	}
	info, statErr := os.Stat(abs)
	if statErr != nil {
		return "", exitError{code: 2, msg: fmt.Sprintf("mount %s is not readable: %v", mount.ID, statErr)}
	}
	if !info.IsDir() {
		return "", exitError{code: 2, msg: fmt.Sprintf("mount %s path is not a directory: %s", mount.ID, abs)}
	}
	return "", exitError{code: 2, msg: fmt.Sprintf("mount %s path is not a Taskr root: %s", mount.ID, abs)}
}

func probeMountWritable(root string) error {
	f, err := os.CreateTemp(root, ".taskr-mount-write-probe-*")
	if err != nil {
		return err
	}
	name := f.Name()
	if closeErr := f.Close(); closeErr != nil {
		_ = os.Remove(name)
		return closeErr
	}
	return os.Remove(name)
}

func writeProjectConfig(root string, config projectConfig) error {
	var document strings.Builder
	if config.Site != nil {
		document.WriteString("[site]\n")
		fmt.Fprintf(&document, "directory = %s\n\n", strconv.Quote(config.Site.Directory))
	}
	if config.Defaults != nil {
		document.WriteString("[defaults]\n")
		for _, field := range []struct{ name, value string }{
			{"create_status", config.Defaults.CreateStatus},
			{"milestone_status", config.Defaults.MilestoneStatus},
			{"task_status", config.Defaults.TaskStatus},
			{"subtask_status", config.Defaults.SubtaskStatus},
		} {
			if field.value != "" {
				fmt.Fprintf(&document, "%s = %s\n", field.name, strconv.Quote(field.value))
			}
		}
		document.WriteByte('\n')
	}
	for _, mount := range config.Mounts {
		document.WriteString("[[mounts]]\n")
		fmt.Fprintf(&document, "id = %s\nname = %s\npath = %s\nmode = %s\n\n",
			strconv.Quote(mount.ID), strconv.Quote(mount.Name), strconv.Quote(mount.Path), strconv.Quote(mount.Mode))
	}
	data := []byte(document.String())
	path := filepath.Join(root, projectConfigName)
	tmp, err := os.CreateTemp(root, ".taskr-config-*")
	if err != nil {
		return err
	}
	tmpName := tmp.Name()
	defer os.Remove(tmpName)
	if _, err := tmp.Write(data); err != nil {
		_ = tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmpName, path)
}

func resolveMountConfig(config projectConfig, selector string) (int, mountProjectConfig, error) {
	selector = strings.TrimSpace(selector)
	for i, mount := range config.Mounts {
		if mount.ID == selector {
			return i, mount, nil
		}
	}
	var matches []int
	for i, mount := range config.Mounts {
		if strings.EqualFold(mount.Name, selector) {
			matches = append(matches, i)
			continue
		}
		haystack := strings.ToLower(strings.Join([]string{mount.ID, mount.Name, mount.Path, mount.Mode}, " "))
		if strings.Contains(haystack, strings.ToLower(selector)) {
			matches = append(matches, i)
		}
	}
	if len(matches) == 0 {
		return -1, mountProjectConfig{}, exitError{code: 2, msg: fmt.Sprintf("no match for mount selector %q", selector)}
	}
	if len(matches) > 1 {
		ids := make([]string, 0, len(matches))
		for _, i := range matches {
			ids = append(ids, config.Mounts[i].ID)
		}
		return -1, mountProjectConfig{}, exitError{code: 2, msg: fmt.Sprintf("ambiguous mount selector %q; candidates: %s", selector, strings.Join(ids, ", "))}
	}
	i := matches[0]
	return i, config.Mounts[i], nil
}

func ensureMountPathReadable(path string) error {
	entries, err := os.ReadDir(path)
	if err != nil {
		return err
	}
	_ = entries
	return nil
}

func relativeMountPath(ownerRoot, target string) string {
	rel, err := filepath.Rel(ownerRoot, target)
	if err == nil && rel != "." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return filepath.ToSlash(rel)
	}
	return filepath.Clean(target)
}

func removeProjectConfigIfEmpty(root string, config projectConfig) error {
	if config.Site == nil && config.Defaults == nil && len(config.Mounts) == 0 {
		err := os.Remove(filepath.Join(root, projectConfigName))
		if errors.Is(err, fs.ErrNotExist) {
			return nil
		}
		return err
	}
	return writeProjectConfig(root, config)
}

func validateMountGraph(root string) (int, error) {
	abs, err := filepath.Abs(root)
	if err != nil {
		return 0, err
	}
	seen := map[string]string{}
	return validateMountGraphFrom(abs, mountReadWrite, map[string]bool{abs: true}, seen)
}

func validateMountGraphFrom(ownerRoot, parentMode string, ancestors map[string]bool, seen map[string]string) (int, error) {
	config, err := loadProjectConfig(ownerRoot)
	if err != nil {
		return 0, err
	}
	count := 0
	for _, mount := range config.Mounts {
		if previous, ok := seen[mount.ID]; ok {
			return count, exitError{code: 2, msg: fmt.Sprintf("duplicate transitive mount id %q in %s and %s", mount.ID, previous, ownerRoot)}
		}
		seen[mount.ID] = ownerRoot
		path, err := mountedRootPath(ownerRoot, mount)
		if err != nil {
			return count, err
		}
		if err := ensureMountPathReadable(path); err != nil {
			return count, exitError{code: 2, msg: fmt.Sprintf("mount %s is not readable: %v", mount.ID, err)}
		}
		if ancestors[path] {
			return count, exitError{code: 2, msg: fmt.Sprintf("mount cycle detected at %s (%s)", mount.ID, path)}
		}
		mode := mount.Mode
		if parentMode == mountReadOnly {
			mode = mountReadOnly
		}
		if mode == mountReadWrite {
			if err := probeMountWritable(path); err != nil {
				return count, exitError{code: 2, msg: fmt.Sprintf("mount %s is not writable: %v", mount.ID, err)}
			}
		}
		nextAncestors := make(map[string]bool, len(ancestors)+1)
		for ancestor := range ancestors {
			nextAncestors[ancestor] = true
		}
		nextAncestors[path] = true
		children, err := validateMountGraphFrom(path, mode, nextAncestors, seen)
		if err != nil {
			return count, err
		}
		count += 1 + children
	}
	return count, nil
}

func removeBrokenLocalMounts(root string) (int, error) {
	config, err := loadProjectConfig(root)
	if err != nil {
		return 0, err
	}
	kept := make([]mountProjectConfig, 0, len(config.Mounts))
	removed := 0
	for _, mount := range config.Mounts {
		path, resolveErr := mountedRootPath(root, mount)
		if resolveErr != nil {
			removed++
			continue
		}
		if readErr := ensureMountPathReadable(path); readErr != nil {
			removed++
			continue
		}
		kept = append(kept, mount)
	}
	if removed == 0 {
		return 0, nil
	}
	config.Mounts = kept
	return removed, removeProjectConfigIfEmpty(root, config)
}
