package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
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

var itemTypes = []string{"milestone", "task", "subtask"}
var priorities = []string{"high", "normal", "low"}

var validStatuses = map[string]bool{
	"open":       true,
	"designing":  true,
	"developing": true,
	"active":     true,
	"reviewing":  true,
	"blocked":    true,
	"done":       true,
	"cancelled":  true,
}

var statuses = []string{"open", "designing", "developing", "active", "reviewing", "blocked", "done", "cancelled"}
var initialStatuses = []string{"open", "designing", "developing", "active", "reviewing", "blocked"}

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
	Priority   string
	CreatedAt  string
	UpdatedAt  string
	StatusAt   map[string]string
	ReopenedAt string
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
	Config     projectConfig
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
	case "__complete", "__completeNoDesc", "archive", "comment", "completion", "create", "doctor", "examples", "help", "init", "list", "move", "open", "priority", "rename", "report", "show", "site", "status", "tree", "version":
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
		siteCommand(rootPath, &configFile),
		doctorCommand(rootPath),
		createCommand(rootPath),
		commentCommand(rootPath),
		showCommand(rootPath),
		priorityCommand(rootPath),
		listCommand(rootPath),
		treeCommand(rootPath),
		statusCommand(rootPath),
		moveCommand(rootPath),
		renameCommand(rootPath),
		openCommand(rootPath),
		reportCommand(rootPath),
		archiveCommand(rootPath),
		examplesCommand(),
		versionCommand(),
	)

	return cmd
}

func examplesCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "examples",
		Short: "Show common Taskr workflows",
		Args:  cobra.NoArgs,
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Fprint(cmd.OutOrStdout(), `Taskr workflow examples

Initialize a project worktree:
  taskr init

Initialize the project site output:
  taskr site init ../site --create-if-missing

Generate the project site:
  taskr site generate

Open the generated project site:
  taskr site open
  taskr site open Define workflows --watch --regenerate

Create a milestone:
  taskr create milestone "MVP" --no-edit

Create a ticket below a milestone:
  taskr create task "Define workflows" --under 001 --no-edit

Create work with an explicit initial status:
  taskr create task "Implement parser" --under 001 --status designing

Create a subtask below a ticket:
  taskr create subtask "Define selectors" --under 002 --no-edit
  taskr create subtask "Verify malformed input" --under 002 --status developing --no-edit

Edit an item:
  taskr open 002

Append comments:
  taskr comment 002 "Reviewed with Michael"
  printf 'first detail\nsecond detail\n' | taskr comment 002 --stdin

Inspect work:
  taskr list
  taskr list --all
  taskr list --glob workflow
  taskr list --all --type task --under 001 --glob 'release*' --glob artifact
  taskr tree
  taskr tree 001 --all
  taskr tree 001 --ascii
  taskr tree 001 --all --show-priority
  taskr tree 001 --hide-priority
  taskr show 002
  taskr show 002 --meta
  taskr report

Prioritize a ticket:
  taskr priority 002 high
  taskr priority 002 normal

Rename an item:
  taskr rename 003 "Plan delivery workflows"
  taskr rename 003 "Plan delivery workflows" --slug delivery-plan
  taskr rename 003 "Plan delivery workflows" --keep-slug

List tickets by status:
  taskr list --type task --status open
  taskr list --type task --status developing --under 001
  taskr list --type task --status active --under 001
  taskr list --type task --status reviewing --under 001
  taskr list --all --type task --status done --under 001
  taskr list --all --type task --status cancelled --under 001
  taskr list --type task --priority high
  taskr list --type task --show-priority
  taskr list --type task --group-by priority

Review and close work:
  taskr status 003 developing
  taskr status 003 reviewing
  taskr status 003 done
  taskr status 002 done
  taskr status 001 done

Archive closed work:
  taskr archive 002 --to 2026
`)
		},
	}
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

func siteCommand(rootPath string, configFile *string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "site",
		Short: "Manage the project site",
		Args:  cobra.NoArgs,
	}
	cmd.AddCommand(siteInitCommand(rootPath), siteGenerateCommand(rootPath), siteOpenCommand(rootPath, configFile))
	return cmd
}

func siteOpenCommand(rootPath string, configFile *string) *cobra.Command {
	var regenerate, watch, noBrowser bool
	var port int
	cmd := &cobra.Command{
		Use:   "open [search terms...]",
		Short: "Serve and open the generated project site",
		Long: `Serve and open the generated project site on a loopback HTTP server.

The existing generated site is served without modification. Use --regenerate
to generate once before serving and --watch to regenerate after relevant Taskr
source changes. Browser selection uses personal configuration, then BROWSER,
then the platform system opener.`,
		Args: cobra.ArbitraryArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			return runSiteOpen(cmd, rootPath, *configFile, args, siteOpenOptions{
				regenerate: regenerate,
				watch:      watch,
				noBrowser:  noBrowser,
				port:       port,
			})
		},
		ValidArgsFunction: func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
			return nil, cobra.ShellCompDirectiveNoFileComp
		},
	}
	cmd.Flags().BoolVar(&regenerate, "regenerate", false, "generate the site once before serving")
	cmd.Flags().BoolVar(&watch, "watch", false, "regenerate and reload after Taskr source changes")
	cmd.Flags().BoolVar(&noBrowser, "no-browser", false, "serve without starting a browser")
	cmd.Flags().IntVar(&port, "port", 0, "exact loopback port (default attempts 80, then a dynamic port)")
	return cmd
}

func siteGenerateCommand(rootPath string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "generate",
		Short: "Generate the project site",
		Long: `Generate the project site in the initialized output directory.

The complete static site is rendered before the existing Taskr-owned output is
atomically replaced. Run taskr site init first to associate an output directory
with the selected Taskr root.`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			index, generatedAt, err := generateSite(t, time.Now().UTC())
			if err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "generated site index=%s generated_at=%s\n", index, generatedAt)
			return nil
		},
		ValidArgsFunction: func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
			return nil, cobra.ShellCompDirectiveNoFileComp
		},
	}
	return cmd
}

func siteInitCommand(rootPath string) *cobra.Command {
	var createIfMissing bool
	cmd := &cobra.Command{
		Use:   "init <site-directory>",
		Short: "Initialize the project site output directory",
		Long: `Initialize the project site output directory.

The directory is stored in the selected Taskr root's taskr.toml. Relative
paths resolve from the Taskr root. Existing nonempty directories must contain
a valid .taskr-site ownership marker. The site directory must not overlap the
Taskr root.`,
		Args: cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			directory, created, changed, err := initializeSite(t.Root, args[0], createIfMissing)
			if err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "initialized site root=%s directory=%s created=%t changed=%t\n", t.Root, directory, created, changed)
			return nil
		},
	}
	cmd.Flags().BoolVar(&createIfMissing, "create-if-missing", false, "create the site directory and required parents when missing")
	return cmd
}

func doctorCommand(rootPath string) *cobra.Command {
	var fix bool

	cmd := &cobra.Command{
		Use:   "doctor",
		Short: "Validate a Taskr root",
		Long: `Validate a Taskr root.

Current validation checks that the root can be loaded as a Taskr worktree:
marker structure, item directory IDs, marker frontmatter used by Taskr, status
values, optional status-transition timestamps, task priority metadata, and
root-wide duplicate IDs. Optional root-local taskr.toml project configuration
is parsed strictly; configured site paths and ownership markers are validated
with the worktree.

Fix mode currently repairs only duplicate IDs. The worktree must be loadable
apart from duplicate IDs; unsupported errors are reported and leave the
worktree unchanged.`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			if fix {
				return runDoctorFix(cmd, rootPath)
			}
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "ok root=%s items=%d files=%d\n", t.Root, len(t.Items), len(t.FileDirs))
			return nil
		},
	}
	cmd.Flags().BoolVar(&fix, "fix", false, "repair duplicate IDs when the rest of the worktree is loadable")
	return cmd
}

