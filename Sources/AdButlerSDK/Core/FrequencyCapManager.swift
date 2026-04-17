import Foundation

/// Manages per-banner frequency caps using UserDefaults.
internal final class FrequencyCapManager {
    private let defaults: UserDefaults
    private let storageKey = "com.adbutler.sdk.frequency_caps"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Record an impression for the given banner ID.
    func recordImpression(bannerId: Int) {
        var caps = loadCaps()
        let key = String(bannerId)
        var entry = caps[key] ?? FrequencyEntry(count: 0, firstSeen: Date())
        entry.count += 1
        caps[key] = entry
        saveCaps(caps)
    }

    /// Get the impression count for the given banner ID.
    func impressionCount(bannerId: Int) -> Int {
        let caps = loadCaps()
        return caps[String(bannerId)]?.count ?? 0
    }

    /// Clear all frequency data.
    func clearAll() {
        defaults.removeObject(forKey: storageKey)
    }

    private func loadCaps() -> [String: FrequencyEntry] {
        guard let data = defaults.data(forKey: storageKey),
              let caps = try? JSONDecoder().decode([String: FrequencyEntry].self, from: data) else {
            return [:]
        }
        return caps
    }

    private func saveCaps(_ caps: [String: FrequencyEntry]) {
        if let data = try? JSONEncoder().encode(caps) {
            defaults.set(data, forKey: storageKey)
        }
    }
}

private struct FrequencyEntry: Codable {
    var count: Int
    var firstSeen: Date
}
