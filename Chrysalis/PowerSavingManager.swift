import CoreGraphics
import Foundation
import IOKit
import os.log

private let logger = Logger(subsystem: "com.rintaro-nishi.chrysalis", category: "PowerSaving")

// DisplayServices private framework
private let displayServicesHandle = dlopen(
    "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW
)

private typealias DSGetBrightness = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
private typealias DSSetBrightness = @convention(c) (CGDirectDisplayID, Float) -> Int32

private let _getBrightness: DSGetBrightness? = {
    guard let handle = displayServicesHandle, let sym = dlsym(handle, "DisplayServicesGetBrightness") else { return nil }
    return unsafeBitCast(sym, to: DSGetBrightness.self)
}()

private let _setBrightness: DSSetBrightness? = {
    guard let handle = displayServicesHandle, let sym = dlsym(handle, "DisplayServicesSetBrightness") else { return nil }
    return unsafeBitCast(sym, to: DSSetBrightness.self)
}()

struct LidCloseOptions {
    var reduceBrightness: Bool
    var disableKeyboardBacklight: Bool
    var muteAudio: Bool
    var enableDoNotDisturb: Bool
    var disableBluetooth: Bool
}

final class PowerSavingManager {
    private var savedBrightness: Float?
    private var savedKeyboardBrightness: Float?
    private var savedVolume: Int?
    private var wasMuted: Bool = false
    private var dndWasOff: Bool = false
    private var bluetoothWasOn: Bool = false

    func onLidClosed(_ options: LidCloseOptions) {
        if options.reduceBrightness {
            savedBrightness = getDisplayBrightness()
            setDisplayBrightness(0)
            logger.info("Brightness saved (\(self.savedBrightness ?? -1)) and set to 0")
        }
        if options.disableKeyboardBacklight {
            savedKeyboardBrightness = getKeyboardBrightness()
            setKeyboardBrightness(0)
            logger.info("Keyboard backlight off")
        }
        if options.muteAudio {
            let state = getAudioState()
            savedVolume = state.volume
            wasMuted = state.muted
            if !wasMuted { setMuted(true) }
            logger.info("Audio muted")
        }
        if options.enableDoNotDisturb {
            dndWasOff = !isDoNotDisturbEnabled()
            if dndWasOff { setDoNotDisturb(true) }
            logger.info("Do Not Disturb enabled")
        }
        if options.disableBluetooth {
            bluetoothWasOn = isBluetoothOn()
            if bluetoothWasOn { setBluetooth(false) }
            logger.info("Bluetooth disabled")
        }
    }

    func onLidOpened(_ options: LidCloseOptions) {
        if options.reduceBrightness, let brightness = savedBrightness {
            setDisplayBrightness(brightness)
            logger.info("Brightness restored to \(brightness)")
            savedBrightness = nil
        }
        if options.disableKeyboardBacklight, let brightness = savedKeyboardBrightness {
            setKeyboardBrightness(brightness)
            logger.info("Keyboard backlight restored")
            savedKeyboardBrightness = nil
        }
        if options.muteAudio {
            if !wasMuted {
                setMuted(false)
            }
            if let volume = savedVolume {
                setVolume(volume)
                savedVolume = nil
            }
            logger.info("Audio restored")
        }
        if options.enableDoNotDisturb, dndWasOff {
            setDoNotDisturb(false)
            logger.info("Do Not Disturb disabled")
            dndWasOff = false
        }
        if options.disableBluetooth, bluetoothWasOn {
            setBluetooth(true)
            logger.info("Bluetooth re-enabled")
            bluetoothWasOn = false
        }
    }

    // MARK: - Display Brightness

    private func getDisplayBrightness() -> Float {
        var brightness: Float = 0.5
        if let getBrightness = _getBrightness {
            _ = getBrightness(CGMainDisplayID(), &brightness)
        }
        return brightness
    }

    private func setDisplayBrightness(_ level: Float) {
        if let setBrightness = _setBrightness {
            _ = setBrightness(CGMainDisplayID(), level)
        }
    }

    // MARK: - Keyboard Backlight

