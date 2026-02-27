import SwiftUI
import UniformTypeIdentifiers

// MARK: - Vue principale
struct ContentView: View {

    @State private var hosts: [HostModel] = {
        let list = [
            HostModel(hostname: "8.8.8.8", label: "Google DNS"),
            HostModel(hostname: "1.1.1.1", label: "Cloudflare DNS"),
        ]
        list.forEach { $0.startPinging() }
        return list
    }()

    @StateObject private var favManager = FavoritesManager()

    // Sheets
    @State private var showAddSheet       = false
    @State private var showSaveSheet      = false
    @State private var showEditSheet      = false
    @State private var showCSVImporter    = false

    // Formulaires
    @State private var newHostname  = ""
    @State private var newLabel     = ""
    @State private var newListName  = ""
    @State private var editingHost: HostModel? = nil
    @State private var editHostname = ""
    @State private var editLabel    = ""

    // Colonnes
    @State private var columnCount = 2

    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if hosts.isEmpty {
                emptyState
            } else {
                // GeometryReader pour le redimensionnement automatique
                GeometryReader { geo in
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(hosts) { host in
                                HostProbeView(host: host,
                                    onDelete: { removeHost(host) },
                                    onEdit:   { startEdit(host) }
                                )
                            }
                        }
                        .padding(12)
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        // Ajuste automatiquement les colonnes selon la largeur
        .background(GeometryReader { geo in
            Color.clear.onChange(of: geo.size.width) { _, width in
                let newCols = max(1, Int(width / 320))
                if newCols != columnCount { columnCount = newCols }
            }
        })
        .sheet(isPresented: $showAddSheet)    { addHostSheet }
        .sheet(isPresented: $showSaveSheet)   { saveListSheet }
        .sheet(isPresented: $showEditSheet)   { editHostSheet }
        .fileImporter(isPresented: $showCSVImporter,
                      allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
                      allowsMultipleSelection: false) { result in
            handleCSVImport(result: result)
        }
    }