func createCommand(rootPath string) *cobra.Command {
	var under, slug, status string
	var edit, noEdit bool

	cmd := &cobra.Command{
		Use:   "create {milestone|task|subtask} <title>",
		Short: "Create a new item",
		Long: `Create a new item.

The item type determines the marker filename: milestone.md, task.md, or
subtask.md. An explicit --status overrides type-specific project defaults in
taskr.toml, then the common project default. Without either, the initial status
defaults to open. Valid initial statuses are open, designing, developing,
active, reviewing, and blocked.`,
		Args: cobra.MinimumNArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runCreate(cmd, rootPath, args[0], strings.Join(args[1:], " "), under, slug, status, edit, noEdit)
		},
		ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
			if len(args) == 0 {
				return filterCompletions(itemTypes, toComplete), cobra.ShellCompDirectiveNoFileComp
			}
			return nil, cobra.ShellCompDirectiveNoFileComp
		},
	}
	cmd.Flags().StringVar(&under, "under", "", "parent item selector")
	cmd.Flags().StringVar(&slug, "slug", "", "directory slug override")
	cmd.Flags().StringVar(&status, "status", "", "initial status (default open)")
	cmd.Flags().BoolVar(&edit, "edit", false, "open marker in editor after creation")
	cmd.Flags().BoolVar(&noEdit, "no-edit", false, "do not open marker in editor after creation")
	mustRegisterCompletion(cmd, "under", writeParentCompletion(rootPath))
	mustRegisterCompletion(cmd, "status", staticCompletion(initialStatuses))
	return cmd
}

func commentCommand(rootPath string) *cobra.Command {
	var fromStdin bool

	cmd := &cobra.Command{
		Use:   "comment <selector> <text>",
		Short: "Append a comment to an item",
		Long: `Append one dated comment entry to an item's # Comments section.

Pass text arguments for a single-line comment, or use --stdin to read a
multi-line comment from a pipe or heredoc.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			if len(args) == 0 {
				return exitError{code: 2, msg: "comment requires selector and text or --stdin"}
			}
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			it, err := resolveItem(t, args[0])
			if err != nil {
				return err
			}
			lines, err := commentLines(args[1:], fromStdin)
			if err != nil {
				return err
			}
			if err := appendComment(it.MarkerPath, lines); err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "commented id=%s path=%s/%s\n", it.IDText, it.RelDir, it.Marker)
			return nil
		},
		ValidArgsFunction: selectorArgCompletion(rootPath),
	}
	cmd.Flags().BoolVar(&fromStdin, "stdin", false, "read comment text from stdin")
	return cmd
}

func showCommand(rootPath string) *cobra.Command {
	var metaOnly bool

	cmd := &cobra.Command{
		Use:   "show <selector>",
		Short: "Show one complete item",
		Long: `Show exactly one Taskr item on the console.

By default, show prints readable item identity and the complete Markdown body.
Stored high and low task priorities are always visible. Use --meta to print all
marker metadata, including effective normal priority, without the body.
Ambiguous selectors fail and list every matching item's ID and title.`,
		Args: cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			it, err := resolveItem(t, args[0])
			if err != nil {
				return err
			}
			return writeShownItem(cmd.OutOrStdout(), it, metaOnly)
		},
		ValidArgsFunction: selectorArgCompletion(rootPath),
	}
	cmd.Flags().BoolVar(&metaOnly, "meta", false, "show marker metadata without the Markdown body")
	return cmd
}

func writeShownItem(w io.Writer, it *item, metaOnly bool) error {
	fmt.Fprintf(w, "ID: %s\nType: %s\nTitle: %s\nStatus: %s\n", it.IDText, it.Type, it.Title, it.Status)
	if it.Type == "task" && (metaOnly || it.Priority != "normal") {
		fmt.Fprintf(w, "Priority: %s\n", it.Priority)
	}
	fmt.Fprintf(w, "Marker: %s\n", filepath.ToSlash(filepath.Join(it.RelDir, it.Marker)))
	if metaOnly {
		fmt.Fprintf(w, "Created at: %s\nUpdated at: %s\n", it.CreatedAt, it.UpdatedAt)
		for _, status := range statuses {
			if timestamp := it.StatusAt[status]; timestamp != "" {
				fmt.Fprintf(w, "%s at: %s\n", statusLabel(status), timestamp)
			}
		}
		if it.ReopenedAt != "" {
			fmt.Fprintf(w, "Reopened at: %s\n", it.ReopenedAt)
		}
		return nil
	}

	body, err := markerBody(it.MarkerPath)
	if err != nil {
		return err
	}
	fmt.Fprintln(w)
	_, err = fmt.Fprint(w, body)
	return err
}

func markerBody(path string) (string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	content := string(data)
	if !strings.HasPrefix(content, "---\n") {
		return "", exitError{code: 2, msg: fmt.Sprintf("%s: invalid frontmatter", path)}
	}
	frontmatterEnd := strings.Index(content[len("---\n"):], "\n---\n")
	if frontmatterEnd < 0 {
		return "", exitError{code: 2, msg: fmt.Sprintf("%s: unterminated frontmatter", path)}
	}
	bodyStart := len("---\n") + frontmatterEnd + len("\n---\n")
	return strings.TrimLeft(content[bodyStart:], "\n"), nil
}

func listCommand(rootPath string) *cobra.Command {
	var under, typeFilter, statusFilter, priorityFilter, groupBy string
	var globs []string
	var includeAll, showPriority, hidePriority bool

	cmd := &cobra.Command{
		Use:   "list",
		Short: "List items",
		Long: `List items.

By default, list excludes done and cancelled items. Use --all to include them.
Explicit done or cancelled status filters therefore require --all. Repeated
--glob values filter complete marker text case-insensitively and must each match
at least one marker line.`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			if showPriority && hidePriority {
				return exitError{code: 2, msg: "list flags --show-priority and --hide-priority are mutually exclusive"}
			}
			if groupBy != "" && groupBy != "priority" {
				return exitError{code: 2, msg: fmt.Sprintf("invalid list group %q", groupBy)}
			}
			if groupBy == "priority" && typeFilter != "task" {
				return exitError{code: 2, msg: "list --group-by priority requires --type task"}
			}
			compiledGlobs, err := compileLineGlobs(globs)
			if err != nil {
				return err
			}
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			items, err := filteredItems(t, under, typeFilter, statusFilter, priorityFilter, includeAll)
			if err != nil {
				return err
			}
			items, err = filterItemsByMarkerGlobs(items, compiledGlobs)
			if err != nil {
				return err
			}
			if typeFilter == "task" || priorityFilter != "" {
				sortItemsByPriority(items)
			}
			mode := priorityDisplayAuto
			if showPriority {
				mode = priorityDisplayShow
			} else if hidePriority {
				mode = priorityDisplayHide
			}
			if groupBy == "priority" {
				writePriorityGroups(cmd.OutOrStdout(), items, mode)
			} else {
				writeItemLinesWithPriority(cmd.OutOrStdout(), items, true, mode)
			}
			return nil
		},
	}
	cmd.Flags().BoolVar(&includeAll, "all", false, "include done and cancelled items")
	cmd.Flags().StringVar(&under, "under", "", "parent item selector")
	cmd.Flags().StringVar(&typeFilter, "type", "", "item type filter")
	cmd.Flags().StringVar(&statusFilter, "status", "", "item status filter")
	cmd.Flags().StringVar(&priorityFilter, "priority", "", "effective task priority filter")
	cmd.Flags().BoolVar(&showPriority, "show-priority", false, "show effective priority for every task")
	cmd.Flags().BoolVar(&hidePriority, "hide-priority", false, "hide all task priority values")
	cmd.Flags().StringVar(&groupBy, "group-by", "", "group task output by priority")
	cmd.Flags().StringArrayVar(&globs, "glob", nil, "filter by case-insensitive glob over full marker text (repeatable)")
	mustRegisterCompletion(cmd, "under", displayParentCompletion(rootPath))
	mustRegisterCompletion(cmd, "type", staticCompletion(itemTypes))
	mustRegisterCompletion(cmd, "status", staticCompletion(statuses))
	mustRegisterCompletion(cmd, "priority", staticCompletion(priorities))
	mustRegisterCompletion(cmd, "group-by", staticCompletion([]string{"priority"}))
	return cmd
}

