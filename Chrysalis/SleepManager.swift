import Carbon
import Foundation
import os.log

private let logger = Logger(subsystem: "com.j-naish.chrysalis", category: "SleepManager")

final class SleepManager {
    var isEnabled = false

    /// Check if pmset disablesleep is currently active at the system level
    func isSystemSleepDisabled() -> Bool {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        // Look for "disablesleep		1" in pmset output
        return output.contains("disablesleep") && output.range(of: #"disablesleep\s+1"#, options: .regularExpression) != nil
    }

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
