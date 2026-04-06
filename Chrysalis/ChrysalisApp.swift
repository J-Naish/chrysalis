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
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: true) { _ in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

        let ellipseRect = CGRect(x: 4, y: 2, width: 10, height: 14)

        // Clip to ellipse so cut bands don't extend beyond
        ctx.saveGState()
        ctx.addEllipse(in: ellipseRect)
        ctx.clip()

        // Compound path: ellipse + cut bands (even-odd removes the bands)
        let path = CGMutablePath()
        path.addEllipse(in: ellipseRect)

        // Upper cut band
        path.move(to: CGPoint(x: 0, y: 6.8))
        path.addQuadCurve(to: CGPoint(x: 18, y: 6.8), control: CGPoint(x: 9, y: 5))
        path.addLine(to: CGPoint(x: 18, y: 7.8))
        path.addQuadCurve(to: CGPoint(x: 0, y: 7.8), control: CGPoint(x: 9, y: 6))
        path.closeSubpath()

        // Lower cut band
        path.move(to: CGPoint(x: 0, y: 10.8))
        path.addQuadCurve(to: CGPoint(x: 18, y: 10.8), control: CGPoint(x: 9, y: 9))
        path.addLine(to: CGPoint(x: 18, y: 11.8))
        path.addQuadCurve(to: CGPoint(x: 0, y: 11.8), control: CGPoint(x: 9, y: 10))
        path.closeSubpath()

        ctx.addPath(path)
        ctx.setFillColor(CGColor(gray: 0, alpha: active ? 1.0 : 0.35))
        ctx.fillPath(using: .evenOdd)

        ctx.restoreGState()
        return true
    }
    image.isTemplate = true
    return image
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