func treeCommand(rootPath string) *cobra.Command {
	var includeAll, ascii, tabs, wide, showPriority, hidePriority bool

	cmd := &cobra.Command{
		Use:   "tree [selector]",
		Short: "Show the item hierarchy",
		Long: `Show Taskr items as an indented tree.

By default, done and cancelled items are hidden. Use --all to include them.

The default format uses two spaces per hierarchy level. Use --ascii for branch
markers, --tabs for tab indentation, or --wide for wider space indentation.
Non-normal task priority is shown by default; --show-priority includes normal
and --hide-priority suppresses all priority labels.`,
		Args: cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			opts, err := newTreeOptions(includeAll, ascii, tabs, wide, showPriority, hidePriority)
			if err != nil {
				return err
			}
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			var roots []*item
			if len(args) == 1 {
				it, err := resolveItem(t, args[0])
				if err != nil {
					return err
				}
				roots = []*item{it}
			} else {
				for _, it := range t.Items {
					if it.Parent == nil {
						roots = append(roots, it)
					}
				}
				sortItems(roots)
			}
			writeTree(cmd.OutOrStdout(), roots, opts)
			return nil
		},
		ValidArgsFunction: treeArgCompletion(rootPath),
	}
	cmd.Flags().BoolVar(&includeAll, "all", false, "include done and cancelled items")
	cmd.Flags().BoolVar(&ascii, "ascii", false, "use ASCII branch markers")
	cmd.Flags().BoolVar(&tabs, "tabs", false, "indent hierarchy levels with tabs")
	cmd.Flags().BoolVar(&wide, "wide", false, "indent hierarchy levels with four spaces")
	cmd.Flags().BoolVar(&showPriority, "show-priority", false, "show effective priority for every task")
	cmd.Flags().BoolVar(&hidePriority, "hide-priority", false, "hide all task priority values")
	return cmd
}

func statusCommand(rootPath string) *cobra.Command {
	return &cobra.Command{
		Use:   "status <selector> <status>",
		Short: "Change item status",
		Long: `Change one item's status.

A real transition updates updated_at and the target status's *_at timestamp.
Reopening a done or cancelled item also updates reopened_at. Repeating the
current status succeeds without changing the marker.`,
		Args: cobra.ExactArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			newStatus := args[1]
			if !validStatuses[newStatus] {
				return exitError{code: 2, msg: fmt.Sprintf("invalid status %q", newStatus)}
			}
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			it, err := resolveItem(t, args[0])
			if err != nil {
				return err
			}
			if newStatus == it.Status {
				fmt.Fprintf(cmd.OutOrStdout(), "status id=%s old=%s new=%s changed=false\n", it.IDText, it.Status, newStatus)
				return nil
			}
			if newStatus == "done" {
				if blockers := unfinishedChildren(it); len(blockers) > 0 {
					return exitError{code: 2, msg: fmt.Sprintf("unfinished children block done for %s: %s", it.IDText, strings.Join(blockers, ", "))}
				}
			}
			now := time.Now().UTC().Format(time.RFC3339)
			fields := map[string]string{
				"status":          newStatus,
				"updated_at":      now,
				newStatus + "_at": now,
			}
			if isClosedStatus(it.Status) && !isClosedStatus(newStatus) {
				fields["reopened_at"] = now
			}
			if err := updateMarkerFields(it.MarkerPath, fields); err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "status id=%s old=%s new=%s changed=true\n", it.IDText, it.Status, newStatus)
			return nil
		},
		ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
			switch len(args) {
			case 0:
				return selectorCompletion(rootPath)(cmd, args, toComplete)
			case 1:
				return filterCompletions(statuses, toComplete), cobra.ShellCompDirectiveNoFileComp
			default:
				return nil, cobra.ShellCompDirectiveNoFileComp
			}
		},
	}
}

func priorityCommand(rootPath string) *cobra.Command {
	return &cobra.Command{
		Use:   "priority <selector> <high|normal|low>",
		Short: "Change task priority",
		Long: `Change one task's effective priority.

High and low are stored in marker frontmatter. Normal removes stored priority
metadata because omitted priority is effectively normal. A real change updates
updated_at; repeating the effective priority leaves the marker unchanged.`,
		Args: cobra.ExactArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			newPriority := args[1]
			if !isPriority(newPriority) {
				return exitError{code: 2, msg: fmt.Sprintf("invalid priority %q", newPriority)}
			}
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			it, err := resolveItem(t, args[0])
			if err != nil {
				return err
			}
			if it.Type != "task" {
				return exitError{code: 2, msg: fmt.Sprintf("priority can only be changed for tasks, not %s %s", it.Type, it.IDText)}
			}
			stored := newPriority != "normal"
			if newPriority == it.Priority {
				fmt.Fprintf(cmd.OutOrStdout(), "priority id=%s old=%s new=%s changed=false stored=%t\n", it.IDText, it.Priority, newPriority, stored)
				return nil
			}
			updates := map[string]string{"updated_at": time.Now().UTC().Format(time.RFC3339)}
			remove := map[string]bool{}
			if stored {
				updates["priority"] = newPriority
			} else {
				remove["priority"] = true
			}
			if err := rewriteMarkerFields(it.MarkerPath, updates, remove); err != nil {
				return err
			}
			fmt.Fprintf(cmd.OutOrStdout(), "priority id=%s old=%s new=%s changed=true stored=%t\n", it.IDText, it.Priority, newPriority, stored)
			return nil
		},
		ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
			switch len(args) {
			case 0:
				return filteredSelectorCompletion(rootPath, func(it *item) bool { return it.Type == "task" })(cmd, args, toComplete)
			case 1:
				return filterCompletions(priorities, toComplete), cobra.ShellCompDirectiveNoFileComp
			default:
				return nil, cobra.ShellCompDirectiveNoFileComp
			}
		},
	}
}

func isPriority(value string) bool {
	return value == "high" || value == "normal" || value == "low"
}

func moveCommand(rootPath string) *cobra.Command {
	var under string
	var toRoot bool

	cmd := &cobra.Command{
		Use:   "move <selector>",
		Short: "Move an item to another parent",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runMove(cmd, rootPath, args[0], under, toRoot)
		},
		ValidArgsFunction: moveArgCompletion(rootPath),
	}
	cmd.Flags().StringVar(&under, "under", "", "destination parent selector")
	cmd.Flags().BoolVar(&toRoot, "root", false, "move item to the root level")
	mustRegisterCompletion(cmd, "under", moveParentCompletion(rootPath))
	return cmd
}

func renameCommand(rootPath string) *cobra.Command {
	var slug string
	var keepSlug bool

	cmd := &cobra.Command{
		Use:   "rename <selector> <new-title>",
		Short: "Rename an item",
		Long: `Rename a milestone, task, or subtask while preserving its numeric ID and subtree.

By default, the directory slug is derived from the new title. Use --slug to
provide a different slug or --keep-slug to change only the title.`,
		Args: cobra.MinimumNArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			slugSet := cmd.Flags().Changed("slug")
			if slugSet && keepSlug {
				return exitError{code: 2, msg: "rename flags --slug and --keep-slug are mutually exclusive"}
			}
			return runRename(cmd, rootPath, args[0], strings.Join(args[1:], " "), slug, slugSet, keepSlug)
		},
		ValidArgsFunction: selectorArgCompletion(rootPath),
	}
	cmd.Flags().StringVar(&slug, "slug", "", "directory slug override")
	cmd.Flags().BoolVar(&keepSlug, "keep-slug", false, "change the title without changing the directory slug")
	return cmd
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
		ValidArgsFunction: selectorArgCompletion(rootPath),
	}
	cmd.Flags().BoolVar(&system, "system", false, "open with the system opener")
	return cmd
}

func reportCommand(rootPath string) *cobra.Command {
	var output string

	cmd := &cobra.Command{
		Use:   "report",
		Short: "Render a repository report",
		Long: `Render a top-level repository report.

The default report includes status summaries, effective task-priority counts,
status extremes, milestone sections, and open milestones without tickets.`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			t, err := loadTree(rootPath)
			if err != nil {
				return err
			}
			b := renderReport(t, time.Now())
			if output != "" {
				if err := os.WriteFile(output, []byte(b), 0o644); err != nil {
					return exitError{code: 1, msg: fmt.Sprintf("write report output %s: %v", output, err)}
				}
				fmt.Fprintf(cmd.OutOrStdout(), "wrote report path=%s\n", output)
				return nil
			}
			fmt.Fprint(cmd.OutOrStdout(), b)
			return nil
		},
	}
	cmd.Flags().StringVar(&output, "output", "", "write report to file")
	return cmd
}

