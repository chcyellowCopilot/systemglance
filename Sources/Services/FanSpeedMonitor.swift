import Foundation
import Darwin

class FanSpeedMonitor {
    private var smcConnection: io_connect_t = 0
    
    init() {
        connectToSMC()
    }
    
    deinit {
        if smcConnection != 0 {
            IOServiceClose(smcConnection)
        }
    }
    
    func getFanSpeed() -> Double {
        return readFanRPM(for: "F0Ac")
    }
    
    func getFanSpeedPercentage() -> Double {
        let maxRPM = 8000.0 // Typical max RPM for Apple Silicon
        let currentRPM = getFanSpeed()
        return min(100, (currentRPM / maxRPM) * 100)
    }
    
    private func connectToSMC() {
        let smcService = IOServiceMatching("AppleSMC")
        var iterator: io_iterator_t = 0
        
        let result = IOServiceGetMatchingServices(kIOMasterPortDefault, smcService, &iterator)
        guard result == kIOReturnSuccess else { return }
        
        defer { IOObjectRelease(iterator) }
        
        let device = IOIteratorNext(iterator)
        guard device != 0 else { return }
        
        defer { IOObjectRelease(device) }
        
        let status = IOServiceOpen(device, mach_task_self_, 0, &smcConnection)
        guard status == kIOReturnSuccess else { return }
    }
    
    private func readFanRPM(for key: String) -> Double {
        var result: SMCBytes = SMCBytes()
        var inputStruct = SMCParamStruct()
        
        inputStruct.key = stringToFourCharCode(key)
        inputStruct.dataSize = 0
        inputStruct.dataType = stringToFourCharCode("fpe2")
        
        guard callSMC(inputStruct, &result) == kIOReturnSuccess else { return 0 }
        
        // Convert SMC bytes to RPM (SMC uses fpe2 format)
        let rpm = Double(bytesToUInt16(result.bytes.0, result.bytes.1))
        return rpm > 0 && rpm < 10000 ? rpm : 0
    }
    
    private func callSMC(_ input: SMCParamStruct, _ output: inout SMCBytes) -> kern_return_t {
        var inputStruct = input
        var outputStruct = SMCParamStruct()
        var outputSize = MemoryLayout<SMCParamStruct>.size
        
        let status = IOConnectCallStructMethod(
            smcConnection,
            2,
            &inputStruct,
            MemoryLayout<SMCParamStruct>.size,
            &outputStruct,
            &outputSize
        )
        
        output = outputStruct.bytes
        return status
    }
    
    private func stringToFourCharCode(_ string: String) -> UInt32 {
        let chars = string.utf8
        var result: UInt32 = 0
        for char in chars {
            result = (result << 8) + UInt32(char)
        }
        return result
    }
    
    private func bytesToUInt16(_ byte1: UInt8, _ byte2: UInt8) -> UInt16 {
        return (UInt16(byte1) << 8) | UInt16(byte2)
    }
}
