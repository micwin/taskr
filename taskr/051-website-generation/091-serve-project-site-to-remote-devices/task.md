---
title: Serve project site to remote devices
status: designing
created_at: 2026-08-13T15:44:45Z
updated_at: 2026-08-13T15:44:45Z
designing_at: 2026-08-13T15:44:45Z
---

# Description

Add an explicit workflow for serving a generated Taskr project site to another
computer or device. The feature is separate from `taskr site open`, whose local
preview remains bound to loopback and must not expose project data to the
network implicitly.

The command surface and security model must be designed with the user before
implementation. Candidate use cases include opening the site from another
device on the same trusted network and deliberately binding to one selected
network interface.

# Acceptance

- The design chooses a command surface distinct from local `taskr site open`,
  comparing forms such as `taskr site serve` and an explicit remote flag.
- Remote serving occurs only after an explicit user command and never as a
  side effect of normal local open or watch behavior.
- Bind address and port behavior are explicit. Taskr does not default to every
  interface without communicating the exposure clearly.
- Startup prints the actual local and remotely usable URLs and identifies the
  selected network interface or address.
- The design defines behavior for multiple interfaces, unavailable addresses,
  occupied ports, IPv4 and IPv6, firewall restrictions, and clean shutdown.
- The threat model covers unencrypted project content, untrusted local
  networks, authentication, TLS, browser caching, and accidental public
  exposure before implementation starts.
- The initial scope explicitly decides whether serving is limited to trusted
  local networks or may support internet-facing use. Taskr does not imply
  production-grade public hosting without implementing the required controls.
- Site generation and optional source watching reuse tasks `081` and `082`
  rather than introducing a second site format or watcher.
- Smokey uses loopback or controlled network namespaces and never exposes test
  fixtures to a production network.
- Help, examples, completion, documentation, Doctor impact, and public API
  impact are reviewed for the final command surface.

# Comments

- 2026-08-13: Created while specifying local `site open --watch`. Local preview
  remains loopback-only; remote access is deliberately separated so network
  exposure cannot happen accidentally.

# Outcome
