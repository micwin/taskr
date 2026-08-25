---
title: Report mounted roots
status: blocked
created_at: 2026-08-25T17:20:20Z
updated_at: 2026-08-25T20:13:09Z
designing_at: 2026-08-25T17:20:20Z
developing_at: 2026-08-25T18:56:59Z
blocked_at: 2026-08-25T20:13:09Z
---

# Description

Extend `taskr report` and the report-like overview portion of generated sites
so repository reports include mounted roots and mounted items with explicit
source identity.

# Acceptance

- Reports include mount objects or a dedicated mounted-roots section.
- Mounted item counts and visible rows include mount identity.
- Local and mounted items with the same numeric ID or slug remain
  distinguishable.
- Report status, priority, and tag summaries include mounted items according to
  documented rules.
- The generated site's report-like overview uses the same mounted-root report
  data: mounted root section, mounted status counts, mounted priority/tag
  summaries, and source-qualified visible rows.
- Unavailable mounts fail clearly.
- Help, docs, and examples cover mounted report output.
- Smokey covers mounted report section/counts, local/mounted collision
  readability, tags, priorities, site report overview output, and unavailable
  mount failure.

# Comments

- 2026-08-25: Report-specific slice of ticket 099.
- 2026-08-25: The report-like overview in generated sites belongs to this
  report slice too. It must stay consistent with `taskr report` when mounted
  roots are included.

- 2026-08-25 22:13: Blocked on branch report-mounted-roots: the fixture creates three mounted reviewing tasks but the accepted status assertion expects two while its priority and tag assertions count all three. The branch corrects the reviewing count to three.

# Outcome
