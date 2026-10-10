# Security Policy

MacOS Flusher deletes files and runs shell commands on the machine it is installed on. A bug that makes it delete, read or run something it should not is a security issue, not just a regular bug.

## Supported versions

Only the latest release is supported. Versions are calendar-based (`YYYY.M.PATCH`); there are no long-term maintenance branches.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Instead, use [GitHub Security Advisories](https://github.com/bircex/macos-flusher/security/advisories/new) for this repository, or open an issue and mark it clearly as sensitive so it can be moved to a private channel.

Include, where possible:

- The exact target or flow involved (a built-in target's id, or "My targets" with your folder/command).
- What you expected to happen and what actually happened.
- Whether the issue could delete, expose or run something outside what the app shows in its list before you confirm.

## What is in scope

- A built-in or custom target deleting outside the folder it claims to touch.
- A target's "own cleanup command" running something other than what is shown.
- Anything that bypasses the responsibility confirmation for a custom target, or the delete confirmation dialog.
- Path handling bugs (symlinks, `..`, globs) that let a target escape its intended folder.

## What is out of scope

- The app not being notarized yet; Gatekeeper's own warning is expected until that changes.
- A target correctly deleting a cache that a user did not expect to lose data from; the responsibility text and the per-target risk labels (`slow to get back`, `deleted for good`) exist for exactly this.

The app makes no network requests and sends no data anywhere, so account, server or data-exfiltration reports do not apply here.
