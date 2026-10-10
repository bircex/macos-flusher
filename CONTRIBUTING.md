# Contributing

Thanks for looking at the code. A few things that make a pull request easy to merge.

## Build and test

Needs Xcode Command Line Tools, no full Xcode required.

```
make test       # swift test, with Swift Testing's framework paths added
make run        # builds and opens the app without installing it
```

Keep `make test` green before opening a pull request.

## Adding a built-in target

A target is one entry in `Sources/MacOSFlusher/Targets.swift`: an id that never changes once shipped, a name, the folder(s) it removes or the command it runs, and a risk (`rebuilds`, `redownload`, or `data`).

Before opening a pull request for a new target, have two things ready, since they go in the description:

1. A primary source: the tool's own documentation, or its own cache-clearing command/flag.
2. A live observation: the folder grows with use, the app works the same after it is removed, and the tool rebuilds or redownloads it without Full Disk Access.

Update the website's "What it cleans" section (`docs/index.html`) in the same pull request; the group and target counts there are checked by a test.

## Translations

The app's strings live in `Sources/MacOSFlusher/Resources/<code>.lproj/Localizable.strings`, one file per language, the English sentence as the key. `make test` checks that every language has the same keys and placeholders as English. Corrections to a translation, including a wrong word or a wrong direction for a right-to-left language, are welcome as an issue or a pull request.

## Style

Short, plain commit messages and pull request descriptions. No filler, no restating the diff in prose. Follow the structure already in the file you are editing rather than introducing a new pattern.

## Reporting a problem that is not a security issue

Open an [issue](https://github.com/bircex/macos-flusher/issues). For a security issue, see [SECURITY.md](SECURITY.md) instead.
