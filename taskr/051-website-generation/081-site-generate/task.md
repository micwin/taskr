---
title: Generate project site
status: designing
created_at: 2026-08-10T18:03:26Z
updated_at: 2026-08-10T18:03:30Z
designing_at: 2026-08-10T18:03:30Z
---

# Description

Add `taskr site generate <target-directory>`. The command renders the project
managed by the selected Taskr root as a static site in the requested directory.
The generated `index.html` must be directly usable with a browser and must not
require a Taskr process or web server after generation.

# Acceptance

- `taskr site generate <target-directory>` uses Taskr's normal root discovery
  and writes the generated site beneath the explicit target directory.
- Successful generation creates `<target-directory>/index.html`.
- Generated pages, links, styles, and assets work when `index.html` is opened
  through a local `file:` URL without a web server.
- Generation does not modify marker files or other source data in the Taskr
  root.
- Site generation reuses one rendering implementation that can also support
  `taskr site open`; the two commands do not maintain separate site formats.
- The design defines behavior for a missing, existing empty, existing nonempty,
  nested, unwritable, or source-overlapping target directory before
  implementation starts.
- Partial output is not presented as a successful site when rendering fails.
- Command output reports the generated index path in a script-friendly form.
- Smokey verifies generated structure and representative project content using
  a temporary target under Smokey-managed state.
- Help, examples, completion, documentation, Doctor impact, and public API
  impact are reviewed for the final command and flags.

# Comments

- 2026-08-10: This command owns persistent output. Temporary preview and browser
  launch behavior belong to task `082`.

# Outcome
