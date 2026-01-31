import SwiftUI

public struct PortRowView: View {
    let port: PortInfo
    let isSelected: Bool
    let isKilling: Bool
    let onKill: () -> Void
    
    @State private var isHovered = false
    
    public init(port: PortInfo, isSelected: Bool = false, isKilling: Bool = false, onKill: @escaping () -> Void) {
        self.port = port
        self.isSelected = isSelected
        self.isKilling = isKilling
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
                Text(port.address == "*" ? String(localized: "All interfaces", bundle: .module) : port.address)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Stop button or spinner - visible on hover, selected, or killing
            if isKilling {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 60, height: 26)
            } else if isHovered || isSelected {
                Button(action: onKill) {
                    Text(String(localized: "Stop", bundle: .module))
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
        .background(
            isSelected ? Color.accentColor.opacity(0.2) :
            isHovered ? Color.gray.opacity(0.1) : Color.clear
        )
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