const reportCurrentLimit = 5

func renderReport(t *tree, now time.Time) string {
	items := append([]*item(nil), t.Items...)
	sortItems(items)

	var b strings.Builder
	fmt.Fprintln(&b, "Taskr report")
	fmt.Fprintf(&b, "Project: %s\n", filepath.Base(t.Root))
	fmt.Fprintf(&b, "Report date: %s\n", now.Format("2006-01-02"))
	b.WriteByte('\n')

	fmt.Fprintln(&b, "# Status Summary")
	writeStatusSummary(&b, items)
	b.WriteByte('\n')
	fmt.Fprintln(&b, "# Task Priority Summary")
	writeTaskPriorityCounts(&b, items)
	b.WriteByte('\n')

	fmt.Fprintln(&b, "# Status Extremes")
	writeStatusExtremes(&b, items)

	writeMilestoneSections(&b, items)

	if writeOpenMilestonesWithoutTickets(&b, items) {
		b.WriteByte('\n')
	}
	return b.String()
}

func writeTaskPriorityCounts(w interface{ Write([]byte) (int, error) }, items []*item) {
	counts := map[string]int{}
	for _, it := range items {
		if it.Type == "task" {
			counts[it.Priority]++
		}
	}
	for _, priority := range priorities {
		fmt.Fprintf(w, "tasks with effective priority %q: %d\n", priority, counts[priority])
	}
}

func writeStatusSummary(w interface{ Write([]byte) (int, error) }, items []*item) {
	counts := map[string]map[string]int{}
	for _, itemType := range itemTypes {
		counts[itemType] = map[string]int{}
	}
	for _, it := range items {
		if _, ok := counts[it.Type]; !ok {
			counts[it.Type] = map[string]int{}
		}
		counts[it.Type][it.Status]++
	}
	for _, itemType := range itemTypes {
		for _, status := range statuses {
			if count := counts[itemType][status]; count > 0 {
				fmt.Fprintf(w, "%s with status %q: %d\n", pluralItemType(itemType), status, count)
			}
		}
	}
}

func writeStatusExtremes(w interface{ Write([]byte) (int, error) }, items []*item) {
	for _, itemType := range itemTypes {
		var wroteType bool
		for _, status := range statuses {
			var matches []*item
			for _, it := range items {
				if it.Type == itemType && it.Status == status {
					matches = append(matches, it)
				}
			}
			if len(matches) == 0 {
				continue
			}
			if !wroteType {
				fmt.Fprintf(w, "## %s\n", titlePluralItemType(itemType))
				wroteType = true
			}
			sortItemsByAge(matches)
			if closedStatus(status) {
				fmt.Fprintf(w, "Newest %s: %s\n", status, reportItemLine(matches[len(matches)-1], false))
			} else {
				fmt.Fprintf(w, "Oldest %s: %s\n", status, reportItemLine(matches[0], false))
			}
		}
		if wroteType {
			fmt.Fprintln(w)
		}
	}
}

func writeMilestoneSections(w interface{ Write([]byte) (int, error) }, items []*item) bool {
	var milestones []*item
	for _, it := range items {
		if it.Type == "milestone" {
			milestones = append(milestones, it)
		}
	}
	sortItems(milestones)
	var wrote bool
	for _, milestone := range milestones {
		counts := map[string]int{}
		var activeTickets []*item
		for _, child := range milestone.Children {
			if child.Type != "task" {
				continue
			}
			counts[child.Status]++
			if child.Status == "developing" || child.Status == "reviewing" {
				activeTickets = append(activeTickets, child)
			}
		}
		if len(counts) == 0 {
			continue
		}
		if !wrote {
			fmt.Fprintln(w, "# Milestones")
			wrote = true
		}
		fmt.Fprintf(w, "## %s (%s) [%s]\n", milestone.Title, milestone.Slug, milestone.Status)
		fmt.Fprintln(w, "### Ticket Status Counts")
		for _, status := range statuses {
			if count := counts[status]; count > 0 {
				fmt.Fprintf(w, "tasks with status %q: %d\n", status, count)
			}
		}
		fmt.Fprintln(w, "### Task Priority Counts")
		writeTaskPriorityCounts(w, directChildren(milestone, "task"))
		if len(activeTickets) > 0 {
			sortItems(activeTickets)
			visible := activeTickets
			if len(visible) > reportCurrentLimit {
				visible = visible[:reportCurrentLimit]
				fmt.Fprintf(w, "### Current %d developing/reviewing tasks (showing %d of %d)\n", reportCurrentLimit, len(visible), len(activeTickets))
			} else {
				fmt.Fprintln(w, "### Current developing/reviewing tasks")
			}
			for _, it := range visible {
				fmt.Fprintln(w, reportItemLine(it, false))
			}
		}
		fmt.Fprintln(w)
	}
	return wrote
}

func directChildren(it *item, itemType string) []*item {
	var children []*item
	for _, child := range it.Children {
		if child.Type == itemType {
			children = append(children, child)
		}
	}
	return children
}

func writeOpenMilestonesWithoutTickets(w interface{ Write([]byte) (int, error) }, items []*item) bool {
	var milestones []*item
	for _, it := range items {
		if it.Type != "milestone" || closedStatus(it.Status) || directChildCount(it, "task") > 0 {
			continue
		}
		milestones = append(milestones, it)
	}
	if len(milestones) == 0 {
		return false
	}
	sortItems(milestones)
	fmt.Fprintln(w, "# Open Milestones Without Tickets")
	for _, it := range milestones {
		fmt.Fprintln(w, reportItemLine(it, false))
	}
	return true
}

func directChildCount(it *item, itemType string) int {
	var count int
	for _, child := range it.Children {
		if child.Type == itemType {
			count++
		}
	}
	return count
}

func reportItemLine(it *item, withType bool) string {
	if withType {
		return fmt.Sprintf("%s [%s %s] %s", it.IDText, it.Type, it.Status, it.Title)
	}
	return fmt.Sprintf("%s [%s] %s", it.IDText, it.Status, it.Title)
}

func titlePluralItemType(itemType string) string {
	switch itemType {
	case "milestone":
		return "Milestones"
	case "task":
		return "Tasks"
	case "subtask":
		return "Subtasks"
	default:
		return pluralItemType(itemType)
	}
}

func pluralItemType(itemType string) string {
	switch itemType {
	case "milestone":
		return "milestones"
	case "task":
		return "tasks"
	case "subtask":
		return "subtasks"
	default:
		return itemType + "s"
	}
}

func sortItemsByAge(items []*item) {
	sort.Slice(items, func(i, j int) bool {
		left := itemAgeKey(items[i])
		right := itemAgeKey(items[j])
		if left == right {
			return items[i].ID < items[j].ID
		}
		return left < right
	})
}

