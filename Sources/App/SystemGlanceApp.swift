import SwiftUI

@main
struct SystemGlanceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var monitor: SystemMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "◉"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // Initialize monitor
        monitor = SystemMonitor()
        monitor?.startMonitoring()
        
        // Create popover
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: PopoverView(monitor: monitor!))
        popover?.behavior = .transient
        
        // Setup status bar updates
        setupStatusBarUpdates()
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                if let button = statusItem?.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }
    
    func setupStatusBarUpdates() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusBar()
        }
    }
    
    func updateStatusBar() {
        guard let monitor = monitor else { return }
        
        let temp = String(format: "%.0f°", monitor.currentStats.cpuTemp)
        let fan = String(format: "%.0f", monitor.currentStats.fanSpeed)
        let network = monitor.currentStats.networkSpeed > 1000 ? 
            String(format: "%.1fG", monitor.currentStats.networkSpeed / 1000) :
            String(format: "%.0fM", monitor.currentStats.networkSpeed)
        
        if let button = statusItem?.button {
            button.title = "\(temp) \(fan)rpm \(network)bps"
        }
    }
}
