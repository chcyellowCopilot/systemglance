import Foundation
import Darwin

class NetworkMonitor {
    private var previousStats: NetworkStats?
    private var lastUpdateTime: Date = Date()
    
    func getNetworkSpeed() -> (download: Double, upload: Double) {
        let currentStats = readNetworkStats()
        let currentTime = Date()
        
        guard let previous = previousStats else {
            previousStats = currentStats
            lastUpdateTime = currentTime
            return (0, 0)
        }
        
        let timeDelta = currentTime.timeIntervalSince(lastUpdateTime)
        guard timeDelta > 0 else { return (0, 0) }
        
        let bytesDelta = Int64(currentStats.bytesReceived) - Int64(previous.bytesReceived)
        let bytesSentDelta = Int64(currentStats.bytesSent) - Int64(previous.bytesSent)
        
        // Convert to Mbps (bytes per second * 8 / 1,000,000)
        let downloadSpeed = Double(bytesDelta) / timeDelta / 125000.0
        let uploadSpeed = Double(bytesSentDelta) / timeDelta / 125000.0
        
        previousStats = currentStats
        lastUpdateTime = currentTime
        
        return (max(0, downloadSpeed), max(0, uploadSpeed))
    }
    
    private func readNetworkStats() -> NetworkStats {
        var totalBytesReceived: UInt64 = 0
        var totalBytesSent: UInt64 = 0
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return NetworkStats() }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while let interface = ptr?.pointee {
            let name = String(cString: interface.ifa_name)
            let flags = interface.ifa_flags
            
            // Skip loopback and non-active interfaces
            if (flags & UInt32(IFF_UP)) != 0 && 
               (flags & UInt32(IFF_LOOPBACK)) == 0 &&
               interface.ifa_addr?.pointee.sa_family == sa_family_t(AF_LINK) {
                
                if let data = interface.ifa_data {
                    let ifData = data.assumingMemoryBound(to: if_data.self)
                    totalBytesReceived += UInt64(ifData.pointee.ifi_ibytes)
                    totalBytesSent += UInt64(ifData.pointee.ifi_obytes)
                }
            }
            
            ptr = interface.ifa_next
        }
        
        return NetworkStats(bytesReceived: totalBytesReceived, bytesSent: totalBytesSent)
    }
}
