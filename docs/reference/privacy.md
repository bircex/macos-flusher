# Privacy and permissions

MacOS Flusher works entirely on your Mac.

- It makes no network requests.
- It has no account, no analytics and no crash reporting.
- It stores no data of its own.

The source code is public, so every statement on this page can be checked in the [repository](https://github.com/bircex/macos-flusher).

## What the app reads

| What | Why | How |
| --- | --- | --- |
| Size of each cache folder | To show how much a flush would free | `du` |
| Docker usage | To show reclaimable Docker data | `docker system df` and `docker images` |
| Size of home folders, `/Applications` and system folders | To build the location chart | `du` |
| Total and free disk space | To draw the donut and the disk bar | macOS volume information |
| `PATH` of your login shell | To find installed tools | `zsh -lc` |

The app reads sizes only. It does not open, index or copy file contents.

## What the app changes

The app deletes only what you select, and only after you confirm the flush.

- It deletes inside the folders listed in [What gets cleaned](/reference/catalog).
- It runs the cleanup commands listed there.
- It writes nothing else. It installs no helper, no login item and no background service.

## Permissions macOS asks for

macOS protects some folders and asks before an app can read them. The prompts appear the first time the disk analysis runs.

| Prompt | Needed for | If you decline |
| --- | --- | --- |
| Desktop folder | Size of `~/Desktop` | Counted under Everything else |
| Documents folder | Size of `~/Documents` | Counted under Everything else |
| Downloads folder | Size of `~/Downloads` | Counted under Everything else |
| Data from other apps | Size of app data under `~/Library` | Counted under Everything else |

Declining never blocks scanning or flushing. Only the location chart becomes less detailed.

The app does not ask for Full Disk Access. Folders that need it, such as Mail and Messages data, are counted under Everything else.

## Commands the app runs

The app starts these programs. All of them are part of macOS or tools you installed yourself.

| Program | Used for |
| --- | --- |
| `/usr/bin/du` | Measuring folders |
| `/bin/zsh` | Reading the `PATH` and running cleanup commands |
| `docker`, `podman` | Measuring and pruning container data |
| `go`, `npm`, `brew` | Running their own cleanup commands |

Cleanup commands run with your user account. The app never asks for an administrator password.

## Code signing

Release builds are signed locally and are not notarized by Apple. That is why macOS asks you to allow a downloaded copy the first time. [First launch](/guide/first-launch#allow-the-app-to-open) explains the prompt.

To check that a download is the file that was published, compare its checksum as shown in [Verify a download](/guide/install#verify-a-download).
