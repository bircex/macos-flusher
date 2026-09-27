---
layout: home

hero:
  name: MacOS Flusher
  text: Get your disk space back
  tagline: A small native macOS app that finds and deletes developer caches, and shows what is filling the disk.
  image:
    src: /icon.png
    alt: MacOS Flusher icon
  actions:
    - theme: brand
      text: Download for Mac
      link: https://github.com/bircex/macos-flusher/releases/latest/download/MacOS-Flusher.dmg
    - theme: alt
      text: Get started
      link: /guide/install
    - theme: alt
      text: View on GitHub
      link: https://github.com/bircex/macos-flusher

features:
  - title: Every stack in one list
    details: 88 cache locations in 14 groups. npm, pip, Go, Cargo, Gradle, Xcode, Docker, Homebrew, JetBrains, VS Code and many more.
  - title: Measure first, delete second
    details: Every cache is measured before anything is removed. The disk bar shows how full the disk is now and how full it will be after the flush.
  - title: See what fills the disk
    details: Charts break the disk down by location and by cache category, with the Docker disk image grouped under Docker.
  - title: Safe defaults
    details: Caches that are slow to rebuild or hold user data start unselected. Named Docker volumes and project files are never touched.
  - title: Uses each tool's own cleanup
    details: Where a tool has a cleanup command, the app runs it. go clean, npm cache clean, docker prune and brew cleanup do the deleting.
  - title: Native and private
    details: Written in SwiftUI as a universal binary for Apple Silicon and Intel. The app makes no network requests and collects nothing.
---

<div class="shot-frame">

![MacOS Flusher main window showing the disk overview, the cache list, two charts and the activity log](/shots/main-light.png){.light-only}
![MacOS Flusher main window showing the disk overview, the cache list, two charts and the activity log](/shots/main-dark.png){.dark-only}

</div>
