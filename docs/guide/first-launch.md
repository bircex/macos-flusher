# First launch

Two things can happen the first time you open the app: macOS may block it, and macOS asks for access to a few folders. Both are expected.

## Allow the app to open

This step applies only when you installed from the DMG. The install script and a source build skip it.

MacOS Flusher is signed locally but not notarized by Apple. macOS therefore stops the first launch of a copy that was downloaded with a browser and shows a message saying the app could not be verified.

### macOS 15 Sequoia and newer

1. Open the app once and close the message.
2. Open **System Settings > Privacy & Security**.
3. Scroll down to **Security**. You will see a line saying MacOS Flusher was blocked.
4. Click **Open Anyway** and confirm with your password or Touch ID.

### macOS 13 Ventura and macOS 14 Sonoma

1. In Applications, hold Control and click **MacOS Flusher**.
2. Choose **Open**.
3. Click **Open** in the dialog.

### From Terminal

Removing the quarantine mark has the same effect on every macOS version:

```sh
xattr -dr com.apple.quarantine "/Applications/MacOS Flusher.app"
```

macOS remembers the decision. You do this once per installed copy.

## Folder access prompts

After the first scan the app measures the folders in your home directory to build the **Disk usage by location** chart. macOS protects some of those folders and asks before letting any app read them.

| Prompt | Why the app asks |
| --- | --- |
| Files in your Desktop folder | To measure the size of Desktop |
| Files in your Documents folder | To measure the size of Documents |
| Files in your Downloads folder | To measure the size of Downloads |
| Data from other apps | To measure app data stored under `~/Library` |

You can answer either way:

- **Allow**: the folder is measured and gets its own row in the chart.
- **Don't Allow**: the folder is skipped and its size is counted under **Everything else**.

The analysis waits while a prompt is on screen. If the chart header stays at "Analyzing" for a long time, look for a prompt behind other windows.

The app only reads sizes in these folders. It never changes or deletes anything in them. [Privacy and permissions](/reference/privacy) lists everything the app reads.

::: tip Change your answer later
Access to Desktop, Documents and Downloads is listed under **System Settings > Privacy & Security > Files and Folders**.
:::

## The first scan

The app starts scanning as soon as the window opens. There is nothing to configure.

1. **Scan**: every cache in the list is measured. Expect around ten seconds.
2. **Disk analysis**: folders are measured in the background for the location chart. Expect around half a minute.

Both steps take longer on disks with many small files.

You can select caches and press **Flush selected** while the disk analysis is still running.

Continue with [Scan and flush](/guide/usage).