    private func getKeyboardBrightness() -> Float {
        var brightness: Float = 0
        var iterator: io_iterator_t = 0
        let matching = IOServiceNameMatching("AppleHIDKeyboardEventDriverV2")
        IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        if service != 0 {
            if let prop = IORegistryEntryCreateCFProperty(service, "KeyboardBacklightBrightness" as CFString, kCFAllocatorDefault, 0) {
                brightness = prop.takeRetainedValue() as? Float ?? 0
            }
            IOObjectRelease(service)
        }
        return brightness
    }

    private func setKeyboardBrightness(_ level: Float) {
        var iterator: io_iterator_t = 0
        let matching = IOServiceNameMatching("AppleHIDKeyboardEventDriverV2")
        IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            IORegistryEntrySetCFProperty(service, "KeyboardBacklightBrightness" as CFString, level as CFNumber)
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }

    // MARK: - Audio

    private struct AudioState {
        let volume: Int
        let muted: Bool
    }

    private func getAudioState() -> AudioState {
        let script = NSAppleScript(source: """
            set vol to output volume of (get volume settings)
            set isMuted to output muted of (get volume settings)
            return (vol as text) & "," & (isMuted as text)
            """)
        var error: NSDictionary?
        if let result = script?.executeAndReturnError(&error).stringValue {
            let parts = result.split(separator: ",")
            let volume = Int(parts.first ?? "50") ?? 50
            let muted = parts.last == "true"
            return AudioState(volume: volume, muted: muted)
        }
        return AudioState(volume: 50, muted: false)
    }

    private func setMuted(_ muted: Bool) {
        let source = muted
            ? "set volume with output muted"
            : "set volume without output muted"
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error { logger.error("setMuted failed: \(error)") }
    }

    private func setVolume(_ volume: Int) {
        var error: NSDictionary?
        NSAppleScript(source: "set volume output volume \(volume)")?.executeAndReturnError(&error)
        if let error { logger.error("setVolume failed: \(error)") }
    }

    // MARK: - Do Not Disturb

    private func isDoNotDisturbEnabled() -> Bool {
        let script = NSAppleScript(source: """
            do shell script "defaults read com.apple.controlcenter 'NSStatusItem Visible FocusModes' 2>/dev/null || echo 0"
            """)
        var error: NSDictionary?
        // Approximation - DND state is hard to read reliably
        let result = script?.executeAndReturnError(&error).stringValue
        return result == "1"
    }

    private func setDoNotDisturb(_ enabled: Bool) {
        let script: String
        if enabled {
            script = """
                do shell script "defaults write com.apple.ncprefs dnd_prefs -data $(echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>dndDisplayLock</key><false/><key>dndDisplaySleep</key><false/><key>dndMirrored</key><false/><key>userPref</key><dict><key>enabled</key><true/></dict></dict></plist>' | plutil -convert binary1 -o - - | xxd -p | tr -d '\\n')"
                do shell script "killall NotificationCenter 2>/dev/null; killall usernoted 2>/dev/null"
                """
        } else {
            script = """
                do shell script "defaults write com.apple.ncprefs dnd_prefs -data $(echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>dndDisplayLock</key><false/><key>dndDisplaySleep</key><false/><key>dndMirrored</key><false/><key>userPref</key><dict><key>enabled</key><false/></dict></dict></plist>' | plutil -convert binary1 -o - - | xxd -p | tr -d '\\n')"
                do shell script "killall NotificationCenter 2>/dev/null; killall usernoted 2>/dev/null"
                """
        }
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }

    // MARK: - Bluetooth

    private func isBluetoothOn() -> Bool {
        let script = NSAppleScript(source: """
            do shell script "defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState 2>/dev/null || echo 1"
            """)
        var error: NSDictionary?
        return script?.executeAndReturnError(&error).stringValue == "1"
    }

    private func setBluetooth(_ on: Bool) {
        // Use blueutil if available, otherwise fall back to defaults + kill
        let script = NSAppleScript(source: """
            do shell script "if command -v blueutil >/dev/null; then blueutil --power \(on ? "1" : "0"); else defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int \(on ? 1 : 0); killall -HUP bluetoothd 2>/dev/null; fi"
            """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
    }
}