func itemAgeKey(it *item) string {
	if it.CreatedAt != "" {
		return it.CreatedAt
	}
	if it.UpdatedAt != "" {
		return it.UpdatedAt
	}
	return it.IDText
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
		ValidArgsFunction: selectorArgCompletion(rootPath),
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

func runCreate(cmd *cobra.Command, rootPath, itemType, title, under, slug, status string, edit, noEdit bool) error {
	marker, ok := typeMarkers[itemType]
	if !ok {
		return exitError{code: 2, msg: fmt.Sprintf("invalid item type %q", itemType)}
	}
	if status != "" && !isInitialStatus(status) {
		return exitError{code: 2, msg: fmt.Sprintf("invalid initial status %q; valid values: %s", status, strings.Join(initialStatuses, ", "))}
	}
	t, err := loadTreeAllowEmpty(rootPath)
	if err != nil {
		return err
	}
	status = t.Config.initialCreateStatus(itemType, status)
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
	if err := os.WriteFile(markerPath, []byte(newMarker(title, status)), 0o644); err != nil {
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

func runMove(cmd *cobra.Command, rootPath, selector, under string, toRoot bool) error {
	if (under == "") == !toRoot {
		return exitError{code: 2, msg: "move destination requires exactly one of --under or --root"}
	}
	t, err := loadTree(rootPath)
	if err != nil {
		return err
	}
	source, err := resolveItem(t, selector)
	if err != nil {
		return err
	}
	destParent := t.Root
	if under != "" {
		parent, err := resolveItem(t, under)
		if err != nil {
			return err
		}
		if parent == source {
			return exitError{code: 2, msg: "cannot move item under itself"}
		}
		if isDescendantOf(parent, source) {
			return exitError{code: 2, msg: "cannot move item under its own descendant"}
		}
		if err := validateChildType(parent, source.Type); err != nil {
			return err
		}
		destParent = parent.Dir
	}
	dest := filepath.Join(destParent, filepath.Base(source.Dir))
	if filepath.Clean(dest) == filepath.Clean(source.Dir) {
		return exitError{code: 2, msg: "move destination is the current location"}
	}
	if _, err := os.Stat(dest); err == nil {
		return exitError{code: 2, msg: fmt.Sprintf("move destination exists: %s", relPath(t.Root, dest))}
	} else if !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	oldRel := source.RelDir
	newRel := relPath(t.Root, dest)
	if err := os.Rename(source.Dir, dest); err != nil {
		return err
	}
	if _, err := loadTree(t.Root); err != nil {
		rollbackErr := os.Rename(dest, source.Dir)
		if rollbackErr != nil {
			return exitError{code: 1, msg: fmt.Sprintf("move made invalid worktree and rollback failed: %v; rollback: %v", err, rollbackErr)}
		}
		return exitError{code: 2, msg: fmt.Sprintf("move would make worktree invalid: %v", err)}
	}
	fmt.Fprintf(cmd.OutOrStdout(), "moved id=%s from=%s to=%s\n", source.IDText, oldRel, newRel)
	return nil
}

func runRename(cmd *cobra.Command, rootPath, selector, title, slug string, slugSet, keepSlug bool) error {
	title = strings.TrimSpace(title)
	if title == "" {
		return exitError{code: 2, msg: "rename title is empty"}
	}
	t, err := loadTree(rootPath)
	if err != nil {
		return err
	}
	it, err := resolveItem(t, selector)
	if err != nil {
		return err
	}

	newSlug := it.Slug
	if !keepSlug {
		if slugSet {
			newSlug = slugify(slug)
		} else {
			newSlug = slugify(title)
		}
	}
	if newSlug == "" {
		return exitError{code: 2, msg: "rename slug is empty"}
	}
	if title == it.Title && newSlug == it.Slug {
		fmt.Fprintf(cmd.OutOrStdout(), "renamed id=%s from=%s to=%s title=%q changed=false\n", it.IDText, it.RelDir, it.RelDir, title)
		return nil
	}

	oldDir := it.Dir
	oldRel := it.RelDir
	newDir := filepath.Join(filepath.Dir(oldDir), it.IDText+"-"+newSlug)
	newRel := relPath(t.Root, newDir)
	if newSlug != it.Slug {
		if existing := existingSlugDir(filepath.Dir(oldDir), newSlug); existing != "" {
			return exitError{code: 2, msg: fmt.Sprintf("rename destination slug exists: %s", existing)}
		}
		if _, err := os.Stat(newDir); err == nil {
			return exitError{code: 2, msg: fmt.Sprintf("rename destination exists: %s", newRel)}
		} else if !errors.Is(err, fs.ErrNotExist) {
			return err
		}
	}

	originalMarker, err := os.ReadFile(it.MarkerPath)
	if err != nil {
		return err
	}
	markerInfo, err := os.Stat(it.MarkerPath)
	if err != nil {
		return err
	}
	restoreMarker := func(path string) error {
		return os.WriteFile(path, originalMarker, markerInfo.Mode().Perm())
	}
	updates := map[string]string{
		"title":      title,
		"updated_at": time.Now().UTC().Format(time.RFC3339),
	}
	if err := updateMarkerFields(it.MarkerPath, updates); err != nil {
		return err
	}
	moved := newSlug != it.Slug
	if moved {
		if err := os.Rename(oldDir, newDir); err != nil {
			if restoreErr := restoreMarker(it.MarkerPath); restoreErr != nil {
				return exitError{code: 1, msg: fmt.Sprintf("rename failed: %v; marker rollback failed: %v", err, restoreErr)}
			}
			return err
		}
	}
	if _, err := loadTree(t.Root); err != nil {
		markerPath := it.MarkerPath
		if moved {
			if rollbackErr := os.Rename(newDir, oldDir); rollbackErr != nil {
				return exitError{code: 1, msg: fmt.Sprintf("rename made invalid worktree: %v; path rollback failed: %v", err, rollbackErr)}
			}
		} else {
			markerPath = filepath.Join(oldDir, it.Marker)
		}
		if restoreErr := restoreMarker(markerPath); restoreErr != nil {
			return exitError{code: 1, msg: fmt.Sprintf("rename made invalid worktree: %v; marker rollback failed: %v", err, restoreErr)}
		}
		return exitError{code: 2, msg: fmt.Sprintf("rename would make worktree invalid: %v", err)}
	}

	fmt.Fprintf(cmd.OutOrStdout(), "renamed id=%s from=%s to=%s title=%q changed=true\n", it.IDText, oldRel, newRel, title)
	return nil
}

type idRepair struct {
	Item   *item
	OldID  string
	NewID  string
	OldDir string
	NewDir string
	OldRel string
	NewRel string
}

func runDoctorFix(cmd *cobra.Command, rootPath string) error {
	t, err := loadTreeAllowDuplicateIDs(rootPath)
	if err != nil {
		return exitError{code: errorExitCode(err), msg: fmt.Sprintf("not fixable: %v", err)}
	}
	repairs, err := duplicateIDRepairs(t)
	if err != nil {
		return err
	}
	if len(repairs) == 0 {
		fmt.Fprintf(cmd.OutOrStdout(), "ok root=%s items=%d files=%d fixed=0\n", t.Root, len(t.Items), len(t.FileDirs))
		return nil
	}
	if err := applyIDRepairs(t.Root, repairs); err != nil {
		return err
	}
	verified, err := loadTree(t.Root)
	if err != nil {
		return exitError{code: 1, msg: fmt.Sprintf("fix made invalid worktree: %v", err)}
	}
	for _, repair := range repairs {
		fmt.Fprintf(cmd.OutOrStdout(), "fixed id=%s new_id=%s from=%s to=%s\n", repair.OldID, repair.NewID, repair.OldRel, repair.NewRel)
	}
	fmt.Fprintf(cmd.OutOrStdout(), "ok root=%s items=%d files=%d fixed=%d\n", verified.Root, len(verified.Items), len(verified.FileDirs), len(repairs))
	return nil
}

func duplicateIDRepairs(t *tree) ([]idRepair, error) {
	maxID := 0
	for _, it := range t.Items {
		if it.ID > maxID {
			maxID = it.ID
		}
	}
	var duplicateIDs []string
	for id, items := range t.ByID {
		if len(items) < 2 {
			continue
		}
		duplicateIDs = append(duplicateIDs, id)
	}
	sort.Slice(duplicateIDs, func(i, j int) bool {
		left, _ := strconv.Atoi(duplicateIDs[i])
		right, _ := strconv.Atoi(duplicateIDs[j])
		if left == right {
			return duplicateIDs[i] < duplicateIDs[j]
		}
		return left < right
	})
	var repairs []idRepair
	for _, id := range duplicateIDs {
		items := t.ByID[id]
		sortItems(items)
		for _, it := range items[1:] {
			maxID++
			newID := formatID(maxID, len(it.IDText))
			newDir := filepath.Join(filepath.Dir(it.Dir), newID+"-"+it.Slug)
			if _, err := os.Stat(newDir); err == nil {
				return nil, exitError{code: 2, msg: fmt.Sprintf("not fixable: destination exists for duplicate id %s: %s", id, relPath(t.Root, newDir))}
			} else if !errors.Is(err, fs.ErrNotExist) {
				return nil, err
			}
			repairs = append(repairs, idRepair{
				Item:   it,
				OldID:  it.IDText,
				NewID:  newID,
				OldDir: it.Dir,
				NewDir: newDir,
				OldRel: it.RelDir,
				NewRel: relPath(t.Root, newDir),
			})
		}
	}
	sort.Slice(repairs, func(i, j int) bool {
		return repairs[i].OldRel < repairs[j].OldRel
	})
	return repairs, nil
}

func applyIDRepairs(root string, repairs []idRepair) error {
	tmp, err := os.MkdirTemp("", "taskr-doctor-fix-*")
	if err != nil {
		return exitError{code: 1, msg: fmt.Sprintf("temporary directory unavailable: %v", err)}
	}
	defer os.RemoveAll(tmp)

	// Keep restorable backups in the platform temp directory, then rename only
	// inside the Taskr root so repair works across filesystem boundaries.
	for i, repair := range repairs {
		backupDir := filepath.Join(tmp, fmt.Sprintf("%03d-%s", i+1, filepath.Base(repair.OldDir)))
		if err := copyDir(repair.OldDir, backupDir); err != nil {
			return err
		}
	}
	applied := make([]idRepair, 0, len(repairs))
	for _, repair := range repairs {
		if err := os.Rename(repair.OldDir, repair.NewDir); err != nil {
			rollbackApplied(applied)
			return err
		}
		applied = append(applied, repair)
	}
	if _, err := loadTree(root); err != nil {
		rollbackApplied(applied)
		return err
	}
	return nil
}

func rollbackApplied(repairs []idRepair) {
	for i := len(repairs) - 1; i >= 0; i-- {
		_ = os.Rename(repairs[i].NewDir, repairs[i].OldDir)
	}
}

func copyDir(src, dest string) error {
	return filepath.WalkDir(src, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		rel, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}
		target := filepath.Join(dest, rel)
		info, err := entry.Info()
		if err != nil {
			return err
		}
		switch {
		case entry.Type()&os.ModeSymlink != 0:
			linkTarget, err := os.Readlink(path)
			if err != nil {
				return err
			}
			return os.Symlink(linkTarget, target)
		case entry.IsDir():
			return os.MkdirAll(target, info.Mode().Perm())
		case entry.Type().IsRegular():
			return copyFile(path, target, info.Mode().Perm())
		default:
			return nil
		}
	})
}

func copyFile(src, dest string, mode fs.FileMode) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.OpenFile(dest, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, mode)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		_ = out.Close()
		return err
	}
	return out.Close()
}

