import Foundation
import Darwin
import IOKit
import IOKit.hidsystem

typealias IOHIDEventRef = CFTypeRef

@_silgen_name("IOHIDEventSystemClientCreateWithType")
private func IOHIDEventSystemClientCreateWithType(
    _ allocator: CFAllocator?,
    _ type: Int32,
    _ options: CFDictionary?
) -> IOHIDEventSystemClient

@_silgen_name("IOHIDServiceClientCopyEvent")
private func IOHIDServiceClientCopyEvent(
    _ service: IOHIDServiceClient,
    _ type: Int64,
    _ matching: CFDictionary?,
    _ options: UInt32
) -> IOHIDEventRef?

@_silgen_name("IOHIDEventGetFloatValue")
private func IOHIDEventGetFloatValue(_ event: IOHIDEventRef, _ field: Int32) -> Double

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
        let smcKeys = [
            "TC0P", "TC0E", "TC0F", "TC0H", "TC0D",
            "TC1P", "TC1E", "TC1F", "TC1H", "TC1D",
            "TC2P", "TC2E", "TC2F", "TC2H", "TC2D",
        ]
        let smcTemperatures = smcKeys.compactMap { readTemperature(for: $0) }
        let hidTemperatures = readHIDDieTemperatures()
        return (smcTemperatures + hidTemperatures).max() ?? .nan
    }
    
    func getGPUTemperature() -> Double {
        let gpuKeys = ["TG0P", "TG0D", "TG1P", "TG1D"]
        return gpuKeys.compactMap { readTemperature(for: $0) }.max() ?? .nan
    }
    
    private func connectToSMC() {
        let smcService = IOServiceMatching("AppleSMC")
        var iterator: io_iterator_t = 0
        
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, smcService, &iterator)
        guard result == kIOReturnSuccess else { return }
        
        defer { IOObjectRelease(iterator) }
        
        let device = IOIteratorNext(iterator)
        guard device != 0 else { return }
        
        defer { IOObjectRelease(device) }
        
        let status = IOServiceOpen(device, mach_task_self_, 0, &smcConnection)
        guard status == kIOReturnSuccess else { return }
    }
    
    private func readTemperature(for key: String) -> Double? {
        guard let output = readSMCKey(key) else { return nil }

        let bytes = output.bytesArray
        let value: Double?
        if output.dataType == "sp78", bytes.count >= 2 {
            value = Double(Int8(bitPattern: bytes[0])) + Double(bytes[1]) / 256.0
        } else if output.dataType == "flt ", bytes.count >= 4 {
            value = Double(bytes.withUnsafeBytes { $0.loadUnaligned(as: Float.self) })
        } else if bytes.count >= 2 {
            let raw = UInt16(bigEndian: bytes.withUnsafeBytes { $0.loadUnaligned(as: UInt16.self) })
            value = Double(raw) / 256.0
        } else {
            value = nil
        }

        guard let value, value >= 0, value <= 130 else { return nil }
        return value
    }
    
    func readSMCKey(_ key: String) -> SMCReading? {
        guard smcConnection != 0 else { return nil }

        let keyCode = stringToFourCharCode(key)
        var inputStruct = SMCParamStruct()
        inputStruct.key = keyCode
        inputStruct.data8 = SMCCommand.readKeyInfo.rawValue

        guard callSMC(&inputStruct) == kIOReturnSuccess else { return nil }
        guard inputStruct.result == 0 else { return nil }

        let dataSize = inputStruct.keyInfo.dataSize
        let dataType = fourCharString(inputStruct.keyInfo.dataType)

        var readStruct = SMCParamStruct()
        readStruct.key = keyCode
        readStruct.keyInfo.dataSize = dataSize
        readStruct.data8 = SMCCommand.readBytes.rawValue
        guard callSMC(&readStruct) == kIOReturnSuccess else { return nil }
        guard readStruct.result == 0 else { return nil }

        let bytes = withUnsafeBytes(of: readStruct.bytes) {
            Array($0.prefix(Int(dataSize)))
        }

        return SMCReading(bytesArray: bytes, size: dataSize, dataType: dataType)
    }

    private func readHIDDieTemperatures() -> [Double] {
        let temperatureEventType = 15
        let temperatureField = Int32(temperatureEventType << 16)
        let clientTypes: [Int32] = [1, 3]
        var readings: [Double] = []
        var seenProducts = Set<String>()

        for clientType in clientTypes {
            let client = IOHIDEventSystemClientCreateWithType(kCFAllocatorDefault, clientType, nil)
            guard let services = IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClient] else {
                continue
            }

            for service in services where IOHIDServiceClientConformsTo(service, 65280, 5) != 0 {
                guard let product = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String,
                      product.range(of: #"^PMU2? tdie\d+$"#, options: .regularExpression) != nil,
                      !seenProducts.contains(product),
                      let event = IOHIDServiceClientCopyEvent(service, Int64(temperatureEventType), nil, 0)
                else {
                    continue
                }

                let temperature = IOHIDEventGetFloatValue(event, temperatureField)
                guard temperature >= 0, temperature <= 130 else { continue }
                seenProducts.insert(product)
                readings.append(temperature)
            }
        }

        return readings
    }

    private func fourCharString(_ code: UInt32) -> String {
        let bytes = [
            UInt8((code >> 24) & 0xff),
            UInt8((code >> 16) & 0xff),
            UInt8((code >> 8) & 0xff),
            UInt8(code & 0xff),
        ]
        return String(bytes: bytes, encoding: .ascii) ?? ""
    }

    private func callSMC(_ inputOutput: inout SMCParamStruct) -> kern_return_t {
        var outputStruct = SMCParamStruct()
        var outputSize = MemoryLayout<SMCParamStruct>.stride
        
        let status = IOConnectCallStructMethod(
            smcConnection,
            2,
            &inputOutput,
            MemoryLayout<SMCParamStruct>.stride,
            &outputStruct,
            &outputSize
        )
        
        inputOutput = outputStruct
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
enum SMCCommand: UInt8 {
    case readBytes = 5
    case readKeyInfo = 9
}

struct SMCReading {
    let bytesArray: [UInt8]
    let size: UInt32
    let dataType: String
}

struct SMCVersion {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

struct SMCPLimitData {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
}

struct SMCKeyInfo {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
}

struct SMCParamStruct {
    typealias Bytes32 = (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )

    var key: UInt32 = 0
    var vers: SMCVersion = SMCVersion()
    var pLimitData: SMCPLimitData = SMCPLimitData()
    var keyInfo: SMCKeyInfo = SMCKeyInfo()
    var padding: UInt16 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: Bytes32 = (
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    )
}
