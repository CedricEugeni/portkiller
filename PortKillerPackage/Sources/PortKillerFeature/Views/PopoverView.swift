import SwiftUI

public struct PopoverView: View {
    @StateObject private var scanner = PortScanner()
    private let killer = ProcessKiller()
    
    @State private var searchText = ""
    @State private var systemPortsExpanded = false
    @State private var userPortsExpanded = true
    @State private var showKillConfirmation = false
    @State private var portToKill: PortInfo?
    @State private var selectedPortId: UUID?
    @State private var killingPortId: UUID?
    @FocusState private var isSearchFocused: Bool
    
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
                        
                        TextField(String.moduleLocalized("Search ports, process, PID..."), text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .focused($isSearchFocused)
                            .onSubmit {
                                selectFirstPort()
                            }
                        
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
                    .help(String.moduleLocalized("Refresh port list"))
                }
                
                // Error banner
                if let error = scanner.lastError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(error, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.borderless)
                        .help(String.moduleLocalized("Copy error message"))
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding()
            
            Divider()
            
            // Port list
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // Empty state
                        if filteredPorts.isEmpty && !scanner.isScanning {
                            VStack(spacing: 12) {
                                Image(systemName: "network.slash")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text(searchText.isEmpty ? String.moduleLocalized("No ports listening") : String.moduleLocalized("No ports matching your search"))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                        
                        // System Ports Section
                        if !systemPorts.isEmpty {
                            DisclosureGroup(
                                isExpanded: $systemPortsExpanded,
                                content: {
                                    VStack(spacing: 4) {
                                        ForEach(systemPorts, id: \.id) { port in
                                            PortRowView(
                                                port: port,
                                                isSelected: selectedPortId == port.id,
                                                isKilling: killingPortId == port.id
                                            ) {
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
                                        Text(String.moduleLocalized("System Ports (<1024)"))
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
                                            PortRowView(
                                                port: port,
                                                isSelected: selectedPortId == port.id,
                                                isKilling: killingPortId == port.id
                                            ) {
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
                                        Text(String.moduleLocalized("User Ports (≥1024)"))
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
                        
                        // Loading state
                        if scanner.isScanning {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(String.moduleLocalized("Scanning ports..."))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                }
                .onChange(of: selectedPortId) { _, newId in
                    if let newId = newId {
                        withAnimation {
                            scrollProxy.scrollTo(newId, anchor: .center)
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer with Quit button
            HStack {
                Spacer()
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 11))
                        Text(String.moduleLocalized("Quit"))
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 400, height: 500)
        .onAppear {
            Task {
                await scanner.scan()
            }
            isSearchFocused = true
        }
        .onKeyPress(.upArrow) {
            navigateUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            navigateDown()
            return .handled
        }
        .onKeyPress(.return) {
            if let selectedId = selectedPortId,
               let port = filteredPorts.first(where: { $0.id == selectedId }) {
                handleKillRequest(port)
                return .handled
            }
            return .ignored
        }
        .alert(String.moduleLocalized("Kill System Process?"), isPresented: $showKillConfirmation, presenting: portToKill) { port in
            Button(String.moduleLocalized("Cancel"), role: .cancel) { }
            Button(String.moduleLocalized("Kill Process"), role: .destructive) {
                Task {
                    await killProcess(port)
                }
            }
        } message: { port in
            Text(String.moduleLocalized("Warning: '\(port.processName)' (PID: \(port.pid)) is a system process running as root.\n\nKilling this process may cause system instability or require a restart."))
        }
    }
    
    private func handleKillRequest(_ port: PortInfo) {
        // Check if completely blocked
        if killer.isCompletelyBlocked(port: port) {
            // Show error - cannot kill
            scanner.lastError = String.moduleLocalized("Cannot kill \(port.processName) - critical system process")
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
        await MainActor.run {
            killingPortId = port.id
        }
        
        do {
            try await killer.killProcess(pid: port.pid)
            // Refresh immediately after successful kill
            await scanner.scan()
        } catch {
            await MainActor.run {
                scanner.lastError = String.moduleLocalized("Failed to kill process: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            killingPortId = nil
        }
    }
    
    private func navigateUp() {
        guard !filteredPorts.isEmpty else { return }
        
        if let currentId = selectedPortId,
           let currentIndex = filteredPorts.firstIndex(where: { $0.id == currentId }) {
            if currentIndex > 0 {
                selectedPortId = filteredPorts[currentIndex - 1].id
                expandSectionForPort(filteredPorts[currentIndex - 1])
            }
        } else {
            // Select last port if none selected
            selectedPortId = filteredPorts.last?.id
            if let port = filteredPorts.last {
                expandSectionForPort(port)
            }
        }
    }
    
    private func navigateDown() {
        guard !filteredPorts.isEmpty else { return }
        
        if let currentId = selectedPortId,
           let currentIndex = filteredPorts.firstIndex(where: { $0.id == currentId }) {
            if currentIndex < filteredPorts.count - 1 {
                selectedPortId = filteredPorts[currentIndex + 1].id
                expandSectionForPort(filteredPorts[currentIndex + 1])
            }
        } else {
            // Select first port if none selected
            selectedPortId = filteredPorts.first?.id
            if let port = filteredPorts.first {
                expandSectionForPort(port)
            }
        }
    }
    
    private func selectFirstPort() {
        guard !filteredPorts.isEmpty else { return }
        selectedPortId = filteredPorts.first?.id
        if let port = filteredPorts.first {
            expandSectionForPort(port)
        }
    }
    
    private func expandSectionForPort(_ port: PortInfo) {
        if port.isSystemPort {
            systemPortsExpanded = true
        } else {
            userPortsExpanded = true
        }
    }
}
