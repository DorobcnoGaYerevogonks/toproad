import Foundation
import Combine

// MARK: - Template Categories

enum TemplateCategory: String, CaseIterable, Codable, Identifiable {
    case essentials, vacation, business, hiking, citybreak, custom
    var id: String { rawValue }

    /// Localization key for UI
    var localizedKey: String {
        switch self {
        case .essentials: return "tpl_cat_essentials"
        case .vacation:   return "tpl_cat_vacation"
        case .business:   return "tpl_cat_business"
        case .hiking:     return "tpl_cat_hiking"
        case .citybreak:  return "tpl_cat_citybreak"
        case .custom:     return "tpl_cat_custom"
        }
    }

    /// SF Symbol name for UI (used later in TemplatesView)
    var systemImage: String {
        switch self {
        case .essentials: return "checkmark.circle"
        case .vacation:   return "sun.max"
        case .business:   return "briefcase"
        case .hiking:     return "figure.hiking"
        case .citybreak:  return "building.2"
        case .custom:     return "square.and.pencil"
        }
    }
}

// MARK: - Template Model

struct Template: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var category: TemplateCategory
    var items: [ChecklistItem] = []
    var notes: String = ""
    var emoji: String? = nil
    /// Built-in templates shipped with the app bundle
    var isBuiltin: Bool = false
}

// MARK: - Store & Persistence

final class TemplateStore: ObservableObject {
    @Published private(set) var templates: [Template] = []

    private let folderName = "TopRoad"
    private let fileName   = "templates.json"

    init() { load() }

    // Public API

