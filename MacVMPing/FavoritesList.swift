import Foundation
import Combine

struct SavedHost: Codable {
    var hostname: String
    var label: String
}

struct FavoritesList: Codable, Identifiable {
    var id = UUID()
    var name: String
    var hosts: [SavedHost]
    var createdAt: Date = Date()
}

class FavoritesManager: ObservableObject {
    @Published var lists: [FavoritesList] = []

    private let saveURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = dir.appendingPathComponent("MacVMPing")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("favorites.json")
    }()

    init() { load() }

    func save(name: String, hosts: [HostModel]) {
        let savedHosts = hosts.map { SavedHost(hostname: $0.hostname, label: $0.label) }
        if let idx = lists.firstIndex(where: { $0.name == name }) {
            lists[idx].hosts = savedHosts
        } else {
            lists.append(FavoritesList(name: name, hosts: savedHosts))
        }
        persist()
    }

    func delete(_ list: FavoritesList) {
        lists.removeAll { $0.id == list.id }
        persist()
    }

    // MARK: - Import CSV
    // Format attendu : hostname,label  (une ligne par hôte, header optionnel)
    func parseCSV(url: URL) -> [SavedHost] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var results: [SavedHost] = []
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        for line in lines {
            let cols = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let hostname = cols.first, !hostname.isEmpty,
                  !hostname.lowercased().hasPrefix("host") else { continue } // skip header
            let label = cols.count > 1 ? cols[1] : hostname
            results.append(SavedHost(hostname: hostname, label: label))
        }
        return results
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([FavoritesList].self, from: data) else { return }
        lists = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(lists) { try? data.write(to: saveURL) }
    }
}
