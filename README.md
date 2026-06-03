# SystemGlance

A lightweight macOS menu bar app for Apple Silicon Macs. It shows system temperature, fan speed, network speed, CPU usage, and memory usage in real time.

## Features

- Real-time CPU/GPU temperature display
- Fan RPM display
- Download and upload speed display
- CPU usage from processor tick deltas
- System memory usage from host VM statistics
- Clean SwiftUI popover from the menu bar

## Requirements

- macOS 12.0 or later
- Apple Silicon Mac
- Xcode 14.0 or later

## Installation

```bash
git clone https://github.com/chcyellowCopilot/systemglance.git
cd systemglance
open SystemGlance.xcodeproj
```

Build and run the `SystemGlance` scheme in Xcode.

## Architecture

```text
SystemGlance/
├── Sources/
│   ├── App/
│   │   └── SystemGlanceApp.swift
│   ├── Views/
│   │   └── PopoverView.swift
│   ├── Models/
│   │   └── SystemStats.swift
│   ├── Services/
│   │   ├── SystemMonitor.swift
│   │   ├── TemperatureMonitor.swift
│   │   ├── FanSpeedMonitor.swift
│   │   └── NetworkMonitor.swift
│   └── Info.plist
└── SystemGlance.xcodeproj
```

## Monitoring Details

- Temperature: SMC keys `TC0P` and `TG0P`
- Fan speed: SMC key `F0Ac`
- Network: active non-loopback interfaces from `getifaddrs`
- CPU: host processor tick deltas
- Memory: host VM statistics

## License

MIT License. See `LICENSE`.
