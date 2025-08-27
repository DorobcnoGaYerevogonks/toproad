import SwiftUI

struct TemplatesView: View {
    // Stores
    @StateObject private var templateStore = TemplateStore()
    @EnvironmentObject private var tripStore: TripStore

    // UI State
    @State private var query: String = ""
    @State private var selectedCategory: TemplateCategory? = nil
    @State private var editingTemplate: Template? = nil      // <-- sheet(item:)
    @State private var usingTemplate: Template? = nil
    @State private var showImportPicker: Bool = false
    @State private var exportURL: URL? = nil
    @State private var showExportSheet: Bool = false
    @State private var showResetAlert: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if filteredTemplates.isEmpty {
                    ContentUnavailableView {
                        Label("tpl_empty_title", systemImage: "square.and.pencil")
                    } description: {
                        Text("tpl_empty_subtitle")
                    }
                } else {
                    List {
                        categoryChips

                        ForEach(filteredTemplates) { tpl in
                            HStack(spacing: 12) {
                                // Только системные значки
                                Image(systemName: tpl.category.systemImage)
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tpl.title).font(.headline)
                                    HStack(spacing: 6) {
                                        Image(systemName: tpl.category.systemImage)
                                            .foregroundStyle(.secondary)
                                        Text(LocalizedStringKey(tpl.category.localizedKey))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button {
                                    usingTemplate = tpl
                                } label: {
                                    Label(NSLocalizedString("tpl_use", comment: ""), systemImage: "plus.circle")
                                }
                                .buttonStyle(.borderless)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    templateStore.duplicate(tpl)
                                } label: {
                                    Label(NSLocalizedString("tpl_duplicate", comment: ""), systemImage: "doc.on.doc")
                                }.tint(.blue)

                                if !tpl.isBuiltin {
                                    Button(role: .destructive) {
                                        templateStore.remove(tpl)
                                    } label: {
                                        Label(NSLocalizedString("tpl_delete", comment: ""), systemImage: "trash")
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingTemplate = tpl // sheet(item:) откроется
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("tab_templates"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button { showImportPicker = true } label: {
                            Label(NSLocalizedString("tpl_import", comment: ""), systemImage: "square.and.arrow.down")
                        }
                        Button { exportTemplates() } label: {
                            Label(NSLocalizedString("tpl_export", comment: ""), systemImage: "square.and.arrow.up")
                        }
                        Divider()
                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            Label(NSLocalizedString("tpl_reset_defaults", comment: ""), systemImage: "arrow.counterclockwise")
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // создаём новый пустой шаблон — и просто присваиваем в editingTemplate
                        editingTemplate = Template(title: "", category: .custom, items: [], notes: "", emoji: nil, isBuiltin: false)
                    } label: {
                        Label(NSLocalizedString("tpl_create", comment: ""), systemImage: "plus")
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer, prompt: Text("tpl_search_placeholder"))
            .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    do { try templateStore.import(from: url) } catch {
                        #if DEBUG
                        print("Import error: \(error)")
                        #endif
                    }
                case .failure: break
                }
            }
            // ✅ Редактор теперь открывается по самому факту наличия editingTemplate
            .sheet(item: $editingTemplate) { tpl in
                TemplateEditorSheet(template: tpl) { updated, action in
                    switch action {
                    case .save:
                        if templateStore.all().contains(where: { $0.id == updated.id }) {
                            templateStore.update(updated)
                        } else {
                            templateStore.add(updated)
                        }
                    case .delete:
                        templateStore.remove(updated)
                    case .cancel:
                        break
                    }
                }
            }
            .sheet(item: $usingTemplate) { tpl in
                TripFromTemplateSheet(template: tpl) { trip in
                    tripStore.add(trip)
                }
            }
            .alert(NSLocalizedString("tpl_reset_defaults", comment: ""), isPresented: $showResetAlert) {
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {}
                Button(NSLocalizedString("reset", comment: ""), role: .destructive) { templateStore.resetToDefaults() }
            } message: { Text("tpl_reset_warn") }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareLink(item: url) {
                        Label(NSLocalizedString("tpl_share_export", comment: ""), systemImage: "square.and.arrow.up")
                    }
                    .presentationDetents([.medium])
                }
            }
        }
    }

    private var filteredTemplates: [Template] {
        var list = selectedCategory == nil ? templateStore.all()
                                           : templateStore.list(category: selectedCategory)
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list = list.filter { tpl in
                tpl.title.localizedCaseInsensitiveContains(query)
                || tpl.notes.localizedCaseInsensitiveContains(query)
                || tpl.items.contains(where: { $0.title.localizedCaseInsensitiveContains(query) })
            }
        }
        return list
    }

    @ViewBuilder
    private var categoryChips: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(nil, title: NSLocalizedString("all_categories", comment: ""), symbol: "line.3.horizontal.decrease.circle")
                        .opacity(selectedCategory == nil ? 1 : 0.9)
                    ForEach(TemplateCategory.allCases, id: \.self) { cat in
                        chip(cat, title: NSLocalizedString(cat.localizedKey, comment: ""), symbol: cat.systemImage)
                            .opacity(selectedCategory == cat ? 1 : 0.9)
                    }
                }.padding(.vertical, 6)
            }
        }
    }

    private func chip(_ cat: TemplateCategory?, title: String, symbol: String) -> some View {
        let isOn = selectedCategory == cat
        return Button {
            withAnimation { selectedCategory = (selectedCategory == cat ? nil : cat) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                Text(title)
            }
            .font(.caption)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(isOn ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func exportTemplates() {
        do {
            let dir = FileManager.default.temporaryDirectory
            let url = dir.appendingPathComponent("TopRoad_Templates_Export.json")
            try templateStore.exportUserTemplates(to: url)
            exportURL = url
            showExportSheet = true
        } catch {
            #if DEBUG
            print("Export error: \(error)")
            #endif
        }
    }
}

// MARK: - Editor Sheet

private struct TemplateEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State var template: Template
    var onFinish: (Template, TemplateEditorAction) -> Void
    @State private var newItemTitle: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(NSLocalizedString("tpl_title", comment: ""), text: $template.title)
                    Picker(NSLocalizedString("tpl_category", comment: ""), selection: $template.category) {
                        ForEach(TemplateCategory.allCases) { cat in
                            Label(LocalizedStringKey(cat.localizedKey), systemImage: cat.systemImage).tag(cat)
                        }
                    }
                    // Emoji поле удалено — используем только системные значки
                }

                Section(NSLocalizedString("field_notes", comment: "")) {
                    TextEditor(text: $template.notes).frame(minHeight: 100)
                }

                Section(NSLocalizedString("checklist_title", comment: "")) {
                    if template.items.isEmpty {
                        Text("checklist_empty").foregroundStyle(.secondary)
                    } else {
                        ForEach(template.items.indices, id: \.self) { idx in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.secondary)
                                TextField(NSLocalizedString("add_item_placeholder", comment: ""), text: Binding(
                                    get: { template.items[idx].title },
                                    set: { template.items[idx].title = $0 }
                                ))
                                Spacer()
                                Button(role: .destructive) {
                                    template.items.remove(at: idx)
                                } label: {
                                    Image(systemName: "trash")
                                }.buttonStyle(.borderless)
                            }
                        }
                    }
                    HStack {
                        TextField(NSLocalizedString("add_item_placeholder", comment: ""), text: $newItemTitle)
                        Button {
                            let t = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            template.items.append(ChecklistItem(title: t))
                            newItemTitle = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }.buttonStyle(.borderless)
                    }
                }
            }
            .navigationTitle(Text(template.isBuiltin ? "tpl_view" : (template.title.isEmpty ? "tpl_create" : "tpl_edit")))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        onFinish(template, .cancel)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("save", comment: "")) {
                        onFinish(template, .save)
                        dismiss()
                    }.disabled(template.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if !template.isBuiltin {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            onFinish(template, .delete)
                            dismiss()
                        } label: {
                            Label(NSLocalizedString("tpl_delete", comment: ""), systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

private enum TemplateEditorAction { case save, delete, cancel }

// MARK: - Trip Creation Sheet

private struct TripFromTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let template: Template
    var onCreate: (Trip) -> Void

    @State private var tripTitle: String = ""
    @State private var location: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var tripCategory: TripCategory = .other

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(NSLocalizedString("field_title", comment: ""), text: $tripTitle)
                    TextField(NSLocalizedString("field_location", comment: ""), text: $location)
                    Picker(NSLocalizedString("field_category", comment: ""), selection: $tripCategory) {
                        ForEach(TripCategory.allCases) { cat in
                            Label(LocalizedStringKey(cat.localizedTitleKey), systemImage: cat.systemImageName).tag(cat)
                        }
                    }
                }
                Section {
                    DatePicker(NSLocalizedString("field_start", comment: ""), selection: $startDate, displayedComponents: .date)
                    DatePicker(NSLocalizedString("field_end", comment: ""), selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                Section(NSLocalizedString("checklist_title", comment: "")) {
                    if template.items.isEmpty {
                        Text("checklist_empty").foregroundStyle(.secondary)
                    } else {
                        ForEach(template.items, id: \.id) { item in
                            HStack {
                                Image(systemName: "circle")
                                Text(item.title)
                            }
                        }
                        Text("tpl_checklist_hint").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(Text("tpl_use_sheet_title"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("create", comment: "")) {
                        let store = TemplateStore()
                        let title = tripTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? template.title : tripTitle
                        let trip = store.makeTrip(from: template,
                                                  title: title,
                                                  location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                                                  startDate: startDate,
                                                  endDate: endDate,
                                                  tripCategory: tripCategory)
                        onCreate(trip)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if tripTitle.isEmpty { tripTitle = template.title }
                switch template.category {
                case .vacation: tripCategory = .vacation
                case .business: tripCategory = .business
                case .hiking:   tripCategory = .weekend
                case .citybreak: tripCategory = .event
                default: break
                }
            }
        }
    }

    private var isValid: Bool {
        !tripTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        endDate >= startDate
    }
}
