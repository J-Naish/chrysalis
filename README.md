# Chrysalis

<p align="center">
  <img src="Chrysalis/Assets.xcassets/AppIcon.appiconset/icon_1024.png" width="128" height="128" alt="Chrysalis app icon">
</p>

<p align="center">
  <strong>Keep your Mac awake with the lid closed.</strong>
</p>

<p align="center">
  <a href="https://github.com/J-Naish/chrysalis/releases/latest">Download</a> · macOS 13+ · Apple Silicon & Intel
</p>

---

Chrysalis is a lightweight macOS menu bar app that prevents your Mac from sleeping when you close the lid.

Built for developers who use [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with [Remote Control](https://docs.anthropic.com/en/docs/claude-code/remote-control) — close your MacBook lid, pick up your phone, and keep coding with Claude from anywhere. Without Chrysalis, closing the lid puts your Mac to sleep the Claude Code session. With Chrysalis, it just keeps running.

## Features

- **Sleep Prevention** — Toggle system sleep on/off from the menu bar using `pmset disablesleep`
- **Global Keyboard Shortcut** — Quick toggle with a customizable hotkey (default: `⌃⌥E`)
- **Lid Close Actions** — Automatically perform actions when the lid closes:
  - Reduce display brightness
  - Turn off keyboard backlight
  - Mute audio
  - Enable Do Not Disturb
  - Disable Bluetooth
- **Launch at Login** — Optionally start Chrysalis when you log in
- **Lives in the Menu Bar** — No Dock icon, stays out of your way

## Installation

### Download

1. Download the latest `.dmg` from [Releases](https://github.com/J-Naish/chrysalis/releases/latest)
2. Drag **Chrysalis.app** to your Applications folder
3. On first launch, right-click the app and select **Open** (required for unsigned apps)
4. Grant **Accessibility** access when prompted (needed for the global keyboard shortcut)

### Build from Source

```bash
git clone https://github.com/J-Naish/chrysalis.git
cd Chrysalis
open Chrysalis.xcodeproj
```

Build and run the `Chrysalis` target in Xcode.

## Usage

1. Click the leaf icon in the menu bar
2. Toggle **Sleep Prevention** to keep your Mac awake
3. Close the lid — your Mac will stay running
4. Open **Settings** to customize the keyboard shortcut and lid close behaviors

> **Note:** Chrysalis requires administrator privileges to control sleep settings. You'll be prompted for your password when toggling sleep prevention.

## How It Works

Chrysalis uses `pmset disablesleep` (via AppleScript with admin privileges) to prevent the system from sleeping. When sleep prevention is active, it monitors the lid state through IOKit's `AppleClamshellState` and applies your configured power-saving actions automatically.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac

## License

[MIT](LICENSE) © J-Naish
