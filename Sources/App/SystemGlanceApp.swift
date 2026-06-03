import SwiftUI
import AppKit

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
    var settings = StatusBarSettings()
    private var eventMonitor: Any?
    
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
        popover?.contentViewController = NSHostingController(rootView: PopoverView(monitor: monitor!, settings: settings))
        popover?.behavior = .transient
        
        // Setup status bar updates
        setupStatusBarUpdates()
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let popover = popover {
            if popover.isShown {
                closePopover(sender)
            } else {
                if let button = statusItem?.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    startEventMonitor()
                }
            }
        }
    }

    private func closePopover(_ sender: AnyObject?) {
        popover?.performClose(sender)
        stopEventMonitor()
    }

    private func startEventMonitor() {
        stopEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.closePopover(nil)
            }
        }
    }

    private func stopEventMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
    
    func setupStatusBarUpdates() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusBar()
        }
    }
    
    func updateStatusBar() {
        guard let monitor = monitor else { return }
        
        var parts: [(String, String, NSColor)] = []

        if settings.showTemperature {
            let temp = monitor.currentStats.cpuTemp.isFinite ? String(format: "%.0f°", monitor.currentStats.cpuTemp) : "--°"
            let tempColor: NSColor = monitor.currentStats.cpuTemp > 60 ? .systemRed : .systemGreen
            parts.append(("thermometer.sun.fill", temp, tempColor))
        }

        if settings.showFanSpeed {
            let fan = monitor.currentStats.fanSpeed > 0 ? String(format: "%.0frpm", monitor.currentStats.fanSpeed) : "--rpm"
            parts.append(("wind", fan, .systemBlue))
        }

        if settings.showNetworkSpeed {
            let network = monitor.currentStats.networkSpeed > 1000 ?
                String(format: "%.1fGbps", monitor.currentStats.networkSpeed / 1000) :
                String(format: "%.0fMbps", monitor.currentStats.networkSpeed)
            parts.append(("network", network, .systemGreen))
        }

        if settings.showCPUUsage {
            parts.append(("cpu.fill", String(format: "%.0f%%", monitor.currentStats.cpuUsage), .systemOrange))
        }

        if settings.showMemoryUsage {
            parts.append(("memorychip.fill", String(format: "%.0f%%", monitor.currentStats.memoryUsage), .systemPurple))
        }
        
        if let button = statusItem?.button {
            button.attributedTitle = statusBarTitle(parts)
        }
    }

    private func statusBarTitle(_ parts: [(String, String, NSColor)]) -> NSAttributedString {
        let title = NSMutableAttributedString()
        let valueFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        let iconFont = NSFont.systemFont(ofSize: 15, weight: .bold)
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: NSColor.labelColor
        ]

        if parts.isEmpty {
            return NSAttributedString(string: "SYSGLANCE", attributes: baseAttributes)
        }

        for (index, part) in parts.enumerated() {
            if index > 0 {
                title.append(NSAttributedString(string: " ︱ ", attributes: [
                    .font: valueFont,
                    .foregroundColor: NSColor.secondaryLabelColor
                ]))
            }

            title.append(statusBarIcon(symbolName: part.0, color: part.2, font: iconFont))
            title.append(NSAttributedString(string: " "))

            title.append(NSAttributedString(string: part.1, attributes: [
                .font: valueFont,
                .foregroundColor: part.2
            ]))
        }

        return title
    }

    private func statusBarIcon(symbolName: String, color: NSColor, font: NSFont) -> NSAttributedString {
        guard let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
            return NSAttributedString(string: "●", attributes: [
                .font: font,
                .foregroundColor: color
            ])
        }

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let configuredImage = image.withSymbolConfiguration(symbolConfig) ?? image
        let tintedImage = configuredImage.tinted(with: color)
        let attachment = NSTextAttachment()
        attachment.image = tintedImage
        attachment.bounds = CGRect(x: 0, y: -2, width: 15, height: 15)
        return NSAttributedString(attachment: attachment)
    }
}

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: size)
        draw(in: rect, from: rect, operation: .sourceOver, fraction: 1)
        rect.fill(using: .sourceAtop)
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
