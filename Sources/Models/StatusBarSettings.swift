import Foundation

final class StatusBarSettings: ObservableObject {
    @Published var showTemperature: Bool { didSet { save() } }
    @Published var showFanSpeed: Bool { didSet { save() } }
    @Published var showNetworkSpeed: Bool { didSet { save() } }
    @Published var showCPUUsage: Bool { didSet { save() } }
    @Published var showMemoryUsage: Bool { didSet { save() } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showTemperature = defaults.object(forKey: Keys.showTemperature) as? Bool ?? true
        showFanSpeed = defaults.object(forKey: Keys.showFanSpeed) as? Bool ?? true
        showNetworkSpeed = defaults.object(forKey: Keys.showNetworkSpeed) as? Bool ?? true
        showCPUUsage = defaults.object(forKey: Keys.showCPUUsage) as? Bool ?? false
        showMemoryUsage = defaults.object(forKey: Keys.showMemoryUsage) as? Bool ?? false
    }

    private func save() {
        defaults.set(showTemperature, forKey: Keys.showTemperature)
        defaults.set(showFanSpeed, forKey: Keys.showFanSpeed)
        defaults.set(showNetworkSpeed, forKey: Keys.showNetworkSpeed)
        defaults.set(showCPUUsage, forKey: Keys.showCPUUsage)
        defaults.set(showMemoryUsage, forKey: Keys.showMemoryUsage)
    }

    private enum Keys {
        static let showTemperature = "statusBar.showTemperature"
        static let showFanSpeed = "statusBar.showFanSpeed"
        static let showNetworkSpeed = "statusBar.showNetworkSpeed"
        static let showCPUUsage = "statusBar.showCPUUsage"
        static let showMemoryUsage = "statusBar.showMemoryUsage"
    }
}
