import SwiftUI

struct HostProbeView: View {
    @ObservedObject var host: HostModel
    var onDelete: () -> Void
    var onEdit: () -> Void

    @State private var showLog = true

    var body: some View {
        VStack(spacing: 0) {
            headerView
            statsView.frame(height: 50).background(Color(NSColor.controlBackgroundColor))
            if showLog { logView }
        }
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(statusBorderColor, lineWidth: 2))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    // MARK: - Header
    var headerView: some View {
        ZStack {
            statusBackgroundColor.animation(.easeInOut(duration: 0.3), value: host.status)
            VStack(spacing: 4) {
                Text(host.label)
                    .font(.headline).foregroundColor(.white).shadow(radius: 1)
                Text(host.hostname)
                    .font(.caption).foregroundColor(.white.opacity(0.85))
                Text(host.latency)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.white).shadow(radius: 1)
            }
            .padding(8)
            VStack {
                HStack {
                    Spacer()
                    controlButtons
                }
                Spacer()
            }
            .padding(6)
        }
        .frame(height: 80)
    }

    // MARK: - Boutons
    var controlButtons: some View {
        HStack(spacing: 6) {
            // Start / Stop
            Button {
                host.isRunning ? host.stopPinging() : host.startPinging()
            } label: {
                Image(systemName: host.isRunning ? "stop.circle.fill" : "play.circle.fill")
                    .foregroundColor(.white).font(.title3)
            }.buttonStyle(.plain)

            // Éditer
            Button { onEdit() } label: {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.white).font(.title3)
            }.buttonStyle(.plain)

            // Journal
            Button { withAnimation { showLog.toggle() } } label: {
                Image(systemName: showLog ? "list.bullet.circle.fill" : "list.bullet.circle")
                    .foregroundColor(.white).font(.title3)
            }.buttonStyle(.plain)

            // Supprimer
            Button { host.stopPinging(); onDelete() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.8)).font(.title3)
            }.buttonStyle(.plain)
        }
    }

    // MARK: - Stats
    var statsView: some View {
        HStack(spacing: 0) {
            statItem(label: "OK",     value: "\(host.successCount)", color: .green)
            Divider()
            statItem(label: "KO",     value: "\(host.failureCount)", color: .red)
            Divider()
            statItem(label: "Pertes", value: lossPercentage,          color: .orange)
        }
    }

    func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity)
    }

    var lossPercentage: String {
        let total = host.successCount + host.failureCount
        guard total > 0 else { return "-" }
        return String(format: "%.0f%%", Double(host.failureCount) / Double(total) * 100)
    }

    // MARK: - Journal
    var logView: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(host.log) { entry in
                        HStack(spacing: 6) {
                            Text(entry.timeString)
                                .font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary)
                            Circle().fill(entry.isSuccess ? Color.green : Color.red).frame(width: 6, height: 6)
                            Text(entry.message).font(.system(size: 11)).foregroundColor(.primary)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 1)
                    }
                }.padding(.vertical, 4)
            }
            .frame(height: 120)
            .background(Color(NSColor.textBackgroundColor))
        }
    }

    // MARK: - Couleurs
    var statusBackgroundColor: Color {
        switch host.status {
        case .idle: return .gray; case .pinging: return .blue
        case .up:   return .green; case .down:  return .red; case .error: return .orange
        }
    }
    var statusBorderColor: Color {
        switch host.status {
        case .idle: return .gray.opacity(0.4); case .pinging: return .blue.opacity(0.6)
        case .up:   return .green.opacity(0.6); case .down:  return .red.opacity(0.6); case .error: return .orange.opacity(0.6)
        }
    }
}
