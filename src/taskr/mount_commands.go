package main

import (
	"fmt"
	"path/filepath"
	"sort"
	"strings"

	"github.com/spf13/cobra"
)

func runCreateMount(cmd *cobra.Command, rootPath, path, id, name, mode string) error {
	root, err := discoverRoot(rootPath)
	if err != nil {
		return err
	}
	root, err = filepath.Abs(root)
	if err != nil {
		return err
	}
	config, err := loadProjectConfig(root)
	if err != nil {
		return err
	}
	name = strings.TrimSpace(name)
	if name == "" {
		return exitError{code: 2, msg: "mount name must not be empty"}
	}
	if !validMountMode(mode) {
		return exitError{code: 2, msg: fmt.Sprintf("invalid mount mode %q; valid values: read-only, read-write", mode)}
	}
	if id == "" {
		id, err = deriveMountID(name, config.Mounts, -1)
		if err != nil {
			return err
		}
	} else if !validMountID(id) {
		return exitError{code: 2, msg: fmt.Sprintf("invalid mount id %q", id)}
	}
	for _, existing := range config.Mounts {
		if existing.ID == id {
			return exitError{code: 2, msg: fmt.Sprintf("duplicate mount id %q", id)}
		}
	}
	target, err := mountedRootPath(root, mountProjectConfig{ID: id, Path: path})
	if err != nil {
		return err
	}
	if err := ensureMountPathReadable(target); err != nil {
		return exitError{code: 2, msg: fmt.Sprintf("mount %s is not readable: %v", id, err)}
	}
	if mode == mountReadWrite {
		if err := probeMountWritable(target); err != nil {
			return exitError{code: 2, msg: fmt.Sprintf("mount %s is not writable: %v", id, err)}
		}
	}
	config.Mounts = append(config.Mounts, mountProjectConfig{ID: id, Name: name, Path: filepath.Clean(target), Mode: mode})
	if err := writeProjectConfig(root, config); err != nil {
		return err
	}
	fmt.Fprintf(cmd.OutOrStdout(), "created item id=%s type=mount mode=%s path=%s\n", id, mode, target)
	return nil
}

func deriveMountID(name string, mounts []mountProjectConfig, self int) (string, error) {
	word := strings.Fields(name)
	if len(word) == 0 {
		return "", exitError{code: 2, msg: "cannot derive mount id from empty name"}
	}
	first := strings.ToLower(word[0])
	for _, r := range first {
		if r < 'a' || r > 'z' {
			return "", exitError{code: 2, msg: "cannot derive mount id: first name word must contain only ASCII letters"}
		}
	}
	for n := 1; n <= len(first); n++ {
		candidate := first[:n]
		available := true
		for i, mount := range mounts {
			if i != self && mount.ID == candidate {
				available = false
				break
			}
		}
		if available {
			return candidate, nil
		}
	}
	return "", exitError{code: 2, msg: "cannot derive mount id: too many attempts"}
}

func reconfigureCommand(rootPath string) *cobra.Command {
	cmd := &cobra.Command{Use: "reconfigure", Short: "Reconfigure Taskr objects"}
	cmd.AddCommand(reconfigureMountCommand(rootPath))
	return cmd
}

