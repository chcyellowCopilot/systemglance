# Installation & Setup Guide

## Prerequisites

- Mac with Apple Silicon (M1, M2, M3, M4, etc.)
- macOS 12.0 or later
- Xcode 14.0 or later (for development)

## Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/chcyellowCopilot/systemglance.git
cd systemglance
```

### 2. Open in Xcode

```bash
open SystemGlance.xcodeproj
```

### 3. Build & Run

**For Development:**
- Select your Mac as the target
- Press `Cmd + R` or click the Play button

**For Release Build:**
- Select your Mac as the target
- Press `Cmd + B` (or Product > Build)
- The app will be in the `DerivedData` folder

### 4. Install as Menu Bar App

#### Option A: Run from Xcode (Quick Testing)
1. Build and run from Xcode
2. The app will appear in your menu bar

#### Option B: Create Standalone App
1. Build the Release version
2. Locate `SystemGlance.app` in the build output
3. Copy to `/Applications/` folder:
   ```bash
   cp -r path/to/SystemGlance.app /Applications/
   ```
4. Launch from Applications folder or Spotlight

#### Option C: Auto-Launch at Startup
1. Copy `SystemGlance.app` to `/Applications/`
2. Open System Preferences > General > Login Items
3. Add `SystemGlance.app` to the startup list

## Troubleshooting

### App Doesn't Show Temperature/Fan Speed

**Solution:** The app requires privileged access to SMC (System Management Controller).

Run once with sudo to grant permissions:
```bash
sudo /Applications/SystemGlance.app/Contents/MacOS/SystemGlance
```

Or add to sudoers (advanced users only):
```bash
sudo visudo
# Add line: yourusername ALL=(ALL) NOPASSWD: /Applications/SystemGlance.app/Contents/MacOS/SystemGlance
```

### App Not Responding

1. Force quit: `Cmd + Option + Esc` → Select SystemGlance → Force Quit
2. Relaunch the app

### Network Speed Shows 0

- Ensure your Mac is connected to the internet
- Check if network interfaces are properly enumerated
- Restart the app

## Development Notes

### Key Components

- **TemperatureMonitor**: Reads CPU/GPU temps via SMC
- **FanSpeedMonitor**: Accesses fan RPM data from SMC
- **NetworkMonitor**: Tracks network interface statistics
- **SystemMonitor**: Coordinates all monitors and publishes updates
- **PopoverView**: SwiftUI interface for menu bar display

### M-series Optimization

This app is optimized for Apple Silicon with:
- Native arm64 architecture
- Efficient background monitoring
- Minimal power consumption
- 1-second update interval (configurable)

### Code Structure

```
Sources/
├── App/
│   └── SystemGlanceApp.swift      # Main app entry & menu bar setup
├── Views/
│   └── PopoverView.swift          # SwiftUI menu bar popover UI
├── Services/
│   ├── TemperatureMonitor.swift   # SMC temperature reading
│   ├── FanSpeedMonitor.swift      # SMC fan speed reading
│   ├── NetworkMonitor.swift       # Network interface monitoring
│   └── SystemMonitor.swift        # Coordinator/publisher
└── Models/
    └── SystemStats.swift          # Data structures
```

## Advanced Configuration

### Modify Update Interval

In `SystemMonitor.swift`, change the timer interval:
```swift
Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) // 500ms updates
```

### Change Temperature Thresholds

In `PopoverView.swift`, modify `tempColor()`:
```swift
private func tempColor(_ temp: Double) -> Color {
    if temp > 90 { return .red }      // Red above 90°C
    else if temp > 70 { return .orange } // Orange 70-90°C
    else { return .green }             // Green below 70°C
}
```

## Support

For issues or questions:
1. Check [GitHub Issues](https://github.com/chcyellowCopilot/systemglance/issues)
2. Review Xcode build logs for errors
3. Ensure macOS and Xcode are up to date

---

**Happy monitoring!** 🔍
