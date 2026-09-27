# Troubleshooting

Start with the activity log. Every failed step is listed there as an **ERROR** line with the message from the tool that failed.

## The app does not open

macOS says the app could not be verified, or that it is damaged.

The app is not notarized by Apple, and macOS blocks copies downloaded with a browser. Follow [Allow the app to open](/guide/first-launch#allow-the-app-to-open).

## Docker

### Cannot connect to the Docker daemon

Docker is installed but not running. Start Docker Desktop, wait until it is ready and press **Scan**.

### Docker rows show "empty" although Docker uses a lot of space

The Docker rows show what Docker reports as reclaimable, not everything Docker stores.

- Images used by a container are not reclaimable.
- Named volumes are never counted and never removed.

The total size of Docker is in the **Docker** row of the location chart.

### read-only file system

The flush fails with a message that ends in `read-only file system`.

This happens after the Mac ran out of disk space while Docker was running. Docker's virtual disk switches to read-only to protect itself and stays that way, even after space is free again.

1. Free some space first. Flush the caches that are not from Docker.
2. Quit Docker Desktop and start it again.
3. Press **Scan**, then flush the Docker caches.

::: warning Check your containers
Databases and other containers that were writing when the disk filled up may have lost their last writes. Check them after Docker restarts.
:::

### The disk image does not shrink after a flush

Docker Desktop returns freed space to macOS with a delay. Restarting Docker Desktop usually speeds this up.

## A tool is shown as "not installed"

The app looks for tools in these folders, followed by the `PATH` of your login shell:

```text
/opt/homebrew/bin
/usr/local/bin
/usr/bin
/bin
/usr/sbin
/sbin
~/go/bin
~/.cargo/bin
```

If a tool lives somewhere else, add that folder to `PATH` in `~/.zprofile`, then quit and reopen the app.

## The disk analysis does not finish

The header of the location chart stays at "Analyzing".

macOS is waiting for an answer to a folder access prompt. The prompt can be hidden behind other windows. Answer it and the analysis continues.

## "Everything else" is very large

The app could not read some folders. Allow access when macOS asks, or accept that those folders are counted together. [Folder access prompts](/guide/first-launch#folder-access-prompts) explains the prompts.

## Sizes differ from Finder

The app measures the space that files occupy on disk. Finder often shows the size of the file contents. The two differ for:

- Sparse files such as the Docker disk image, which occupy less than their nominal size
- Files that are stored in iCloud and not downloaded
- Files that share storage because they were copied on the same disk

## Less space was freed than selected

- A cache failed. Look for **ERROR** lines in the log.
- A tool rebuilt part of its cache while the flush ran.
- macOS keeps deleted files in local snapshots for a while. The space becomes free when the snapshot expires.

## A cache comes back after the flush

That is expected. Caches are rebuilt the next time you install packages or build a project. Flush again when you need the space.

## Report a problem

Open an issue on [GitHub](https://github.com/bircex/macos-flusher/issues) and include:

- The macOS version and the app version from **MacOS Flusher > About MacOS Flusher**
- The **ERROR** lines from the activity log
