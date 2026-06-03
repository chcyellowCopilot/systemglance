import Foundation

struct SystemStats {
    var cpuTemp: Double = .nan
    var gpuTemp: Double = .nan
    var fanSpeed: Double = 0.0
    var networkSpeed: Double = 0.0
    var downloadSpeed: Double = 0.0
    var uploadSpeed: Double = 0.0
    var cpuUsage: Double = 0.0
    var memoryUsage: Double = 0.0
    var timestamp: Date = Date()
    
    var maxTemp: Double {
        [cpuTemp, gpuTemp].filter(\.isFinite).max() ?? .nan
    }
    
    var isHighTemp: Bool {
        maxTemp.isFinite && maxTemp > 80
    }
    
    var isNormalTemp: Bool {
        maxTemp.isFinite && maxTemp < 60
    }
}

struct NetworkStats {
    var bytesReceived: UInt64 = 0
    var bytesSent: UInt64 = 0
    var timestamp: Date = Date()
    
    var downloadSpeed: Double {
        return Double(bytesReceived) / 1_000_000 // Convert to Mbps
    }
    
    var uploadSpeed: Double {
        return Double(bytesSent) / 1_000_000 // Convert to Mbps
    }
}
