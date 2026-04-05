import Combine
import ServiceManagement
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isPreventingSleep: Bool = false

    @Published var launchAtLogin: Bool {
        didSet {
            guard !isUpdatingState else { return }
            isUpdatingState = true
            defer { isUpdatingState = false }
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = !launchAtLogin
            }
        }
    }

    // Power Saving
    @Published var reduceBrightness: Bool {
        didSet { UserDefaults.standard.set(reduceBrightness, forKey: "reduceBrightness") }
    }
    @Published var disableKeyboardBacklight: Bool {
        didSet { UserDefaults.standard.set(disableKeyboardBacklight, forKey: "disableKeyboardBacklight") }
    }

    // Lid Close Actions
    @Published var muteAudio: Bool {
        didSet { UserDefaults.standard.set(muteAudio, forKey: "muteAudio") }
    }
    @Published var enableDoNotDisturb: Bool {
        didSet { UserDefaults.standard.set(enableDoNotDisturb, forKey: "enableDoNotDisturb") }
    }
    @Published var disableBluetooth: Bool {
        didSet { UserDefaults.standard.set(disableBluetooth, forKey: "disableBluetooth") }
    }

    let shortcutManager: ShortcutManager

    private let sleepManager = SleepManager()
    private let lidMonitor = LidMonitor()
    private let powerSavingManager = PowerSavingManager()
    private var isUpdatingState = false

    var lidCloseOptions: LidCloseOptions {
        LidCloseOptions(
            reduceBrightness: reduceBrightness,
            disableKeyboardBacklight: disableKeyboardBacklight,
            muteAudio: muteAudio,
            enableDoNotDisturb: enableDoNotDisturb,
            disableBluetooth: disableBluetooth
        )
    }

    init() {
        // Always start with sleep prevention OFF
        _isPreventingSleep = Published(initialValue: false)
        _launchAtLogin = Published(initialValue: SMAppService.mainApp.status == .enabled)

        _reduceBrightness = Published(initialValue: UserDefaults.standard.object(forKey: "reduceBrightness") as? Bool ?? true)
        _disableKeyboardBacklight = Published(initialValue: UserDefaults.standard.object(forKey: "disableKeyboardBacklight") as? Bool ?? true)
        _muteAudio = Published(initialValue: UserDefaults.standard.object(forKey: "muteAudio") as? Bool ?? true)
        _enableDoNotDisturb = Published(initialValue: UserDefaults.standard.object(forKey: "enableDoNotDisturb") as? Bool ?? true)
        _disableBluetooth = Published(initialValue: UserDefaults.standard.object(forKey: "disableBluetooth") as? Bool ?? true)

        shortcutManager = ShortcutManager()

        lidMonitor.onLidClosed = { [weak self] in
            guard let self else { return }
            self.powerSavingManager.onLidClosed(self.lidCloseOptions)
        }
        lidMonitor.onLidOpened = { [weak self] in
            guard let self else { return }
            self.powerSavingManager.onLidOpened(self.lidCloseOptions)
        }

        shortcutManager.onToggle = { [weak self] in
            self?.toggle()
        }
        shortcutManager.startMonitoring()
    }

    /// Toggle sleep prevention with proper error handling and rollback
    func setSleepPrevention(_ enabled: Bool) {
        guard !isUpdatingState else { return }
        isUpdatingState = true
        defer { isUpdatingState = false }

        if enabled {
            if sleepManager.enable() {
                isPreventingSleep = true
                UserDefaults.standard.set(true, forKey: "isPreventingSleep")
                lidMonitor.startMonitoring()
            }
            // If failed (user cancelled), don't change state
        } else {
            if sleepManager.disable() {
                isPreventingSleep = false
                UserDefaults.standard.set(false, forKey: "isPreventingSleep")
                lidMonitor.stopMonitoring()
            }
            // If failed, keep state as ON
        }
    }

    func toggle() {
        setSleepPrevention(!isPreventingSleep)
    }

    func cleanup() {
        if sleepManager.isEnabled {
            sleepManager.disable()
        }
        lidMonitor.stopMonitoring()
    }
}
