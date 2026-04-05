import SwiftUI
import ApplicationServices

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var shortcutManager: ShortcutManager

    var body: some View {
        Form {
            Section("Keyboard Shortcut") {
                HStack {
                    if shortcutManager.isRecording {
                    if shortcutManager.recordingModifiers.isEmpty {
                        Text("Press a key combination...")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(shortcutManager.recordingModifiers + "...")
                            .fontDesign(.monospaced)
                    }
                    } else {
                        Text(shortcutManager.currentShortcut?.displayString ?? "Not set")
                            .fontDesign(.monospaced)
                    }

                    Spacer()

                    if shortcutManager.isRecording {
                        Button("Cancel") {
                            shortcutManager.stopRecording()
                        }
                    } else {
                        Button("Record") {
                            shortcutManager.startRecording()
                        }
                        Button("Reset") {
                            shortcutManager.currentShortcut = .default
                        }
                    }
                }

                if !AXIsProcessTrusted() {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("Accessibility access is required for global shortcuts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Grant Access") {
                            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
                            _ = AXIsProcessTrustedWithOptions(options)
                        }
                        .font(.caption)
                    }
                }
            }

            Section("On Lid Close") {
                Toggle("Reduce Display Brightness", isOn: $appState.reduceBrightness)
                Toggle("Turn Off Keyboard Backlight", isOn: $appState.disableKeyboardBacklight)
                Toggle("Mute Audio", isOn: $appState.muteAudio)
                Toggle("Enable Do Not Disturb", isOn: $appState.enableDoNotDisturb)
                Toggle("Disable Bluetooth", isOn: $appState.disableBluetooth)
            }

            Section("General") {
                Toggle("Launch at Login", isOn: $appState.launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }
}

@MainActor
final class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?

    private init() {}

    func open(appState: AppState) {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView(appState: appState, shortcutManager: appState.shortcutManager)
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Chrysalis Settings"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