    func all() -> [Template] {
        templates.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func list(category: TemplateCategory?) -> [Template] {
        let base = category == nil ? templates : templates.filter { $0.category == category }
        return base.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func add(_ t: Template) {
        var t = t
        t.id = UUID()
        t.isBuiltin = false
        templates.append(t)
        saveCustom()
    }

    func update(_ t: Template) {
        guard let idx = templates.firstIndex(where: { $0.id == t.id }) else { return }
        templates[idx] = t
        saveCustom()
    }

    /// Removes only user-created templates; built-in templates are kept.
    func remove(_ t: Template) {
        guard !t.isBuiltin else { return }
        templates.removeAll { $0.id == t.id }
        saveCustom()
    }

    func duplicate(_ t: Template) {
        var copy = t
        copy.id = UUID()
        copy.isBuiltin = false
        copy.title = String(format: NSLocalizedString("tpl_copy_of", comment: ""), t.title)
        templates.append(copy)
        saveCustom()
    }

    /// Replace (append-or-merge) templates from external JSON file URL.
    func `import`(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let incoming = try JSONDecoder().decode([Template].self, from: data)
        // keep existing, append non-duplicates by title+category
        var map = Dictionary(uniqueKeysWithValues: templates.map { (key: $0.title + "|" + $0.category.rawValue, value: $0) })
        for var t in incoming {
            t.isBuiltin = false
            let k = t.title + "|" + t.category.rawValue
            if map[k] == nil { map[k] = t }
        }
        templates = Array(map.values)
        saveCustom()
    }

    /// Export only user templates to given URL as JSON.
    func exportUserTemplates(to url: URL) throws {
        let user = templates.filter { !$0.isBuiltin }
        let data = try JSONEncoder().encode(user)
        try data.write(to: url, options: [.atomic])
    }

    /// Resets user templates and reloads bundled defaults.
    func resetToDefaults() {
        // delete user file
        let fm = FileManager.default
        let url = fileURL()
        if fm.fileExists(atPath: url.path) {
            try? fm.removeItem(at: url)
        }
        load()
    }

    // MARK: - Apply to Trip (helper)

    /// Builds a Trip from a Template.
    /// You may also use UseTemplateFlowView to gather title/location/dates first.
    func makeTrip(from template: Template,
                  title: String,
                  location: String,
                  startDate: Date,
                  endDate: Date,
                  tripCategory: TripCategory? = nil) -> Trip {
        Trip(
            id: UUID(),
            title: title,
            location: location,
            startDate: startDate,
            endDate: endDate,
            notes: template.notes,
            category: tripCategory ?? mapToTripCategory(template.category),
            checklist: template.items,
            dailyNotes: [],
            isHidden: false
        )
    }

    // MARK: - Private

    private func mapToTripCategory(_ cat: TemplateCategory) -> TripCategory {
        switch cat {
        case .vacation:   return .vacation
        case .business:   return .business
        case .citybreak:  return .event
        case .hiking:     return .weekend
        case .essentials: return .other
        case .custom:     return .other
        }
    }

    private func load() {
        // Load user templates from disk
        let user = loadUserTemplates()

        // Load bundled defaults (optional)
        let bundled = loadBundledDefaults()

        // merge: bundled first (isBuiltin = true), then user overrides/extends
        var result: [Template] = []
        result.append(contentsOf: bundled)
        result.append(contentsOf: user)

        templates = result
    }

    private func saveCustom() {
        let user = templates.filter { !$0.isBuiltin }
        guard let data = try? JSONEncoder().encode(user) else { return }
        let url = fileURL()
        do {
            let fm = FileManager.default
            let dir = url.deletingLastPathComponent()
            if !fm.fileExists(atPath: dir.path) {
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            try data.write(to: url, options: [.atomic])
        } catch {
            // Swallow write errors silently (no UI layer here)
            #if DEBUG
            print("TemplateStore.saveCustom() error: \(error)")
            #endif
        }
    }

    private func loadUserTemplates() -> [Template] {
        let url = fileURL()
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Template].self, from: data) else {
            return []
        }
        // Ensure flags
        return decoded.map { t in
            var t = t; t.isBuiltin = false; return t
        }
    }

    private func loadBundledDefaults() -> [Template] {
        // Try to find "default_templates.json" anywhere in bundle resources
        let bundle = Bundle.main
        let candidate: URL? = (bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .first(where: { $0.lastPathComponent == "default_templates.json" })

        if let url = candidate,
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Template].self, from: data) {
            return decoded.map { t in
                var t = t; t.isBuiltin = true; return t
            }
        }

        // Fallback: several built-in templates (no emojis)
        let essentials = Template(
            title: "Essentials",
            category: .essentials,
            items: [
                ChecklistItem(title: "Passport"),
                ChecklistItem(title: "Tickets / Boarding pass"),
                ChecklistItem(title: "Phone charger"),
                ChecklistItem(title: "Toothbrush")
            ],
            notes: "",
            emoji: nil,
            isBuiltin: true
        )

        let vacation = Template(
            title: "Vacation Starter",
            category: .vacation,
            items: [
                ChecklistItem(title: "Sunscreen"),
                ChecklistItem(title: "Swimwear"),
                ChecklistItem(title: "Sunglasses"),
                ChecklistItem(title: "Hat")
            ],
            notes: "",
            emoji: nil,
            isBuiltin: true
        )

        let business = Template(
            title: "Business Trip",
            category: .business,
            items: [
                ChecklistItem(title: "Laptop"),
                ChecklistItem(title: "Charger"),
                ChecklistItem(title: "Presentation deck"),
                ChecklistItem(title: "Business cards")
            ],
            notes: "",
            emoji: nil,
            isBuiltin: true
        )

        let hiking = Template(
            title: "Hiking Weekend",
            category: .hiking,
            items: [
                ChecklistItem(title: "Hiking boots"),
                ChecklistItem(title: "Water bottle"),
                ChecklistItem(title: "Rain jacket"),
                ChecklistItem(title: "First aid kit")
            ],
            notes: "",
            emoji: nil,
            isBuiltin: true
        )

        return [essentials, vacation, business, hiking]
    }

    private func fileURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(fileName)
    }
}
