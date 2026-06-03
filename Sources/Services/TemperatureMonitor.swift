import Foundation
import Darwin

class TemperatureMonitor {
    private var smcConnection: io_connect_t = 0
    
    init() {
        connectToSMC()
    }
    
    deinit {
        if smcConnection != 0 {
            IOServiceClose(smcConnection)
        }
    }
    
    func getCPUTemperature() -> Double {
        return readTemperature(for: "Tc0P")
    }
    
    func getGPUTemperature() -> Double {
        return readTemperature(for: "Tg0P")
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
    
    private func readTemperature(for key: String) -> Double {
        var result: SMCBytes = SMCBytes()
        var inputStruct = SMCParamStruct()
        
        inputStruct.key = stringToFourCharCode(key)
        inputStruct.dataSize = 0
        inputStruct.dataType = stringToFourCharCode("ui8 ")
        
        guard callSMC(inputStruct, &result) == kIOReturnSuccess else { return 0 }
        
        let temperature = Double(result.bytes.0) / 10.0
        return temperature > 0 && temperature < 150 ? temperature : 0
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
}

// SMC Structures
struct SMCBytes {
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

struct SMCParamStruct {
    var key: UInt32 = 0
    var vers: SMCBytes = SMCBytes()
    var plen: SMCBytes = SMCBytes()
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var bytes: SMCBytes = SMCBytes()
}
