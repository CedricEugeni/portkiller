import Foundation

public struct PortInfo: Identifiable, Equatable {
    public let id = UUID()
    public let port: Int
    public let processName: String
    public let pid: Int32
    public let uid: uid_t
    public let address: String
    public let protocolType: String
    
    public var isSystemPort: Bool {
        port < 1024
    }
    
    public init(port: Int, processName: String, pid: Int32, uid: uid_t, address: String, protocolType: String = "TCP") {
        self.port = port
        self.processName = processName
        self.pid = pid
        self.uid = uid
        self.address = address
        self.protocolType = protocolType
    }
}
