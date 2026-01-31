import Foundation

public final class ProcessKiller: @unchecked Sendable {
    public init() {}
    
    public func killProcess(pid: Int32) async throws {
        // Try to kill without sudo first (for user's own processes)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/kill")
        process.arguments = ["-9", "\(pid)"]
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            // If failed, might need sudo - try with osascript
            try await killProcessWithPrivileges(pid: pid)
        }
    }
    
    private func killProcessWithPrivileges(pid: Int32) async throws {
        let script = """
        do shell script "kill -9 \(pid)" with administrator privileges
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProcessKiller", code: Int(process.terminationStatus),
                         userInfo: [NSLocalizedDescriptionKey: "Failed to kill process: \(error)"])
        }
    }
    
    public func isSystemCritical(port: PortInfo) -> Bool {
        // Never allow killing these critical processes
        let blockedProcesses = ["kernel_task", "launchd"]
        if blockedProcesses.contains(port.processName) {
            return true
        }
        
        // Check for other system-critical indicators
        if port.uid == 0 {  // Root processes
            return true
        }
        
        if port.pid < 100 {  // Early boot processes
            return true
        }
        
        // Additional critical process names
        let criticalProcesses = [
            "WindowServer",
            "loginwindow",
            "SystemUIServer",
            "Dock",
            "Finder",
            "coreaudiod",
            "bluetoothd",
            "networkd",
            "configd",
            "mDNSResponder",
            "notifyd",
            "diskarbitrationd"
        ]
        
        return criticalProcesses.contains(port.processName)
    }
    
    public func isCompletelyBlocked(port: PortInfo) -> Bool {
        // These should NEVER be killed, no confirmation dialog even
        let blockedProcesses = ["kernel_task", "launchd"]
        return blockedProcesses.contains(port.processName) || port.pid == 1
    }
}
