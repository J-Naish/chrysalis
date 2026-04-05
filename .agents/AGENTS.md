# Chrysalis

macOS menu bar app that prevents system sleep when the MacBook lid is closed, while keeping the machine running in the background.

## License & Distribution

- License: MIT License (Copyright 2026 J-Naish)
- Distribution: GitHub Public Repository + Releases (.dmg)
- Code signing / Notarization: None (users launch via right-click → Open on first run)
- Pricing: Free (no monetization)

## System Requirements

- macOS 13 Ventura or later
- Apple Silicon and Intel both supported

## Tech Stack

- Swift / SwiftUI
- MenuBarExtra for menu bar UI
- IOKit Power Assertion for sleep prevention
- ServiceManagement for login launch

## v1.0 — Minimum Viable Product

### Functional Requirements

#### 1. Sleep Prevention
- Prevent system sleep while the lid is closed
- Implemented via IOKit Power Assertion (`IOPMAssertionCreateWithName`)
- Can be toggled ON / OFF from the menu bar

#### 2. Menu Bar UI
- App does not appear in the Dock (`LSUIElement = YES`)
- Menu bar icon reflects current state (ON / OFF) visually
- Implemented with SwiftUI `MenuBarExtra`
- Menu provides the following actions:
  - Toggle sleep prevention ON / OFF
  - Settings
  - Quit the app

#### 3. Global Keyboard Shortcut
- Toggle sleep prevention ON / OFF via a global keyboard shortcut
- User can customize the shortcut in Settings
- Default shortcut assigned out of the box

#### 4. Launch Behavior
- Automatically launches at login via `ServiceManagement` (`SMAppService`)
- Restores the previous ON / OFF state on launch

### Non-Functional Requirements

- Built with Swift and SwiftUI
- Project structure based on Swift Package Manager (SPM)
- No server-side components, no external network communication
- Minimal third-party dependencies

## Future Candidates (v2.0+)

The following features are out of scope for v1.0 but may be considered in future releases.

### Power Saving
- Reduce internal display brightness when lid closes; restore when opened
- Automatically switch to Low Power Mode when lid closes
- Turn off keyboard backlight when lid closes

### Monitoring
- Display current power consumption in the menu bar
- Detailed battery and power status view

### Suggestions & Notifications
- Detect apps with high CPU usage and notify the user
- Suggest turning off Bluetooth / Wi-Fi to save power

### External Display Support
- External monitor brightness control via DDC/CI

## Build & Run

- Open `Chrysalis.xcodeproj` in Xcode
- Build target: Chrysalis
- Supports Apple Silicon and Intel

## Development Notes

- Development assisted by Claude Code
- Xcode used for building and debugging; code editing handled in VS Code + Claude Code
- v1.0 prioritizes simplicity; features will be added incrementally based on user feedback
