// Taskr CLI entrypoint. This file only wires the initial Cobra command surface;
// it does not implement Taskr storage, selectors, reports, or archive behavior.
package main

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"
)

var version = "dev"

type exitError struct {
	code int
	msg  string
}

func (e exitError) Error() string {
	return e.msg
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
	case "archive", "completion", "create", "doctor", "help", "list", "open", "report", "show", "status", "version":
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
		stubCommand(rootPath, "doctor", "Validate a Taskr root", 0, 0),
		createCommand(rootPath),
		stubCommand(rootPath, "show", "Show one item", 1, 1),
		listCommand(rootPath),
		stubCommand(rootPath, "status", "Change item status", 2, 2),
		openCommand(rootPath),
		reportCommand(rootPath),
		archiveCommand(rootPath),
		versionCommand(),
	)

	return cmd
}

func createCommand(rootPath string) *cobra.Command {
	cmd := stubCommand(rootPath, "create", "Create a new item", 2, -1)
	cmd.Use = "create <type> <title>"
	cmd.Flags().String("under", "", "parent item selector")
	cmd.Flags().String("slug", "", "directory slug override")
	cmd.Flags().Bool("edit", false, "open marker in editor after creation")
	cmd.Flags().Bool("no-edit", false, "do not open marker in editor after creation")
	return cmd
}

func listCommand(rootPath string) *cobra.Command {
	cmd := stubCommand(rootPath, "list", "List items", 0, -1)
	cmd.Flags().String("under", "", "parent item selector")
	cmd.Flags().String("type", "", "item type filter")
	cmd.Flags().String("status", "", "item status filter")
	return cmd
}

func openCommand(rootPath string) *cobra.Command {
	cmd := stubCommand(rootPath, "open", "Open an item marker", 1, -1)
	cmd.Flags().Bool("system", false, "open with the system opener")
	return cmd
}

func reportCommand(rootPath string) *cobra.Command {
	cmd := stubCommand(rootPath, "report", "Render an item report", 0, -1)
	cmd.Flags().String("under", "", "parent item selector")
	cmd.Flags().String("type", "", "item type filter")
	cmd.Flags().String("status", "", "item status filter")
	cmd.Flags().String("output", "", "write report to file")
	return cmd
}

func archiveCommand(rootPath string) *cobra.Command {
	cmd := stubCommand(rootPath, "archive", "Archive a closed subtree", 1, -1)
	cmd.Flags().String("to", "", "archive destination below root archive directory")
	return cmd
}

func versionCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print Taskr version",
		Args:  cobra.NoArgs,
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Fprintf(cmd.OutOrStdout(), "taskr version %s\n", version)
		},
	}
}

func stubCommand(rootPath, name, short string, minArgs, maxArgs int) *cobra.Command {
	return &cobra.Command{
		Use:   name,
		Short: short,
		Args:  argRange(minArgs, maxArgs),
		RunE: func(cmd *cobra.Command, args []string) error {
			return notImplemented(name, rootPath)
		},
	}
}

func argRange(minArgs, maxArgs int) cobra.PositionalArgs {
	return func(cmd *cobra.Command, args []string) error {
		if len(args) < minArgs {
			return fmt.Errorf("%s requires at least %d argument(s)", cmd.CommandPath(), minArgs)
		}
		if maxArgs >= 0 && len(args) > maxArgs {
			return fmt.Errorf("%s accepts at most %d argument(s)", cmd.CommandPath(), maxArgs)
		}
		return nil
	}
}

func notImplemented(commandName, rootPath string) error {
	if rootPath == "" {
		return exitError{code: 2, msg: fmt.Sprintf("taskr: %s not implemented", commandName)}
	}
	return exitError{code: 2, msg: fmt.Sprintf("taskr: %s not implemented for root %s", commandName, rootPath)}
}
