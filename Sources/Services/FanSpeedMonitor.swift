import Foundation
import Darwin
import IOKit

class FanSpeedMonitor {
    private let temperatureMonitor = TemperatureMonitor()
    
    func getFanSpeed() -> Double {
        return readFanRPM(for: "F0Ac")
    }
    
    func getFanSpeedPercentage() -> Double {
        let maxRPM = 8000.0 // Typical max RPM for Apple Silicon
        let currentRPM = getFanSpeed()
        return min(100, (currentRPM / maxRPM) * 100)
    }
    
    private func readFanRPM(for key: String) -> Double {
        guard let output = temperatureMonitor.readSMCKey(key) else { return 0 }

        let bytes = output.bytesArray
        let rpm: Double?
        if output.size == 4, bytes.count >= 4 {
            rpm = Double(bytes.withUnsafeBytes { $0.loadUnaligned(as: Float.self) })
        } else if bytes.count >= 2 {
            let raw = bytesToUInt16(bytes[0], bytes[1])
            rpm = output.dataType == "fpe2" ? Double(raw) / 4.0 : Double(raw)
        } else {
            rpm = nil
        }

        guard let rpm else { return 0 }
        return rpm > 0 && rpm < 10000 ? rpm : 0
    }
    
    private func bytesToUInt16(_ byte1: UInt8, _ byte2: UInt8) -> UInt16 {
        return (UInt16(byte1) << 8) | UInt16(byte2)
    }
}
