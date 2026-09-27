# Scan and flush

The whole workflow is three steps: scan, choose, flush.

![Main window of MacOS Flusher](/shots/main-light.png){.shot .light-only}
![Main window of MacOS Flusher](/shots/main-dark.png){.shot .dark-only}

## 1. Scan

The app scans when it opens. Press **Scan** to measure everything again, for example after a long build.

While a scan runs:

- Each row shows a spinner until its size is known.
- The progress bar shows how many caches have been measured.
- **Scan** turns into **Stop**. Stopping keeps the sizes measured so far.

Nothing is deleted during a scan.

## 2. Choose what to delete

Caches are grouped by ecosystem. Each row shows the cache name, where it lives or which command cleans it, and its size.

| Control | What it does |
| --- | --- |
| Checkbox on a row | Includes or excludes that cache |
| **All** and **None** on a group | Selects or clears the whole group |
| **Hide empty** | Hides rows that are empty or whose tool is not installed |
| Arrow next to a group name | Collapses or expands the group |

Rows marked **not installed** belong to tools the app could not find on your `PATH`. They cannot be selected.

### What is selected by default

Most caches start selected. They are cheap to rebuild and the tools recreate them on demand.

These start unselected, because rebuilding them is slow or because they hold data you may want to keep:

| Group | Unselected by default |
| --- | --- |
| Python | Hugging Face hub, PyTorch hub |
| Go | Go module cache |
| JVM | Maven repository, Bazel cache |
| .NET | NuGet packages |
| Swift / Objective-C | Xcode iOS DeviceSupport |
| Elixir / Erlang / Haskell / OCaml | Stack indices |
| Dart, Zig, Nim, Julia, R, Crystal, D | Dart / Flutter pub cache |
| Containers & VMs | Docker unused images (all), Docker stopped containers, Podman, minikube, Vagrant, Lima / Colima |
| IDEs & dev tools | Pulumi plugins, Ollama models, Claude Code scratchpads |
| Apps & system | User logs, Trash |

[What gets cleaned](/reference/catalog) lists every cache with its exact path or command.

### Check the numbers before you flush

The header shows the total you have selected. The disk bar shows the change you are about to make:

- **94% → 79%** means the disk is 94% full now and will be 79% full after the flush.
- **→ 106.1 GB after flush** is the free space you will have.

## 3. Flush

1. Press **Flush selected**.
2. Read the confirmation. It states the total size and the number of categories.
3. Press **Flush** to delete, or **Cancel** to go back.

The app then works through the selected caches one by one:

- For a folder cache, it deletes the contents of the folder and keeps the folder itself.
- For a cache with a cleanup command, it runs that command. The command is shown under the cache name.
- After each cache it measures the size again, so the list always shows what is really left.

Press **Stop** to end the flush after the current cache. Caches already deleted stay deleted.

::: warning Deleting is permanent
Flushed caches do not go to the Trash. The tools rebuild them the next time they need them, which costs download or build time.
:::

## After the flush

- The disk bar shows **Freed** with the space that was actually released.
- The activity log has one line per cache. Failures are marked **ERROR** and include the message from the tool.
- The disk analysis runs again in the background to refresh the location chart.

![Activity log after a flush, with one error](/shots/log-light.png){.shot .light-only}
![Activity log after a flush, with one error](/shots/log-dark.png){.shot .dark-only}

If a cache failed, [Troubleshooting](/guide/troubleshooting) covers the common causes.

## What is never deleted

- Named Docker volumes
- Docker images that a container uses
- Your projects, including `node_modules`, `target` and other build folders inside them
- Anything outside the paths listed in [What gets cleaned](/reference/catalog)