func formatID(id, width int) string {
	if width < 3 {
		width = 3
	}
	return fmt.Sprintf("%0*d", width, id)
}

func loadTree(rootPath string) (*tree, error) {
	t, err := loadTreeAllowEmpty(rootPath)
	if err != nil {
		return nil, err
	}
	return t, nil
}

func loadTreeAllowEmpty(rootPath string) (*tree, error) {
	return loadTreeWithOptions(rootPath, false)
}

func loadTreeAllowDuplicateIDs(rootPath string) (*tree, error) {
	return loadTreeWithOptions(rootPath, true)
}

func loadTreeWithOptions(rootPath string, allowDuplicateIDs bool) (*tree, error) {
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
	config, err := loadProjectConfig(abs)
	if err != nil {
		return nil, err
	}
	if err := validateConfiguredSite(abs, config); err != nil {
		return nil, err
	}
	t := &tree{Root: abs, ByID: map[string][]*item{}, ArchiveDir: "archive", Config: config}
	if err := scanDir(t, abs, nil); err != nil {
		return nil, err
	}
	sortItems(t.Items)
	for _, it := range t.Items {
		t.ByID[it.IDText] = append(t.ByID[it.IDText], it)
	}
	for id, items := range t.ByID {
		if len(items) > 1 {
			if allowDuplicateIDs {
				continue
			}
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
	itemType := markerTypes[marker]
	priority, err := effectivePriority(filepath.Join(dir, marker), itemType, fields["priority"])
	if err != nil {
		return nil, err
	}
	statusAt := make(map[string]string, len(statuses))
	for _, candidate := range statuses {
		field := candidate + "_at"
		if err := validateOptionalTimestamp(filepath.Join(dir, marker), field, fields[field]); err != nil {
			return nil, err
		}
		statusAt[candidate] = fields[field]
	}
	if err := validateOptionalTimestamp(filepath.Join(dir, marker), "reopened_at", fields["reopened_at"]); err != nil {
		return nil, err
	}
	return &item{
		ID:         id,
		IDText:     idText,
		Slug:       slug,
		Type:       itemType,
		Title:      title,
		Status:     status,
		Priority:   priority,
		CreatedAt:  fields["created_at"],
		UpdatedAt:  fields["updated_at"],
		StatusAt:   statusAt,
		ReopenedAt: fields["reopened_at"],
		Dir:        dir,
		RelDir:     relPath(root, dir),
		Marker:     marker,
		MarkerPath: filepath.Join(dir, marker),
		Parent:     parent,
	}, nil
}

func effectivePriority(path, itemType, stored string) (string, error) {
	if itemType != "task" {
		if stored != "" {
			return "", exitError{code: 2, msg: fmt.Sprintf("%s: priority is not valid for %s items", path, itemType)}
		}
		return "", nil
	}
	if stored == "" {
		return "normal", nil
	}
	if stored == "high" || stored == "low" {
		return stored, nil
	}
	if stored == "normal" {
		return "", exitError{code: 2, msg: fmt.Sprintf("%s: priority %q is redundant; omit it for normal", path, stored)}
	}
	return "", exitError{code: 2, msg: fmt.Sprintf("%s: invalid priority %q", path, stored)}
}

func validateOptionalTimestamp(path, field, value string) error {
	if value == "" {
		return nil
	}
	if _, err := time.Parse(time.RFC3339, value); err != nil {
		return exitError{code: 2, msg: fmt.Sprintf("%s: invalid %s timestamp %q", path, field, value)}
	}
	return nil
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
		return nil, exitError{code: 2, msg: fmt.Sprintf("ambiguous selector %q; candidates:%s", selector, candidateList(matches))}
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

func mustRegisterCompletion(cmd *cobra.Command, flagName string, fn func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective)) {
	if err := cmd.RegisterFlagCompletionFunc(flagName, fn); err != nil {
		panic(err)
	}
}

func staticCompletion(values []string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		return filterCompletions(values, toComplete), cobra.ShellCompDirectiveNoFileComp
	}
}

func selectorArgCompletion(rootPath string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		if len(args) > 0 {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		return selectorCompletion(rootPath)(cmd, args, toComplete)
	}
}

func selectorCompletion(rootPath string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return filteredSelectorCompletion(rootPath, func(*item) bool { return true })
}

func treeArgCompletion(rootPath string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		if len(args) > 0 {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		return treeRootCompletion(rootPath)(cmd, args, toComplete)
	}
}

func moveArgCompletion(rootPath string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		if len(args) > 0 {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		return filteredSelectorCompletion(rootPath, func(it *item) bool {
			return it.Type == "task" || it.Type == "subtask"
		})(cmd, args, toComplete)
	}
}

func treeRootCompletion(rootPath string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return filteredSelectorCompletion(rootPath, func(it *item) bool {
		return it.Type == "milestone" || (it.Type == "task" && len(it.Children) > 0)
	})
}

func displayParentCompletion(rootPath string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return treeRootCompletion(rootPath)
}

func writeParentCompletion(rootPath string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return filteredSelectorCompletion(rootPath, func(it *item) bool {
		return it.Type == "milestone" || it.Type == "task"
	})
}

func moveParentCompletion(rootPath string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		t, err := loadTree(rootPath)
		if err != nil {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		sourceType := ""
		if len(args) > 0 {
			if source, err := resolveItem(t, args[0]); err == nil {
				sourceType = source.Type
			}
		}
		include := func(it *item) bool {
			switch sourceType {
			case "task":
				return it.Type == "milestone"
			case "subtask":
				return it.Type == "task"
			case "milestone":
				return false
			default:
				return it.Type == "milestone" || it.Type == "task"
			}
		}
		return filterCompletions(selectorCompletions(t, include), toComplete), cobra.ShellCompDirectiveNoFileComp
	}
}

func filteredSelectorCompletion(rootPath string, include func(*item) bool) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		t, err := loadTree(rootPath)
		if err != nil {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		return filterCompletions(selectorCompletions(t, include), toComplete), cobra.ShellCompDirectiveNoFileComp
	}
}

