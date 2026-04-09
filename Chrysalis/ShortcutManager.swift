import Cocoa
import Combine
import SwiftUI

struct KeyCombo: Codable, Equatable, Sendable {
    let keyCode: UInt16
    let modifiers: UInt

    static let `default` = KeyCombo(
        keyCode: 0x08, // C
        modifiers: NSEvent.ModifierFlags([.control, .option]).rawValue
    )

    var displayString: String {
        var result = ""
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.shift) { result += "⇧" }
        if flags.contains(.command) { result += "⌘" }
        if let name = Self.keyName(for: keyCode) {
            result += name
        }
        return result
    }

    var keyEquivalent: KeyEquivalent? {
        guard let name = Self.keyName(for: keyCode) else { return nil }
        // Only single-character keys can map to KeyEquivalent
        guard name.count == 1, let char = name.lowercased().first else { return nil }
        return KeyEquivalent(char)
    }

    var eventModifiers: EventModifiers {
        var result: EventModifiers = []
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.control) { result.insert(.control) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.shift) { result.insert(.shift) }
        if flags.contains(.command) { result.insert(.command) }
        return result
    }

    private static func keyName(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 0x00: "A"  case 0x01: "S"  case 0x02: "D"  case 0x03: "F"
        case 0x04: "H"  case 0x05: "G"  case 0x06: "Z"  case 0x07: "X"
        case 0x08: "C"  case 0x09: "V"  case 0x0B: "B"  case 0x0C: "Q"
        case 0x0D: "W"  case 0x0E: "E"  case 0x0F: "R"  case 0x10: "Y"
        case 0x11: "T"  case 0x12: "1"  case 0x13: "2"  case 0x14: "3"
        case 0x15: "4"  case 0x16: "6"  case 0x17: "5"  case 0x18: "="
        case 0x19: "9"  case 0x1A: "7"  case 0x1B: "-"  case 0x1C: "8"
        case 0x1D: "0"  case 0x1E: "]"  case 0x1F: "O"  case 0x20: "U"
        case 0x21: "["  case 0x22: "I"  case 0x23: "P"  case 0x25: "L"
        case 0x26: "J"  case 0x28: "K"  case 0x2C: "/"  case 0x2D: "N"
        case 0x2E: "M"  case 0x24: "↩"  case 0x30: "⇥"  case 0x31: "Space"
        case 0x33: "⌫"  case 0x35: "⎋"
        case 0x7A: "F1"  case 0x78: "F2"  case 0x63: "F3"  case 0x76: "F4"
        case 0x60: "F5"  case 0x61: "F6"  case 0x62: "F7"  case 0x64: "F8"
        case 0x65: "F9"  case 0x6D: "F10" case 0x67: "F11" case 0x6F: "F12"
        default: nil
        }
    }
}

@MainActor
final class ShortcutManager: ObservableObject {
    @Published var currentShortcut: KeyCombo? {
        didSet {
            save()
            if !isRecording { startMonitoring() }
        }
    }
    @Published var isRecording = false
    @Published var recordingModifiers: String = ""

    var onToggle: (@MainActor () -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var recordingMonitor: Any?
    private var flagsMonitor: Any?

    init() {
        if let data = UserDefaults.standard.data(forKey: "globalShortcut"),
           let shortcut = try? JSONDecoder().decode(KeyCombo.self, from: data) {
            _currentShortcut = Published(initialValue: shortcut)
        } else {
            _currentShortcut = Published(initialValue: .default)
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        stopMonitoring()
        guard currentShortcut != nil else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                self?.handleKeyEvent(event)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let shortcut = self.currentShortcut else { return event }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            if event.keyCode == shortcut.keyCode && flags == shortcut.modifiers {
                self.onToggle?()
                return nil
            }
            return event
        }
    }

    func stopMonitoring() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard let shortcut = currentShortcut else { return }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        if event.keyCode == shortcut.keyCode && flags == shortcut.modifiers {
            onToggle?()
        }
    }

    // MARK: - Recording

    func startRecording() {
        stopMonitoring()
        isRecording = true
        recordingModifiers = ""

        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            Task { @MainActor in
                self?.recordingModifiers = Self.modifiersString(flags)
            }
            return event
        }

        recordingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 0x35 {
                Task { @MainActor in self?.stopRecording() }
                return nil
            }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let required: NSEvent.ModifierFlags = [.control, .option, .command]
            guard !flags.intersection(required).isEmpty else { return nil }

            let combo = KeyCombo(keyCode: event.keyCode, modifiers: flags.rawValue)
            Task { @MainActor in
                self?.currentShortcut = combo
                self?.stopRecording()
            }
            return nil
        }
    }

    func stopRecording() {
        isRecording = false
        recordingModifiers = ""
        if let m = recordingMonitor { NSEvent.removeMonitor(m); recordingMonitor = nil }
        if let m = flagsMonitor { NSEvent.removeMonitor(m); flagsMonitor = nil }
        startMonitoring()
    }

    private static func modifiersString(_ flags: NSEvent.ModifierFlags) -> String {
        var result = ""
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.shift) { result += "⇧" }
        if flags.contains(.command) { result += "⌘" }
        return result
    }

    // MARK: - Persistence

    private func save() {
        if let shortcut = currentShortcut, let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: "globalShortcut")
        } else {
            UserDefaults.standard.removeObject(forKey: "globalShortcut")
        }
    }
}
