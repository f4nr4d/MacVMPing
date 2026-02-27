import Foundation
import Combine
import UserNotifications

// MARK: - Statut d'un hôte
enum HostStatus {
    case idle, pinging, up, down, error
}

// MARK: - Modèle d'un hôte
class HostModel: ObservableObject, Identifiable {
    let id = UUID()

    @Published var hostname: String
    @Published var label: String
    @Published var status: HostStatus = .idle
    @Published var latency: String = "-"
    @Published var log: [LogEntry] = []
    @Published var isRunning: Bool = false
    @Published var successCount: Int = 0
    @Published var failureCount: Int = 0

    private var pingTask: Process?
    private var pingTimer: Timer?
    var pingInterval: TimeInterval = 2.0
    var pingTimeout: Int = 1000
    private var previousStatus: HostStatus = .idle

    init(hostname: String, label: String = "") {
        self.hostname = hostname
        self.label = label.isEmpty ? hostname : label
    }

    func startPinging() {
        guard !isRunning else { return }
        isRunning = true
        status = .pinging
        previousStatus = .pinging
        performPing()
        pingTimer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in
            self?.performPing()
        }
    }

    func stopPinging() {
        isRunning = false
        pingTimer?.invalidate()
        pingTimer = nil
        pingTask?.terminate()
        pingTask = nil
        status = .idle
        latency = "-"
        previousStatus = .idle
    }

    // Mise à jour hostname/label sans arrêter le ping
    func update(hostname: String, label: String) {
        let wasRunning = isRunning
        stopPinging()
        self.hostname = hostname
        self.label = label.isEmpty ? hostname : label
        self.log = []
        self.successCount = 0
        self.failureCount = 0
        if wasRunning { startPinging() }
    }

    private func performPing() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-W", String(pingTimeout), hostname]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.terminationHandler = { [weak self] proc in
            guard let self = self else { return }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            DispatchQueue.main.async { self.handlePingResult(output: output, exitCode: proc.terminationStatus) }
        }
        do { try process.run(); self.pingTask = process }
        catch {
            DispatchQueue.main.async {
                self.status = .error; self.latency = "Err"
                self.addLog(message: "Erreur : \(error.localizedDescription)", isSuccess: false)
            }
        }
    }

    private func handlePingResult(output: String, exitCode: Int32) {
        let newStatus: HostStatus = exitCode == 0 ? .up : .down
        if exitCode == 0 {
            let lat = extractLatency(from: output)
            status = .up; latency = lat; successCount += 1
            addLog(message: "Réponse de \(hostname) : \(lat)", isSuccess: true)
        } else {
            status = .down; latency = "Délai"; failureCount += 1
            addLog(message: "Pas de réponse de \(hostname)", isSuccess: false)
        }
        let didChange = (previousStatus == .up && newStatus == .down)
                     || (previousStatus == .down && newStatus == .up)
                     || (previousStatus == .pinging && newStatus == .down)
        if didChange { sendNotification(newStatus: newStatus) }
        previousStatus = newStatus
    }

    private func sendNotification(newStatus: HostStatus) {
        let content = UNMutableNotificationContent()
        let fmt = DateFormatter(); fmt.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let ts = fmt.string(from: Date())
        if newStatus == .up {
            content.title = "✅ \(label) — Accessible"
            content.body  = "[\(ts)]  \(hostname) répond à nouveau."
        } else {
            content.title = "🔴 \(label) — Inaccessible"
            content.body  = "[\(ts)]  \(hostname) ne répond plus."
        }
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    private func extractLatency(from output: String) -> String {
        let pattern = "time[<=]([0-9.]+)\\s*ms"
        if let range = output.range(of: pattern, options: .regularExpression) {
            let match = String(output[range])
            if let numRange = match.range(of: "[0-9.]+", options: .regularExpression) {
                return "\(String(match[numRange])) ms"
            }
        }
        return "? ms"
    }

    private func addLog(message: String, isSuccess: Bool) {
        log.insert(LogEntry(message: message, isSuccess: isSuccess), at: 0)
        if log.count > 50 { log = Array(log.prefix(50)) }
    }

    func reset() {
        stopPinging(); log = []; successCount = 0; failureCount = 0; latency = "-"; status = .idle; previousStatus = .idle
    }
}

// MARK: - Entrée de journal
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let message: String
    let isSuccess: Bool
    var timeString: String {
        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: timestamp)
    }
}
