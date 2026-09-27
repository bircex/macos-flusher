# Read the dashboard

The window has four areas: the overview at the top, the cache list on the left, two charts on the right and the activity log at the bottom.

The same three colors mean the same thing everywhere.

| Color | Meaning |
| --- | --- |
| Blue | Other data. Everything on the disk that is not a cache the app knows. |
| Green | Unselected caches. Found, but not part of the next flush. |
| Orange | Selected caches. These are deleted when you flush. |
| Gray | Free space. |

## Overview

![Overview with the disk donut, four tiles and the disk bar](/shots/overview-light.png){.shot .light-only}
![Overview with the disk donut, four tiles and the disk bar](/shots/overview-dark.png){.shot .dark-only}

### Donut and tiles

The donut splits the whole disk into the four parts above. The number in the middle is how full the disk is.

Each tile repeats one part of the donut with its size and its share of the disk. Changing the selection moves space between **Unselected caches** and **Selected caches** right away.

### Disk bar

The disk bar answers one question: what does the flush change?

- The filled part is what stays on the disk after the flush.
- The orange end is what the flush removes.
- The label reads **now → after**, for example **94% → 79%**.

The bar turns red when the disk is more than 90% full.

After a flush, **Freed** shows how much space was released.

### Progress bar

The second bar appears during a scan or a flush and shows the share of caches already handled.

## Disk usage by location

![Charts panel with disk usage by location and caches by category](/shots/charts-light.png){.shot .narrow .light-only}
![Charts panel with disk usage by location and caches by category](/shots/charts-dark.png){.shot .narrow .dark-only}

This chart shows where the used space is. Rows are sorted from largest to smallest and each bar is split into other data, unselected caches and selected caches.

| Row | What it covers |
| --- | --- |
| Applications | `/Applications` and `~/Applications` |
| Docker | Everything Docker Desktop stores, split into the two rows below |
| Disk image | The virtual disk that holds images, containers, volumes and build cache |
| Other Docker data | Settings, logs and other Docker Desktop files |
| Library | `~/Library` without the Docker folders |
| System files | `/System`, `/Library`, `/private`, `/usr` and `/opt` |
| `~/Name` | One row for every folder in your home directory that holds 1 GB or more |
| Other home items | Home folders and files smaller than 1 GB, added together |
| Everything else | Used space the app could not attribute to a row |

The rows add up to the used space shown in the header of the chart.

### What "Everything else" contains

- Folders you did not allow the app to read
- Folders only the system can read, such as Mail and Messages data
- macOS recovery and startup volumes, and swap space
- Local snapshots that macOS keeps for a while after files are deleted

### Docker caches sit inside the disk image

Docker build cache, images, volumes and containers live inside the Docker disk image, so their sizes appear as the green and orange parts of the **Disk image** row.

Docker Desktop does not always return freed space to macOS right away. The row can stay larger than expected for a while after a flush.

## Caches by category

This chart compares the cache groups from the list. Use it to see which ecosystem takes the most space and how much of it is selected.

A group that is mostly green holds caches that are unselected by default. Go is a common example, because the module cache is slow to download again.

## Activity log

The log records every step with a time and a level.

| Level | Used for |
| --- | --- |
| INFO | Scan started and finished, each flushed cache, freed space, disk analysis finished |
| ERROR | A cache that could not be flushed, with the message from the tool |

The counters on the right show how many lines of each level are in the log. The log keeps the most recent 300 lines, and text in it can be selected and copied.

## Hover for details

Hold the pointer over a tile or a bar to see the exact sizes behind it.
