import UIKit

/// Disk-based cache for the rendered heatmap UIImage.
/// Cache key = userId + runCount + hasLocation + cacheVersion — auto-invalidates when a
/// new run syncs, when rendering logic changes (bump cacheVersion), or when the render
/// switches between location-centered ("_loc") and run-data fallback ("_noloc") modes.
final class HeatmapCache {

    /// Bump this whenever RouteRenderer or RegionCalculator logic changes to bust stale images.
    private let cacheVersion = 5

    private let fileManager = FileManager.default

    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("heatmaps", isDirectory: true)
    }

    init() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Cache Key

    func cacheKey(userId: String, runCount: Int, hasLocation: Bool) -> String {
        let locSuffix = hasLocation ? "_loc" : "_noloc"
        return "\(userId)_\(runCount)_v\(cacheVersion)\(locSuffix)"
    }

    // MARK: - Read

    func load(userId: String, runCount: Int, hasLocation: Bool) -> UIImage? {
        let key = cacheKey(userId: userId, runCount: runCount, hasLocation: hasLocation)
        let url = cacheDirectory.appendingPathComponent("\(key).jpg")

        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    // MARK: - Write

    func save(_ image: UIImage, userId: String, runCount: Int, hasLocation: Bool) {
        let key = cacheKey(userId: userId, runCount: runCount, hasLocation: hasLocation)
        let url = cacheDirectory.appendingPathComponent("\(key).jpg")

        guard let data = image.jpegData(compressionQuality: 0.85) else { return }

        do {
            try data.write(to: url, options: .atomic)
            pruneOldFiles(userId: userId, currentKey: key)
        } catch {
            // Cache write failure is non-fatal
            print("[HeatmapCache] Write failed: \(error)")
        }
    }

    // MARK: - Prune

    private func pruneOldFiles(userId: String, currentKey: String) {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        for file in files {
            let name = file.deletingPathExtension().lastPathComponent
            if name.hasPrefix(userId) && name != currentKey {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    // MARK: - Invalidate

    /// Call on sign out or account deletion.
    func clearAll(userId: String) {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        for file in files where file.lastPathComponent.hasPrefix(userId) {
            try? fileManager.removeItem(at: file)
        }
    }
}
