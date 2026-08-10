# Taskr MVP Workflows

MVP workflows are defined at behavior level. Concrete command names, arguments,
and flags are derived in the command-definition task.

All MVP workflows must be fully executable with only the Taskr CLI and a text
editor. A user must not need a web UI, generated sidecar database, or duplicate
entry of the same information to complete a workflow. Structured facts live in
the directory name, marker filename, or marker frontmatter; prose lives in the
marker body or in `files.md` containers.

```mermaid
flowchart TD
    A[Discover or select root] --> B{Operation}
    B --> C[Create item]
    B --> D[Resolve item selector]
    B --> E[Doctor root]

    C --> C1[Choose parent]
    C1 --> C2[Allocate next root-unique ID]
    C2 --> C3[Write marker template]
    C3 --> C4[Optionally open editor]

    D --> D1{Exactly one match?}
    D1 -->|No matches| X1[Fail: not found]
    D1 -->|Multiple matches| X2[Fail: print candidates]
    D1 -->|One match| F{Item operation}

    F --> G[Change status]
    F --> H[Open marker]
    F --> I[Show or list]
    F --> J[Report]
    F --> K[Archive subtree]

    G --> G1[Validate children]
    G1 --> G2[Write status]

    K --> K1[Require closed subtree]
    K1 --> K2[Move directory to archive]

    E --> E1[Validate markers and structure]
    E1 --> E2[Print pass or failure summary]
```

# Shared Selector Workflow

Most item-oriented operations accept an item selector. The selector can match by
root-unique ID, directory slug, marker filename context, title, or marker/body
content.

Normal flow:

1. User provides a selector.
2. Taskr resolves it within the active root.
3. If exactly one item matches, the operation continues with that item.

Failure cases:

- No item matches: fail with a clear not-found message.
- More than one item matches: fail and print the matching candidates.
- A matched directory is structurally invalid: fail and point at the invalid
  path.

Expected output:

- Successful mutating operations print the affected item path and effective
  status.
- Ambiguous selector failures print enough candidate information for the user to
  choose a narrower selector.

# Create Item Workflow

User provides a work-item type and title, plus an optional parent selector.
Taskr creates the next root-unique ID, derives a slug from the title, creates
the item directory under the selected parent, writes the correct marker
template, and optionally opens the marker in the configured editor.

Normal flow:

1. Resolve the parent when one is provided.
2. Derive allowed hierarchy relationships from the existing root.
3. Validate that the requested type is allowed under that parent by the derived
   hierarchy.
4. Find the next numeric ID that is unused anywhere in the root.
5. Create `<next-id>-<slug>/`.
6. Create `milestone.md`, `task.md`, or `subtask.md` from the template.
7. Set initial status to `open` unless the user explicitly asks for another
   allowed initial status.
8. Open the marker in the editor when requested by config or option.

Failure cases:

- Parent selector is missing when required.
- Parent selector is ambiguous or not found.
- Requested type is not valid for the selected parent.
- Target directory already exists.
- Requested slug already exists for the same role in the root.
- Duplicate IDs already exist in the root; refuse every command except doctor
  and future repair.
- Editor launch fails after creation; report the created marker path.

Expected output:

- Created item path.
- Created root-unique item ID.
- Marker filename.
- Whether the editor was opened.

# Change Status Workflow

User selects an item and requests a new status. Taskr validates the transition
against the item's children before writing.

Normal flow:

1. Resolve the item selector.
2. Load the selected item and child tree.
3. Validate the requested status. `developing` is the normal state for active
   implementation, and `reviewing` is the normal state for work that is
   implemented and ready for user review.
4. If setting a parent item to `done`, verify all completion children are done.
5. If setting an item to `cancelled`, keep children unchanged unless the user
   explicitly requests a recursive cancellation workflow later.
6. Write the new status and update `updated_at`.

Failure cases:

- Status is not allowed.
- User tries to mark a parent `done` while completion children are not done.
- Marker cannot be parsed or written.

Expected output:

- Old status and new status.
- Effective completion status.
- Blocking child paths when the requested status is rejected.

# Open Item Workflow

User selects an item and chooses to open it with the configured editor or system
opener. The default opener is the editor.

Normal flow:

1. Resolve the selector.
2. Select the marker file by default.
3. Open the marker with `$EDITOR` or the editor configured in personal Taskr
   config.
4. If user requests system opener, open through the platform opener.

Failure cases:

- Selector is missing, ambiguous, or not found.
- Editor/opener is not configured or exits non-zero.

Expected output:

- Path opened.
- Opener used.

# Show/List Workflow

User asks to inspect one item, the current root, or a subtree. Taskr prints a
human-readable view to stdout.

Normal flow:

1. Resolve selector when provided.
2. Load the relevant subtree.
3. Print item type, ID, title, status, effective completion state, and
   child summary.

Failure cases:

- Selector is ambiguous or not found.
- Worktree is invalid.

Expected output:

- Stable text output suitable for Smokey assertions.
- No editor or pager required for MVP.

# Report Workflow

User requests a repository report. Taskr summarizes the top-level root by
status and milestone, then writes the report to stdout or to a target file.

Normal flow:

1. Render a deterministic report with root summary, status statistics, and
   milestone sections.
2. List open milestones without tickets in their own section.
3. Use explicit headings when a list is truncated, for example a current-work
   section that shows five of a larger set.
4. Write to stdout unless a target file is provided.

Failure cases:

- Unsupported filter flags are rejected.
- Target file cannot be written.

Expected output:

- For stdout reports: deterministic text.
- For file reports: written path.

# Doctor Workflow

User validates the root. Taskr checks the worktree format from
`doc/taskr-worktree-format.md`.

Normal flow:

1. Discover or select root.
2. Walk directories outside `files.md` containers.
3. Validate marker count, marker format, required sections, ID prefixes,
   statuses, timestamps, root-unique IDs, per-role slug uniqueness, derived
   hierarchy consistency, and structural completion.
4. Print a summary.

Failure cases:

- Invalid root.
- Directory with zero or multiple recognized markers.
- Duplicate IDs.
- Duplicate slugs for the same role.
- Item whose parent/child role pair conflicts with the derived hierarchy.
- Invalid marker frontmatter or body sections.
- Invalid completion state.

Expected output:

- Pass summary with checked item count.
- Failure list with paths and concise reasons.

# Archive Workflow

User archives a completed subtree. Archive is a move, not a status change.

Normal flow:

1. Resolve the selected item.
2. Verify the selected subtree is closed (`done` or `cancelled`) and no active
   work remains inside it.
3. Move the whole directory below the root archive location. `--to 2026` means
   `archive/2026` below the Taskr root.
4. Preserve marker files, outcomes, comments, children, and file containers.

Failure cases:

- Selected item or descendants are still active/open/designing/developing/reviewing/blocked.
- Destination already exists.
- Filesystem move fails.

Expected output:

- Source path.
- Destination path.
- Number of moved work items.
