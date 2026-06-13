# StayAwakeBar

Tiny macOS menu bar app that toggles `caffeinate -di`.

## What it does

- Adds a cup icon to the macOS menu bar
- Turns sleep prevention on and off with one click
- Automatically enables stay-awake mode when the app launches
- Can install itself as a login item via `launchd`

## Requirements

- macOS 13 or newer
- Xcode command line tools or Xcode with `swiftc`

## Build

```bash
./stayawakebar/build.sh
```

This creates:

```text
./dist/StayAwakeBar.app
```

## Install

```bash
./install.sh
```

That will:

- build the app
- copy it to `~/Applications/StayAwakeBar.app`
- install a `LaunchAgent`
- start the app immediately

## Manual run

```bash
open ./dist/StayAwakeBar.app
```

## Source

- `stayawakebar/StayAwakeBar.swift`: menu bar app source
- `stayawakebar/build.sh`: local build script
- `install.sh`: install and enable launch-at-login
