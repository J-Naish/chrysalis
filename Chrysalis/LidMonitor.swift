import Foundation
import IOKit

final class LidMonitor {
    private var timer: Timer?
    private var wasLidClosed = false

    var onLidClosed: (() -> Void)?
    var onLidOpened: (() -> Void)?

    func startMonitoring() {
        stopMonitoring()
        wasLidClosed = isLidClosed()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.check()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func check() {
        let closed = isLidClosed()
        if closed != wasLidClosed {
            wasLidClosed = closed
            if closed { onLidClosed?() } else { onLidOpened?() }
        }
    }

    private func isLidClosed() -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }

        if let prop = IORegistryEntryCreateCFProperty(service, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0) {
            return prop.takeRetainedValue() as? Bool ?? false
        }
        return false
    }
}