    // MARK: - Barre d'outils
    var toolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "network").font(.title2).foregroundColor(.accentColor)
                Text("MacVMPing by f4n").font(.headline)
            }

            Spacer()

            // Colonnes manuelles
            HStack(spacing: 4) {
                Text("Colonnes :").font(.caption).foregroundColor(.secondary)
                Stepper("\(columnCount)", value: $columnCount, in: 1...6).frame(width: 90)
            }

            Divider().frame(height: 20)

            Button { hosts.forEach { $0.startPinging() } } label: {
                Label("Démarrer tout", systemImage: "play.circle.fill")
            }
            Button { hosts.forEach { $0.stopPinging() } } label: {
                Label("Arrêter tout", systemImage: "stop.circle.fill")
            }

            Divider().frame(height: 20)

            // ── Menu Listes ───────────────────────────────────────
            Menu {
                // Sauvegarder
                Button { showSaveSheet = true } label: {
                    Label("Sauvegarder la liste actuelle", systemImage: "square.and.arrow.down")
                }

                // Importer CSV
                Button { showCSVImporter = true } label: {
                    Label("Importer un fichier CSV...", systemImage: "doc.text")
                }

                Divider()

                if favManager.lists.isEmpty {
                    Text("Aucune liste sauvegardée").foregroundColor(.secondary)
                } else {
                    ForEach(favManager.lists) { fav in
                        Menu(fav.name) {
                            Button { loadList(fav) } label: {
                                Label("Charger (remplacer)", systemImage: "arrow.down.circle")
                            }
                            Button { appendList(fav) } label: {
                                Label("Ajouter à la liste actuelle", systemImage: "plus.circle")
                            }
                            Divider()
                            Button(role: .destructive) { favManager.delete(fav) } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                    }
                }
            } label: {
                Label("Listes", systemImage: "list.star")
            }

            Divider().frame(height: 20)

            Button { showAddSheet = true } label: {
                Label("Ajouter", systemImage: "plus.circle.fill")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - État vide
    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "network.slash").font(.system(size: 60)).foregroundColor(.secondary.opacity(0.5))
            Text("Aucun hôte configuré").font(.title2).foregroundColor(.secondary)
            Text("Cliquez sur « Ajouter » ou importez un CSV.").font(.caption).foregroundColor(.secondary)
            HStack(spacing: 12) {
                Button("Ajouter un hôte") { showAddSheet = true }.buttonStyle(.borderedProminent)
                Button("Importer CSV")    { showCSVImporter = true }.buttonStyle(.bordered)
            }
            Spacer()
        }
    }

    // MARK: - Sheet : Ajouter un hôte
    var addHostSheet: some View {
        VStack(spacing: 20) {
            Text("Ajouter un hôte").font(.title2).fontWeight(.semibold)
            Form {
                Section {
                    TextField("Adresse IP ou nom d'hôte", text: $newHostname)
                        .textFieldStyle(.roundedBorder).onSubmit { addHost() }
                    TextField("Label (optionnel)", text: $newLabel)
                        .textFieldStyle(.roundedBorder).onSubmit { addHost() }
                }
            }.formStyle(.grouped)
            HStack(spacing: 12) {
                Button("Annuler") { resetForm(); showAddSheet = false }.keyboardShortcut(.escape)
                Button("Ajouter") { addHost() }
                    .buttonStyle(.borderedProminent)
                    .disabled(newHostname.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return)
            }
        }
        .padding(24).frame(width: 360)
    }

    // MARK: - Sheet : Éditer un hôte
    var editHostSheet: some View {
        VStack(spacing: 20) {
            Text("Modifier l'hôte").font(.title2).fontWeight(.semibold)
            Form {
                Section {
                    TextField("Adresse IP ou nom d'hôte", text: $editHostname)
                        .textFieldStyle(.roundedBorder).onSubmit { confirmEdit() }
                    TextField("Label", text: $editLabel)
                        .textFieldStyle(.roundedBorder).onSubmit { confirmEdit() }
                }
            }.formStyle(.grouped)
            HStack(spacing: 12) {
                Button("Annuler") { showEditSheet = false }.keyboardShortcut(.escape)
                Button("Enregistrer") { confirmEdit() }
                    .buttonStyle(.borderedProminent)
                    .disabled(editHostname.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return)
            }
        }
        .padding(24).frame(width: 360)
    }

    // MARK: - Sheet : Sauvegarder liste
    var saveListSheet: some View {
        VStack(spacing: 20) {
            Text("Sauvegarder la liste").font(.title2).fontWeight(.semibold)
            Text("\(hosts.count) hôte(s) seront sauvegardés").foregroundColor(.secondary).font(.caption)
            TextField("Nom de la liste (ex: Bureau, Prod...)", text: $newListName)
                .textFieldStyle(.roundedBorder).onSubmit { saveList() }.frame(width: 280)
            HStack(spacing: 12) {
                Button("Annuler") { newListName = ""; showSaveSheet = false }.keyboardShortcut(.escape)
                Button("Sauvegarder") { saveList() }
                    .buttonStyle(.borderedProminent)
                    .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return)
            }
        }
        .padding(24).frame(width: 360)
    }

    // MARK: - Actions hôtes
    func addHost() {
        let h = newHostname.trimmingCharacters(in: .whitespaces)
        guard !h.isEmpty else { return }
        let host = HostModel(hostname: h, label: newLabel.trimmingCharacters(in: .whitespaces))
        host.startPinging()
        hosts.append(host)
        resetForm(); showAddSheet = false
    }

    func removeHost(_ host: HostModel) {
        host.stopPinging()
        hosts.removeAll { $0.id == host.id }
    }

    func startEdit(_ host: HostModel) {
        editingHost  = host
        editHostname = host.hostname
        editLabel    = host.label
        showEditSheet = true
    }

    func confirmEdit() {
        let h = editHostname.trimmingCharacters(in: .whitespaces)
        guard !h.isEmpty, let host = editingHost else { return }
        host.update(hostname: h, label: editLabel.trimmingCharacters(in: .whitespaces))
        showEditSheet = false
        editingHost = nil
    }

    func resetForm() { newHostname = ""; newLabel = "" }

    // MARK: - Actions listes
    func saveList() {
        let name = newListName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        favManager.save(name: name, hosts: hosts)
        newListName = ""; showSaveSheet = false
    }

    func loadList(_ fav: FavoritesList) {
        hosts.forEach { $0.stopPinging() }
        hosts = fav.hosts.map {
            let h = HostModel(hostname: $0.hostname, label: $0.label)
            h.startPinging(); return h
        }
    }

    func appendList(_ fav: FavoritesList) {
        let new = fav.hosts.map {
            let h = HostModel(hostname: $0.hostname, label: $0.label)
            h.startPinging(); return h
        }
        hosts.append(contentsOf: new)
    }

    // MARK: - Import CSV
    func handleCSVImport(result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        // Accès sécurisé au fichier
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        let imported = favManager.parseCSV(url: url)
        guard !imported.isEmpty else { return }

        let new = imported.map {
            let h = HostModel(hostname: $0.hostname, label: $0.label)
            h.startPinging(); return h
        }
        hosts.append(contentsOf: new)
    }
}

#Preview { ContentView() }
