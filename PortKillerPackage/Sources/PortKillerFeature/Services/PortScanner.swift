import Foundation

@MainActor
public class PortScanner: ObservableObject {
    @Published public var ports: [PortInfo] = []
    @Published public var isScanning: Bool = false
    @Published public var lastError: String?
    @Published public var debugInfo: String = ""
    
    public init() {}
    
    public func scan() async {
        isScanning = true
        lastError = nil
        debugInfo = "Starting scan...\n"
        
        do {
            let output = try await executeLsofDirect()
            debugInfo += "LSOF output length: \(output.count) chars\n"
            debugInfo += "First 500 chars:\n\(String(output.prefix(500)))\n\n"
            
            let parsedPorts = parseLsofOutput(output)
            debugInfo += "Parsed \(parsedPorts.count) ports\n"
            
            if parsedPorts.isEmpty {
                debugInfo += "⚠️ No ports were parsed from lsof output!\n"
            } else {
                debugInfo += "Ports found:\n"
                for (i, port) in parsedPorts.prefix(5).enumerated() {
                    debugInfo += "\(i+1). Port \(port.port) - \(port.processName) (PID: \(port.pid))\n"
                }
            }
            
            self.ports = parsedPorts
            self.isScanning = false
        } catch {
            debugInfo += "❌ ERROR: \(error.localizedDescription)\n"
            self.lastError = "Error: \(error.localizedDescription)"
            self.isScanning = false
        }
    }
    
    private func executeLsofDirect() async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        
        // lsof returns exit code 1 if no ports found, which is fine
        if process.terminationStatus != 0 && process.terminationStatus != 1 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PortScanner", code: Int(process.terminationStatus), 
                         userInfo: [NSLocalizedDescriptionKey: "lsof failed: \(errorMessage)"])
        }
        
        return output
    }
    
    private func parseLsofOutput(_ output: String) -> [PortInfo] {
        let lines = output.components(separatedBy: .newlines)
        var ports: [PortInfo] = []
        
        for line in lines.dropFirst() { // Skip header
            guard !line.isEmpty else { continue }
            
            // Split by whitespace but limit splits
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            guard components.count >= 9 else { continue }
            
            // Parse components
            // Format: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
            let command = String(components[0]).replacingOccurrences(of: "\\x20", with: " ")
            guard let pid = Int32(components[1]) else { continue }
            
            // The NAME column is the last one and contains the port
            let nameColumn = String(components[8])
            
            // Extract port from format like "*:3000", "127.0.0.1:5432", "[::1]:8080"
            var portString: String?
            if let colonIndex = nameColumn.lastIndex(of: ":") {
                let portPart = nameColumn[nameColumn.index(after: colonIndex)...]
                // Remove anything after space (like "(LISTEN)")
                if let spaceIndex = portPart.firstIndex(of: " ") {
                    portString = String(portPart[..<spaceIndex])
                } else {
                    portString = String(portPart)
                }
            }
            
            guard let portStr = portString, let port = Int(portStr) else {
                continue
            }
            
            // Extract address (everything before the colon)
            var address = "*"
            if let colonIndex = nameColumn.lastIndex(of: ":") {
                let addressPart = nameColumn[..<colonIndex]
                address = String(addressPart).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                if address.isEmpty {
                    address = "*"
                }
            }
            
            // Get UID
            let uid = getUIDForPID(pid)
            
            let portInfo = PortInfo(
                port: port,
                processName: command,
                pid: pid,
                uid: uid,
                address: address
            )
            
            ports.append(portInfo)
        }
        
        // Remove duplicates (same port/process/pid) and sort
        var seen = Set<String>()
        let uniquePorts = ports.filter { port in
            let key = "\(port.port)-\(port.pid)"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
        
        return uniquePorts.sorted { $0.port < $1.port }
    }
    
    private func getUIDForPID(_ pid: Int32) -> uid_t {
        // Use ps to get UID
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "uid="]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try? process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        return uid_t(output) ?? 501 // Default to current user
    }
}
