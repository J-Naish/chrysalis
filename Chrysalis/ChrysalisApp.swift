import SwiftUI

@main
struct ChrysalisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            sleepToggle
            Divider()
            Button("Settings...") {
                SettingsWindowManager.shared.open(appState: appState)
            }
            .keyboardShortcut(",")
            Divider()
            Button("Quit Chrysalis") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(nsImage: menuBarIcon(active: appState.isPreventingSleep))
        }
    }

    @ViewBuilder
    private var sleepToggle: some View {
        let binding = Binding(
            get: { appState.isPreventingSleep },
            set: { appState.setSleepPrevention($0) }
        )
        if let key = appState.shortcutManager.currentShortcut?.keyEquivalent {
            Toggle("Sleep Prevention", isOn: binding)
                .keyboardShortcut(key, modifiers: appState.shortcutManager.currentShortcut?.eventModifiers ?? [])
        } else {
            Toggle("Sleep Prevention", isOn: binding)
        }
    }
}

private func menuBarIcon(active: Bool) -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
    let image = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "Chrysalis")!
        .withSymbolConfiguration(config)!

    let size = image.size
    let result = NSImage(size: size, flipped: false) { rect in
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: active ? 1.0 : 0.35)
        return true
    }
    result.isTemplate = true
    return result
}

final class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Best-effort cleanup: reset pmset disablesleep
        let source = """
            do shell script "pmset disablesleep 0" \
                with administrator privileges \
                with prompt "Chrysalis needs to restore sleep settings before quitting."
            """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }
}
