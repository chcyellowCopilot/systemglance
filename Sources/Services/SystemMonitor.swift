import Foundation
import Combine

class SystemMonitor: ObservableObject {
    @Published var currentStats = SystemStats()
    
    private let temperatureMonitor = TemperatureMonitor()
    private let fanSpeedMonitor = FanSpeedMonitor()
    private let networkMonitor = NetworkMonitor()
    private var updateTimer: Timer?
    private var previousCPUTicks: [UInt32]?
    
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
        var cpuInfo: processor_info_array_t?
        var processorCount: natural_t = 0
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfo,
            &infoCount
        )

        guard result == KERN_SUCCESS, let cpuInfo else { return 0 }
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: cpuInfo),
                vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride)
            )
        }

        let ticks = Array(UnsafeBufferPointer(start: cpuInfo, count: Int(infoCount))).map(UInt32.init)
        guard let previousCPUTicks, previousCPUTicks.count == ticks.count else {
            self.previousCPUTicks = ticks
            return 0
        }

        var usedTicks: UInt64 = 0
        var totalTicks: UInt64 = 0
        let stride = Int(CPU_STATE_MAX)

        for cpuIndex in 0..<Int(processorCount) {
            let offset = cpuIndex * stride
            let user = tickDelta(ticks[offset + Int(CPU_STATE_USER)], previousCPUTicks[offset + Int(CPU_STATE_USER)])
            let system = tickDelta(ticks[offset + Int(CPU_STATE_SYSTEM)], previousCPUTicks[offset + Int(CPU_STATE_SYSTEM)])
            let nice = tickDelta(ticks[offset + Int(CPU_STATE_NICE)], previousCPUTicks[offset + Int(CPU_STATE_NICE)])
            let idle = tickDelta(ticks[offset + Int(CPU_STATE_IDLE)], previousCPUTicks[offset + Int(CPU_STATE_IDLE)])

            usedTicks += user + system + nice
            totalTicks += user + system + nice + idle
        }

        self.previousCPUTicks = ticks
        guard totalTicks > 0 else { return 0 }
        return min(100, (Double(usedTicks) / Double(totalTicks)) * 100)
    }
    
    private func getMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)

        let kerr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    $0,
                    &count
                )
            }
        }
        
        guard kerr == KERN_SUCCESS else { return 0 }
        
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        let pageSize = Double(vm_kernel_page_size)
        let usedPages = UInt64(stats.internal_page_count + stats.wire_count + stats.compressor_page_count)
        let usedMemory = Double(usedPages) * pageSize
        
        return min(100, (usedMemory / totalMemory) * 100)
    }

    private func tickDelta(_ current: UInt32, _ previous: UInt32) -> UInt64 {
        current >= previous ? UInt64(current - previous) : UInt64(UInt32.max - previous + current)
    }
    
    deinit {
        stopMonitoring()
    }
}