func selectorCompletions(t *tree, include func(*item) bool) []string {
	var values []string
	seen := map[string]bool{}
	for _, it := range t.Items {
		if !include(it) {
			continue
		}
		label := fmt.Sprintf("%s %s %s", it.Type, it.Status, it.Title)
		for _, value := range []string{it.IDText, it.Slug} {
			if value == "" || seen[value] {
				continue
			}
			seen[value] = true
			values = append(values, fmt.Sprintf("%s\t%s", value, label))
		}
	}
	sort.Strings(values)
	return values
}

func filterCompletions(values []string, prefix string) []string {
	if prefix == "" {
		return append([]string(nil), values...)
	}
	var out []string
	for _, value := range values {
		candidate := value
		if before, _, ok := strings.Cut(value, "\t"); ok {
			candidate = before
		}
		if strings.HasPrefix(candidate, prefix) {
			out = append(out, value)
		}
	}
	return out
}

func filteredItems(t *tree, under, typeFilter, statusFilter, priorityFilter string, includeAll bool) ([]*item, error) {
	if typeFilter != "" {
		if _, ok := typeMarkers[typeFilter]; !ok {
			return nil, exitError{code: 2, msg: fmt.Sprintf("invalid type %q", typeFilter)}
		}
	}
	if statusFilter != "" && !validStatuses[statusFilter] {
		return nil, exitError{code: 2, msg: fmt.Sprintf("invalid status %q", statusFilter)}
	}
	if !includeAll && closedStatus(statusFilter) {
		return nil, exitError{code: 2, msg: fmt.Sprintf("status %q requires --all", statusFilter)}
	}
	if priorityFilter != "" && !isPriority(priorityFilter) {
		return nil, exitError{code: 2, msg: fmt.Sprintf("invalid priority %q", priorityFilter)}
	}
	items, err := resolveUnder(t, under)
	if err != nil {
		return nil, err
	}
	var out []*item
	for _, it := range items {
		if !includeAll && closedStatus(it.Status) {
			continue
		}
		if typeFilter != "" && it.Type != typeFilter {
			continue
		}
		if statusFilter != "" && it.Status != statusFilter {
			continue
		}
		if priorityFilter != "" && (it.Type != "task" || it.Priority != priorityFilter) {
			continue
		}
		out = append(out, it)
	}
	sortItems(out)
	return out, nil
}

func compileLineGlobs(patterns []string) ([]*regexp.Regexp, error) {
	compiled := make([]*regexp.Regexp, 0, len(patterns))
	for _, pattern := range patterns {
		expression, err := lineGlobExpression(pattern)
		if err != nil {
			return nil, exitError{code: 2, msg: fmt.Sprintf("invalid glob %q: %v", pattern, err)}
		}
		matcher, err := regexp.Compile("(?i)^.*(?:" + expression + ").*$")
		if err != nil {
			return nil, exitError{code: 2, msg: fmt.Sprintf("invalid glob %q: %v", pattern, err)}
		}
		compiled = append(compiled, matcher)
	}
	return compiled, nil
}

func lineGlobExpression(pattern string) (string, error) {
	var expression strings.Builder
	for index := 0; index < len(pattern); index++ {
		switch pattern[index] {
		case '*':
			expression.WriteString(".*")
		case '?':
			expression.WriteByte('.')
		case '\\':
			index++
			if index >= len(pattern) {
				return "", errors.New("trailing escape")
			}
			expression.WriteString(regexp.QuoteMeta(pattern[index : index+1]))
		case '[':
			end := index + 1
			for end < len(pattern) && pattern[end] != ']' {
				if pattern[end] == '\\' {
					end++
				}
				end++
			}
			if end >= len(pattern) {
				return "", errors.New("unterminated character class")
			}
			class := pattern[index+1 : end]
			if class == "" {
				return "", errors.New("empty character class")
			}
			expression.WriteByte('[')
			if class[0] == '!' {
				expression.WriteByte('^')
				class = class[1:]
			}
			if class == "" {
				return "", errors.New("empty character class")
			}
			expression.WriteString(class)
			expression.WriteByte(']')
			index = end
		default:
			expression.WriteString(regexp.QuoteMeta(pattern[index : index+1]))
		}
	}
	return expression.String(), nil
}

func filterItemsByMarkerGlobs(items []*item, globs []*regexp.Regexp) ([]*item, error) {
	if len(globs) == 0 {
		return items, nil
	}
	filtered := make([]*item, 0, len(items))
	for _, it := range items {
		content, err := os.ReadFile(it.MarkerPath)
		if err != nil {
			return nil, err
		}
		lines := strings.Split(string(content), "\n")
		matchesAll := true
		for _, glob := range globs {
			matched := false
			for _, line := range lines {
				if glob.MatchString(line) {
					matched = true
					break
				}
			}
			if !matched {
				matchesAll = false
				break
			}
		}
		if matchesAll {
			filtered = append(filtered, it)
		}
	}
	return filtered, nil
}

type treeOptions struct {
	includeAll bool
	format     string
	indent     string
	priority   priorityDisplay
}

func newTreeOptions(includeAll, ascii, tabs, wide, showPriority, hidePriority bool) (treeOptions, error) {
	if tabs && wide {
		return treeOptions{}, exitError{code: 2, msg: "tree format flags --tabs and --wide cannot be used together"}
	}
	if showPriority && hidePriority {
		return treeOptions{}, exitError{code: 2, msg: "tree flags --show-priority and --hide-priority are mutually exclusive"}
	}
	opts := treeOptions{includeAll: includeAll, indent: "  ", priority: priorityDisplayAuto}
	if showPriority {
		opts.priority = priorityDisplayShow
	} else if hidePriority {
		opts.priority = priorityDisplayHide
	}
	switch {
	case ascii:
		opts.format = "ascii"
	case tabs:
		opts.format = "indent"
		opts.indent = "\t"
	case wide:
		opts.format = "indent"
		opts.indent = "    "
	default:
		opts.format = "indent"
	}
	return opts, nil
}

func writeTree(w interface{ Write([]byte) (int, error) }, roots []*item, opts treeOptions) {
	visible := visibleItems(roots, opts)
	for i, it := range visible {
		writeTreeItem(w, it, "", 0, i == len(visible)-1, true, opts)
	}
}

func writeTreeItem(w interface{ Write([]byte) (int, error) }, it *item, prefix string, depth int, last bool, root bool, opts treeOptions) {
	if opts.format == "ascii" {
		writeASCIITreeItem(w, it, prefix, last, root, opts)
		return
	}
	fmt.Fprintf(w, "%s%s [%s] %s\n", strings.Repeat(opts.indent, depth), it.IDText, treeItemMeta(it, opts.priority), it.Title)
	children := visibleItems(it.Children, opts)
	for i, child := range children {
		writeTreeItem(w, child, "", depth+1, i == len(children)-1, false, opts)
	}
}

func writeASCIITreeItem(w interface{ Write([]byte) (int, error) }, it *item, prefix string, last bool, root bool, opts treeOptions) {
	if root {
		fmt.Fprintf(w, "%s [%s] %s\n", it.IDText, treeItemMeta(it, opts.priority), it.Title)
	} else {
		fmt.Fprintf(w, "%s+- %s [%s] %s\n", prefix, it.IDText, treeItemMeta(it, opts.priority), it.Title)
	}
	childPrefix := prefix
	if !root {
		if last {
			childPrefix += "   "
		} else {
			childPrefix += "|  "
		}
	}
	children := visibleItems(it.Children, opts)
	for i, child := range children {
		writeASCIITreeItem(w, child, childPrefix, i == len(children)-1, false, opts)
	}
}

func visibleItems(items []*item, opts treeOptions) []*item {
	var out []*item
	sorted := append([]*item(nil), items...)
	if allTasks(sorted) {
		sortItemsByPriority(sorted)
	} else {
		sortItems(sorted)
	}
	for _, it := range sorted {
		if treeItemVisible(it, opts) {
			out = append(out, it)
		}
	}
	return out
}

func allTasks(items []*item) bool {
	if len(items) == 0 {
		return false
	}
	for _, it := range items {
		if it.Type != "task" {
			return false
		}
	}
	return true
}

