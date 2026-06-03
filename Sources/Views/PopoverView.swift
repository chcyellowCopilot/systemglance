import SwiftUI

struct PopoverView: View {
    @ObservedObject var monitor: SystemMonitor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("SystemGlance")
                    .font(.headline)
                Spacer()
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            VStack(spacing: 12) {
                // Temperature Section
                StatRow(
                    icon: "thermometer.sun.fill",
                    label: "Temperature",
                    value: String(format: "%.1f°C", monitor.currentStats.cpuTemp),
                    subvalue: String(format: "GPU: %.1f°C", monitor.currentStats.gpuTemp),
                    color: tempColor(monitor.currentStats.maxTemp)
                )
                
                // Fan Speed Section
                StatRow(
                    icon: "wind",
                    label: "Fan Speed",
                    value: String(format: "%.0f RPM", monitor.currentStats.fanSpeed),
                    subvalue: String(format: "%.0f%%", min(100, (monitor.currentStats.fanSpeed / 8000) * 100)),
                    color: .blue
                )
                
                // Network Speed Section
                StatRow(
                    icon: "network",
                    label: "Network",
                    value: formatNetworkSpeed(monitor.currentStats.downloadSpeed),
                    subvalue: "↑ " + formatNetworkSpeed(monitor.currentStats.uploadSpeed),
                    color: .green
                )
                
                // CPU Usage
                StatRow(
                    icon: "cpu.fill",
                    label: "CPU Usage",
                    value: String(format: "%.1f%%", monitor.currentStats.cpuUsage),
                    color: .orange
                )
                
                // Memory Usage
                StatRow(
                    icon: "memorychip.fill",
                    label: "Memory",
                    value: String(format: "%.1f%%", monitor.currentStats.memoryUsage),
                    color: .purple
                )
            }
            .padding(.horizontal)
            
            Divider()
            
            HStack(spacing: 8) {
                Text("Updated: \(formatTime(monitor.currentStats.timestamp))")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 320)
        .background(colorScheme == .dark ? Color(white: 0.12) : Color.white)
    }
    
    private func tempColor(_ temp: Double) -> Color {
        if temp > 80 {
            return .red
        } else if temp > 60 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func formatNetworkSpeed(_ speed: Double) -> String {
        if speed > 1000 {
            return String(format: "↓ %.2f Gbps", speed / 1000)
        } else if speed > 0.1 {
            return String(format: "↓ %.1f Mbps", speed)
        } else {
            return "↓ 0.0 Mbps"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    var subvalue: String?
    var color: Color = .blue
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack {
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                    if let subvalue = subvalue {
                        Text(subvalue)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    PopoverView(monitor: SystemMonitor())
}
