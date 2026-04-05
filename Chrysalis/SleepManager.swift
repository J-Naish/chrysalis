import Carbon
import Foundation
import os.log

private let logger = Logger(subsystem: "com.rintaro-nishi.chrysalis", category: "SleepManager")

final class SleepManager {
    private(set) var isEnabled = false

    @discardableResult
    func enable() -> Bool {
        guard !isEnabled else { return true }
        guard runPmset(flag: "1") else { return false }
        isEnabled = true
        logger.info("Sleep disabled")
        return true
    }

    @discardableResult
    func disable() -> Bool {
        guard isEnabled else { return true }
        guard runPmset(flag: "0") else { return false }
        isEnabled = false
        logger.info("Sleep re-enabled")
        return true
    }

    private func runPmset(flag: String) -> Bool {
        let source = """
            do shell script "pmset disablesleep \(flag)" \
                with administrator privileges \
                with prompt "Chrysalis needs administrator access to control sleep settings."
            """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)

        if let error {
            logger.error("pmset failed: \(error)")
            return false
        }
        return true
    }
}
