# Development Guide

## Project Architecture

SystemGlance follows a modular architecture with clear separation of concerns:

### Components

#### 1. **SystemMonitor** (Coordinator)
- Manages all monitoring components
- Publishes updates to SwiftUI via `@Published`
- Runs on background thread to avoid blocking UI
- Single source of truth for system stats

```swift
class SystemMonitor: ObservableObject {
    @Published var currentStats = SystemStats()
    
    func startMonitoring() { ... }
    func stopMonitoring() { ... }
}
```

#### 2. **TemperatureMonitor**
Communicates with Apple's SMC (System Management Controller):
- Reads CPU temperature
- Reads GPU temperature
- Uses IOKit framework

**Key Methods:**
- `getCPUTemperature()` → Double (°C)
- `getGPUTemperature()` → Double (°C)

#### 3. **FanSpeedMonitor**
Accesses fan speed data via SMC:
- Current RPM reading
- Fan percentage calculation
- Supports multiple fans (expandable)

**Key Methods:**
- `getFanSpeed()` → Double (RPM)
- `getFanSpeedPercentage()` → Double (%)

#### 4. **NetworkMonitor**
Tracks real-time network throughput:
- Downloads speed (Mbps)
- Upload speed (Mbps)
- Uses BSD socket APIs (`getifaddrs`)

**Key Methods:**
- `getNetworkSpeed()` → (download: Double, upload: Double)

#### 5. **PopoverView** (SwiftUI)
Menu bar popover UI:
- Real-time stat display
- Color-coded temperature warnings
- Formatted network speeds
- Responsive updates

### Data Flow

```
┌─────────────────────────────────────────────┐
│        System Monitoring Services           │
├─────────────────────────────────────────────┤
│ TemperatureMonitor │ FanSpeedMonitor │ ...  │
└────────────┬───────────┬───────────┬────────┘
             │           │           │
             └─────┬─────┴───────────┘
                   │
           ┌───────▼────────┐
           │ SystemMonitor  │ (ObservableObject)
           │   @Published   │
           │ currentStats   │
           └───────┬────────┘
                   │
           ┌───────▼────────┐
           │  PopoverView   │ (SwiftUI)
           │   Subscribes   │
           │  to updates    │
           └────────────────┘
```

## Adding New Monitoring Features

### Example: Add Disk Usage Monitor

1. **Create DiskMonitor.swift:**
```swift
import Foundation

class DiskMonitor {
    func getDiskUsage() -> Double {
        // Implementation using FileManager
    }
}
```

2. **Add to SystemMonitor:**
```swift
class SystemMonitor: ObservableObject {
    private let diskMonitor = DiskMonitor()
    
    private func updateStats() {
        stats.diskUsage = diskMonitor.getDiskUsage()
    }
}
```

3. **Update SystemStats:**
```swift
struct SystemStats {
    var diskUsage: Double = 0.0
    // ... other properties
}
```

4. **Update PopoverView:**
```swift
StatRow(
    icon: "internaldrive.fill",
    label: "Disk",
    value: String(format: "%.1f%%", monitor.currentStats.diskUsage),
    color: .yellow
)
```

## Building & Compilation

### Debug Build
```bash
xcodebuild -scheme SystemGlance -configuration Debug
```

### Release Build
```bash
xcodebuild -scheme SystemGlance -configuration Release
```

### Archive for Distribution
```bash
xcodebuild -scheme SystemGlance -archivePath SystemGlance.xcarchive archive
xcodebuild -exportArchive -archivePath SystemGlance.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath ./build
```

## Performance Considerations

### Optimization Tips

1. **Update Frequency**
   - Default: 1.0 second
   - Reduce for more frequent updates (higher CPU cost)
   - Increase for less frequent updates (less responsive)

2. **SMC Access**
   - Cache SMC connection
   - Avoid rapid consecutive calls
   - Current implementation optimized for 1Hz updates

3. **Network Monitoring**
   - Efficient byte counting (no packet inspection)
   - Minimal allocations per cycle
   - Binary-safe implementation

4. **Memory**
   - Lightweight data structures
   - Proper deallocation in deinit
   - No memory leaks detected in profiling

### Profiling

Use Xcode's Instruments:
1. Product > Profile (Cmd + I)
2. Select "System Trace" or "Energy Impact"
3. Monitor for 30+ seconds
4. Analyze results

## Testing

### Manual Testing Checklist

- [ ] App appears in menu bar
- [ ] Temperatures display correctly
- [ ] Fan speed updates in real time
- [ ] Network speeds show activity
- [ ] CPU/Memory usage tracked
- [ ] Popover opens/closes smoothly
- [ ] App survives 1+ hour of monitoring
- [ ] CPU usage remains < 2%
- [ ] Memory usage stays < 50MB

### Unit Testing (Future)

Create `SystemGlanceTests` target:
```swift
import XCTest
@testable import SystemGlance

class TemperatureMonitorTests: XCTestCase {
    func testTemperatureRange() {
        let monitor = TemperatureMonitor()
        let temp = monitor.getCPUTemperature()
        XCTAssertGreaterThanOrEqual(temp, 0)
        XCTAssertLessThan(temp, 150)
    }
}
```

## Known Limitations

1. **SMC Access**
   - Requires elevated permissions on some operations
   - Temperature reading accuracy ±2°C typical
   - Fan speed may not update on all Mac models

2. **Network Monitoring**
   - Does not differentiate between interfaces
   - Counts all traffic (including VPN)
   - Calculation resets on app restart

3. **UI**
   - Popover only shows main monitoring data
   - No historical graphing (yet)
   - No configuration options (yet)

## Future Enhancements

- [ ] Historical data visualization
- [ ] Temperature/fan alerts
- [ ] Preferences window
- [ ] Multiple fan monitoring
- [ ] GPU utilization tracking
- [ ] System uptime display
- [ ] Memory pressure indicator
- [ ] Thermal notifications
- [ ] Launch at login setting
- [ ] Alternative display modes (widget, full window)

## Debugging

### Enable Verbose Logging

Add to `SystemMonitor.swift`:
```swift
private func updateStats() {
    print("CPU: \(stats.cpuTemp)°C")
    print("Fan: \(stats.fanSpeed) RPM")
    print("Net: ↓\(stats.downloadSpeed)Mbps ↑\(stats.uploadSpeed)Mbps")
}
```

### Check SMC Connection

```swift
// In TemperatureMonitor
print("SMC Connected: \(smcConnection != 0)")
```

### Monitor Thread Safety

- All UI updates on main thread ✓
- All sensor reads on background thread ✓
- No data races ✓

## Code Style

- Follow Swift API Design Guidelines
- Use MARK comments for organization
- Document public functions
- Prefer `let` over `var`
- Use guard early returns pattern
- Avoid force unwraps (use guard/if-let)

## Contributing

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes following style guide
3. Test thoroughly
4. Create pull request with description
5. Address review feedback

---

Happy developing! 🚀