func reconfigureMountCommand(rootPath string) *cobra.Command {
	var name, path, mode, id string
	var autoAdjustID bool
	cmd := &cobra.Command{
		Use:   "mount <selector>",
		Short: "Reconfigure a mount",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			if id != "" && autoAdjustID {
				return exitError{code: 2, msg: "--id and --auto-adjust-id are mutually exclusive"}
			}
			changedFlags := cmd.Flags().Changed("name") || cmd.Flags().Changed("path") || cmd.Flags().Changed("mode") || cmd.Flags().Changed("id") || autoAdjustID
			if !changedFlags {
				return exitError{code: 2, msg: "reconfigure mount requires at least one update flag"}
			}
			root, err := discoverRoot(rootPath)
			if err != nil {
				return err
			}
			root, err = filepath.Abs(root)
			if err != nil {
				return err
			}
			config, err := loadProjectConfig(root)
			if err != nil {
				return err
			}
			index, mount, err := resolveMountConfig(config, args[0])
			if err != nil {
				return err
			}
			updated := mount
			if cmd.Flags().Changed("name") {
				updated.Name = strings.TrimSpace(name)
				if updated.Name == "" {
					return exitError{code: 2, msg: "mount name must not be empty"}
				}
			}
			if cmd.Flags().Changed("mode") {
				if !validMountMode(mode) {
					return exitError{code: 2, msg: fmt.Sprintf("invalid mount mode %q", mode)}
				}
				updated.Mode = mode
			}
			if cmd.Flags().Changed("path") {
				updated.Path, err = mountedRootPath(root, mountProjectConfig{ID: updated.ID, Path: path})
				if err != nil {
					return err
				}
			}
			if cmd.Flags().Changed("id") {
				if !validMountID(id) {
					return exitError{code: 2, msg: fmt.Sprintf("invalid mount id %q", id)}
				}
				updated.ID = id
			}
			if autoAdjustID {
				updated.ID, err = deriveMountID(updated.Name, config.Mounts, index)
				if err != nil {
					return err
				}
			}
			for i, candidate := range config.Mounts {
				if i != index && candidate.ID == updated.ID {
					return exitError{code: 2, msg: fmt.Sprintf("duplicate mount id %q", updated.ID)}
				}
			}
			target, err := mountedRootPath(root, updated)
			if err != nil {
				return err
			}
			updated.Path = filepath.Clean(target)
			if err := ensureMountPathReadable(target); err != nil {
				return exitError{code: 2, msg: fmt.Sprintf("mount %s is not readable: %v", updated.ID, err)}
			}
			if updated.Mode == mountReadWrite {
				if err := probeMountWritable(target); err != nil {
					return exitError{code: 2, msg: fmt.Sprintf("mount %s is not writable: %v", updated.ID, err)}
				}
			}
			if updated == mount {
				fmt.Fprintf(cmd.OutOrStdout(), "reconfigured mount id=%s changed=false\n", mount.ID)
				return nil
			}
			config.Mounts[index] = updated
			if err := writeProjectConfig(root, config); err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "reconfigured mount id=%s changed=true\n", updated.ID)
			return nil
		},
		ValidArgsFunction: mountConfigCompletion(rootPath),
	}
	cmd.Flags().StringVar(&name, "name", "", "new mount name")
	cmd.Flags().StringVar(&path, "path", "", "new mount path")
	cmd.Flags().StringVar(&mode, "mode", "", "new mount mode (read-only or read-write)")
	cmd.Flags().StringVar(&id, "id", "", "new mount ID")
	cmd.Flags().BoolVar(&autoAdjustID, "auto-adjust-id", false, "derive a free ID from the mount name")
	mustRegisterCompletion(cmd, "mode", staticCompletion([]string{mountReadOnly, mountReadWrite}))
	return cmd
}

func removeCommand(rootPath string) *cobra.Command {
	cmd := &cobra.Command{Use: "remove", Short: "Remove Taskr objects"}
	cmd.AddCommand(removeMountCommand(rootPath))
	return cmd
}

func removeMountCommand(rootPath string) *cobra.Command {
	return &cobra.Command{
		Use: "mount <selector>", Short: "Remove a mount from project configuration", Args: cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			root, err := discoverRoot(rootPath)
			if err != nil {
				return err
			}
			root, err = filepath.Abs(root)
			if err != nil {
				return err
			}
			config, err := loadProjectConfig(root)
			if err != nil {
				return err
			}
			index, mount, err := resolveMountConfig(config, args[0])
			if err != nil {
				return err
			}
			config.Mounts = append(config.Mounts[:index], config.Mounts[index+1:]...)
			if err := removeProjectConfigIfEmpty(root, config); err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "removed mount id=%s path=%s\n", mount.ID, mount.Path)
			return nil
		},
		ValidArgsFunction: mountConfigCompletion(rootPath),
	}
}

func mountConfigCompletion(rootPath string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		t, err := loadTree(rootPath)
		if err != nil {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		values := make([]string, 0, len(t.Config.Mounts))
		for _, it := range t.Items {
			if it.IsMount {
				values = append(values, fmt.Sprintf("%s\tmount %s %s", it.IDText, it.Status, it.Title))
			}
		}
		sort.Strings(values)
		return filterCompletions(values, toComplete), cobra.ShellCompDirectiveNoFileComp
	}
}

func writableMountCompletion(rootPath string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		t, err := loadTree(rootPath)
		if err != nil {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		values := []string{".\tlocal root"}
		for _, it := range t.Items {
			if it.IsMount && it.MountMode == mountReadWrite {
				values = append(values, fmt.Sprintf("%s\tmount %s %s", it.IDText, it.MountMode, it.Title))
			}
		}
		sort.Strings(values)
		return filterCompletions(values, toComplete), cobra.ShellCompDirectiveNoFileComp
	}
}
