# SystemGlance 🔍

A lightweight menu bar application for Mac M-series chips to monitor system temperature, fan speed, and network speed in real-time.

## Features

- 🌡️ **Real-time Temperature Monitoring** - CPU/GPU temperature display
- 💨 **Fan Speed Tracking** - Monitor fan RPM
- 📊 **Network Speed Monitor** - Download/Upload speeds
- 🎨 **Clean Menu Bar UI** - Quick access from status bar
- ⚡ **M-series Optimized** - Native support for Apple Silicon
- 🔋 **Lightweight** - Minimal CPU and memory usage

## Requirements

- macOS 12.0 or later
- Mac with Apple Silicon (M1, M2, M3, etc.)
- Xcode 14.0 or later

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/chcyellowCopilot/systemglance.git
cd systemglance
```

2. Open the project in Xcode:
```bash
open SystemGlance.xcodeproj
```

3. Build and run:
   - Select your Mac as the target
   - Press `Cmd + R` to run

## Architecture

```
SystemGlance/
├── Sources/
│   ├── Views/
│   │   ├── MenuBarView.swift
│   │   └── PopoverView.swift
│   ├── Models/
│   │   ├── SystemStats.swift
│   │   └── MonitoringData.swift
│   ├── Services/
│   │   ├── TemperatureMonitor.swift
│   │   ├── FanSpeedMonitor.swift
│   │   ├── NetworkMonitor.swift
│   │   └── SystemInfoProvider.swift
│   ├── Utils/
│   │   └── Formatters.swift
│   └── App/
│       └── SystemGlanceApp.swift
└── Resources/
    └── Assets.xcassets
```

## Usage

1. Launch SystemGlance
2. Look for the icon in the menu bar (top-right of your screen)
3. Click to see real-time system stats
4. Stats update every second

## Monitoring Details

### Temperature
- CPU temperature
- GPU temperature
- Threshold warnings

### Fan Speed
- Current RPM
- Fan status
- Performance impact

### Network Speed
- Download speed (Mbps)
- Upload speed (Mbps)
- Connection type

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Feel free to submit issues and pull requests.

## Support

For bugs and feature requests, please create an issue on GitHub.

---

Made with ❤️ for Mac M-series chips
