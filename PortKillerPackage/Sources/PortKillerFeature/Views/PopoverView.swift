import SwiftUI

public struct PopoverView: View {
    @StateObject private var scanner = PortScanner()
    private let killer = ProcessKiller()
    
    @State private var searchText = ""
    @State private var systemPortsExpanded = false
    @State private var userPortsExpanded = true
    @State private var showKillConfirmation = false
    @State private var portToKill: PortInfo?
    
    public init() {}
    
    private var filteredPorts: [PortInfo] {
        let allPorts = scanner.ports
        
        guard !searchText.isEmpty else {
            return allPorts
        }
        
        let lowercased = searchText.lowercased()
        return allPorts.filter { port in
            String(port.port).contains(lowercased) ||
            port.processName.lowercased().contains(lowercased) ||
            String(port.pid).contains(lowercased) ||
            port.address.lowercased().contains(lowercased)
        }
    }
    
    private var systemPorts: [PortInfo] {
        filteredPorts.filter { $0.isSystemPort }
    }
    
    private var userPorts: [PortInfo] {
        filteredPorts.filter { !$0.isSystemPort }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with search and refresh
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    // Search bar
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        
                        TextField("Search ports, process, PID...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    
                    // Refresh button
                    Button(action: {
                        Task {
                            await scanner.scan()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .disabled(scanner.isScanning)
                    .help("Refresh port list")
                }
                
                // Error message
                if let error = scanner.lastError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(error, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.borderless)
                        .help("Copy error message")
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding()
            
            Divider()
            
            // Port list
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // System Ports Section
                    if !systemPorts.isEmpty {
                        DisclosureGroup(
                            isExpanded: $systemPortsExpanded,
                            content: {
                                VStack(spacing: 4) {
                                    ForEach(systemPorts, id: \.id) { port in
                                        PortRowView(port: port) {
                                            handleKillRequest(port)
                                        }
                                        .id(port.id)
                                    }
                                }
                                .padding(.top, 4)
                            },
                            label: {
                                HStack {
                                    Image(systemName: "exclamationmark.shield")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14))
                                    Text("System Ports (<1024)")
                                        .font(.system(size: 14, weight: .semibold))
                                    Spacer()
                                    Text("\(systemPorts.count)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        Divider()
                            .padding(.horizontal)
                    }
                    
                    // User Ports Section
                    if !userPorts.isEmpty {
                        DisclosureGroup(
                            isExpanded: $userPortsExpanded,
                            content: {
                                VStack(spacing: 4) {
                                    ForEach(userPorts, id: \.id) { port in
                                        PortRowView(port: port) {
                                            handleKillRequest(port)
                                        }
                                        .id(port.id)
                                    }
                                }
                                .padding(.top, 4)
                            },
                            label: {
                                HStack {
                                    Image(systemName: "network")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 14))
                                    Text("User Ports (≥1024)")
                                        .font(.system(size: 14, weight: .semibold))
                                    Spacer()
                                    Text("\(userPorts.count)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    
                    // Empty state
                    if filteredPorts.isEmpty && !scanner.isScanning {
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text(searchText.isEmpty ? "No ports listening" : "No ports matching your search")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                    
                    // Loading state
                    if scanner.isScanning {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Scanning ports...")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
        .onAppear {
            Task {
                await scanner.scan()
            }
        }
        .alert("Kill System Process?", isPresented: $showKillConfirmation, presenting: portToKill) { port in
            Button("Cancel", role: .cancel) { }
            Button("Kill Process", role: .destructive) {
                Task {
                    await killProcess(port)
                }
            }
        } message: { port in
            Text("Warning: '\(port.processName)' (PID: \(port.pid)) is a system process running as root.\n\nKilling this process may cause system instability or require a restart.")
        }
    }
    
    private func handleKillRequest(_ port: PortInfo) {
        // Check if completely blocked
        if killer.isCompletelyBlocked(port: port) {
            // Show error - cannot kill
            scanner.lastError = "Cannot kill \(port.processName) - critical system process"
            return
        }
        
        // Check if system critical (needs confirmation)
        if killer.isSystemCritical(port: port) {
            portToKill = port
            showKillConfirmation = true
        } else {
            // Kill directly
            Task {
                await killProcess(port)
            }
        }
    }
    
    private func killProcess(_ port: PortInfo) async {
        do {
            try await killer.killProcess(pid: port.pid)
            // Refresh immediately after successful kill
            await scanner.scan()
        } catch {
            await MainActor.run {
                scanner.lastError = "Failed to kill process: \(error.localizedDescription)"
            }
        }
    }
}
