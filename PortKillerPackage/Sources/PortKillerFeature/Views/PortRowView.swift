import SwiftUI

public struct PortRowView: View {
    let port: PortInfo
    let onKill: () -> Void
    
    @State private var isHovered = false
    
    public init(port: PortInfo, onKill: @escaping () -> Void) {
        self.port = port
        self.onKill = onKill
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Port number - styled as a tag
            Text("\(port.port)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            VStack(alignment: .leading, spacing: 2) {
                // Process name
                Text(port.processName)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
                
                // IP/Interface
                Text(port.address == "*" ? "All interfaces" : port.address)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Stop button - visible on hover
            if isHovered {
                Button(action: onKill) {
                    Text("Stop")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
