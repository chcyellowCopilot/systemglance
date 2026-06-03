import Foundation
import Combine

class SystemMonitor: ObservableObject {
    @Published var currentStats = SystemStats()
    
    private let temperatureMonitor = TemperatureMonitor()
    private let fanSpeedMonitor = FanSpeedMonitor()
    private let networkMonitor = NetworkMonitor()
    private var updateTimer: Timer?
    
    func startMonitoring() {
        // Initial update
        updateStats()
        
        // Schedule regular updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateStats() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            var stats = SystemStats()
            
            stats.cpuTemp = self?.temperatureMonitor.getCPUTemperature() ?? 0
            stats.gpuTemp = self?.temperatureMonitor.getGPUTemperature() ?? 0
            stats.fanSpeed = self?.fanSpeedMonitor.getFanSpeed() ?? 0
            
            let (download, upload) = self?.networkMonitor.getNetworkSpeed() ?? (0, 0)
            stats.downloadSpeed = download
            stats.uploadSpeed = upload
            stats.networkSpeed = download + upload
            
            stats.cpuUsage = self?.getCPUUsage() ?? 0
            stats.memoryUsage = self?.getMemoryUsage() ?? 0
            stats.timestamp = Date()
            
            DispatchQueue.main.async {
                self?.currentStats = stats
            }
        }
    }
    
    private func getCPUUsage() -> Double {
        var loadAvg = [Double](repeating: 0, count: 3)
        getloadavg(&loadAvg, 3)
        
        // Normalize to percentage (assuming 8 cores for M-series)
        let cores = Double(ProcessInfo.processInfo.activeProcessorCount)
        return min(100, (loadAvg[0] / cores) * 100)
    }
    
    private func getMemoryUsage() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size)/4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_VM_INFO),
                    $0,
                    &count
                )
            }
        }
        
        guard kerr == KERN_SUCCESS else { return 0 }
        
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        let usedMemory = Double(info.phys_footprint)
        
        return min(100, (usedMemory / totalMemory) * 100)
    }
    
    deinit {
        stopMonitoring()
    }
}