func treeItemMeta(it *item, mode priorityDisplay) string {
	meta := it.Type + " " + it.Status
	if it.Type == "task" && (mode == priorityDisplayShow || mode == priorityDisplayAuto && it.Priority != "normal") {
		meta += " priority=" + it.Priority
	}
	return meta
}

func treeItemVisible(it *item, opts treeOptions) bool {
	if opts.includeAll {
		return true
	}
	return !closedStatus(it.Status)
}

func closedStatus(status string) bool {
	return status == "done" || status == "cancelled"
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

func isDescendantOf(candidate, parent *item) bool {
	for current := candidate.Parent; current != nil; current = current.Parent {
		if current == parent {
			return true
		}
	}
	return false
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

func isInitialStatus(status string) bool {
	for _, candidate := range initialStatuses {
		if status == candidate {
			return true
		}
	}
	return false
}

func newMarker(title, status string) string {
	now := time.Now().UTC().Format(time.RFC3339)
	return fmt.Sprintf(`---
title: %s
status: %s
created_at: %s
updated_at: %s
%s_at: %s
---

# Description

# Acceptance

# Comments

# Outcome
`, title, status, now, now, status, now)
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

func updateMarkerFields(path string, updates map[string]string) error {
	return rewriteMarkerFields(path, updates, nil)
}

func rewriteMarkerFields(path string, updates map[string]string, remove map[string]bool) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	lines := strings.Split(string(data), "\n")
	out := make([]string, 0, len(lines)+len(updates))
	inFrontmatter := false
	updated := make(map[string]bool, len(updates))
	frontmatterEnded := false
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if i == 0 && trimmed == "---" {
			inFrontmatter = true
			out = append(out, line)
			continue
		}
		if inFrontmatter && trimmed == "---" {
			var additions []string
			for key, value := range updates {
				if !updated[key] {
					additions = append(additions, key+": "+value)
				}
			}
			sort.Strings(additions)
			out = append(out, additions...)
			out = append(out, line)
			inFrontmatter = false
			frontmatterEnded = true
			continue
		}
		if !inFrontmatter {
			out = append(out, line)
			continue
		}
		key, _, ok := strings.Cut(trimmed, ":")
		if ok && remove[key] {
			continue
		}
		if ok {
			if value, exists := updates[key]; exists {
				out = append(out, key+": "+value)
				updated[key] = true
				continue
			}
		}
		out = append(out, line)
	}
	if !frontmatterEnded {
		return exitError{code: 2, msg: fmt.Sprintf("%s: unterminated frontmatter", path)}
	}
	return os.WriteFile(path, []byte(strings.Join(out, "\n")), 0o644)
}

func statusLabel(status string) string {
	if status == "" {
		return status
	}
	return strings.ToUpper(status[:1]) + status[1:]
}

func isClosedStatus(status string) bool {
	return status == "done" || status == "cancelled"
}

func commentLines(args []string, fromStdin bool) ([]string, error) {
	if fromStdin {
		if len(args) > 0 {
			return nil, exitError{code: 2, msg: "comment text arguments cannot be used with --stdin"}
		}
		data, err := io.ReadAll(os.Stdin)
		if err != nil {
			return nil, err
		}
		return normalizeCommentLines(string(data))
	}
	if len(args) == 0 {
		return nil, exitError{code: 2, msg: "comment requires text or --stdin"}
	}
	return normalizeCommentLines(strings.Join(args, " "))
}

func normalizeCommentLines(text string) ([]string, error) {
	text = strings.ReplaceAll(text, "\r\n", "\n")
	text = strings.ReplaceAll(text, "\r", "\n")
	var lines []string
	for _, line := range strings.Split(text, "\n") {
		normalized := strings.Join(strings.Fields(line), " ")
		if normalized == "" {
			continue
		}
		lines = append(lines, normalized)
	}
	if len(lines) == 0 {
		return nil, exitError{code: 2, msg: "comment text is empty"}
	}
	return lines, nil
}

func appendComment(path string, comment []string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	lines := strings.Split(string(data), "\n")
	commentsIdx := -1
	outcomeIdx := -1
	for i, line := range lines {
		switch strings.TrimSpace(line) {
		case "# Comments":
			commentsIdx = i
		case "# Outcome":
			outcomeIdx = i
		}
	}
	if commentsIdx < 0 {
		return exitError{code: 2, msg: fmt.Sprintf("%s: missing # Comments section", path)}
	}
	if outcomeIdx < 0 {
		return exitError{code: 2, msg: fmt.Sprintf("%s: missing # Outcome section", path)}
	}
	if commentsIdx > outcomeIdx {
		return exitError{code: 2, msg: fmt.Sprintf("%s: # Comments must precede # Outcome", path)}
	}
	entry := formatCommentEntry(comment)
	insert := append([]string{""}, entry...)
	if outcomeIdx > 0 && strings.TrimSpace(lines[outcomeIdx-1]) == "" {
		before := append([]string{}, lines[:outcomeIdx-1]...)
		after := append([]string{}, lines[outcomeIdx-1:]...)
		lines = append(append(before, insert...), after...)
	} else {
		insert = append(insert, "")
		before := append([]string{}, lines[:outcomeIdx]...)
		after := append([]string{}, lines[outcomeIdx:]...)
		lines = append(append(before, insert...), after...)
	}
	return os.WriteFile(path, []byte(strings.Join(lines, "\n")), 0o644)
}

func formatCommentEntry(lines []string) []string {
	stamp := time.Now().Format("2006-01-02 15:04")
	if len(lines) == 1 {
		return []string{fmt.Sprintf("- %s: %s", stamp, lines[0])}
	}
	entry := []string{fmt.Sprintf("- %s:", stamp)}
	for _, line := range lines {
		entry = append(entry, "  "+line)
	}
	return entry
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
	writeItemLinesWithPriority(w, items, withType, priorityDisplayHide)
}

type priorityDisplay int

const (
	priorityDisplayAuto priorityDisplay = iota
	priorityDisplayShow
	priorityDisplayHide
)

func writeItemLinesWithPriority(w interface{ Write([]byte) (int, error) }, items []*item, withType bool, mode priorityDisplay) {
	for _, it := range items {
		priority := ""
		if it.Type == "task" && (mode == priorityDisplayShow || mode == priorityDisplayAuto && it.Priority != "normal") {
			priority = " priority=" + it.Priority
		}
		if withType {
			fmt.Fprintf(w, "%s %s %s%s %s\n", it.IDText, it.Type, it.Status, priority, it.Title)
		} else {
			fmt.Fprintf(w, "%s %s%s %s\n", it.IDText, it.Status, priority, it.Title)
		}
	}
}

func writePriorityGroups(w interface{ Write([]byte) (int, error) }, items []*item, mode priorityDisplay) {
	for _, priority := range priorities {
		fmt.Fprintf(w, "Priority: %s\n", priority)
		var group []*item
		for _, it := range items {
			if it.Priority == priority {
				group = append(group, it)
			}
		}
		rowMode := priorityDisplayHide
		if mode == priorityDisplayShow {
			rowMode = mode
		}
		for _, it := range group {
			priorityText := ""
			if rowMode == priorityDisplayShow {
				priorityText = " priority=" + it.Priority
			}
			fmt.Fprintf(w, "  %s %s %s%s %s\n", it.IDText, it.Type, it.Status, priorityText, it.Title)
		}
	}
}

func sortItemsByPriority(items []*item) {
	rank := map[string]int{"high": 0, "normal": 1, "low": 2}
	sort.SliceStable(items, func(i, j int) bool {
		if rank[items[i].Priority] == rank[items[j].Priority] {
			if items[i].ID == items[j].ID {
				return items[i].RelDir < items[j].RelDir
			}
			return items[i].ID < items[j].ID
		}
		return rank[items[i].Priority] < rank[items[j].Priority]
	})
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
		parts = append(parts, fmt.Sprintf("\n%s %s", it.IDText, it.Title))
	}
	return strings.Join(parts, "")
}

var nonSlug = regexp.MustCompile(`[^a-z0-9]+`)

func slugify(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	s = nonSlug.ReplaceAllString(s, "-")
	return strings.Trim(s, "-")
}
