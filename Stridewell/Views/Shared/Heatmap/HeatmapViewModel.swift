import SwiftUI
import UIKit
import MapKit
import CoreLocation

enum HeatmapState {
    case idle
    case loading
    case ready(UIImage)
    case insufficient   // fewer than 3 runs with GPS
    case error(String)
}

@Observable
@MainActor
final class HeatmapViewModel {

    private(set) var state: HeatmapState = .idle

    /// Set to the screen/view size before calling load(). Drives the render resolution.
    var targetSize: CGSize = UIScreen.main.bounds.size

    private let cache = HeatmapCache()
    private var generationTask: Task<Void, Never>?
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Public

    /// Called on view appear. Loads from cache or kicks off generation.
    func load(userId: String, userLocation: CLLocationCoordinate2D?, userInterfaceStyle: UIUserInterfaceStyle = .light) {
        state = .loading
        generationTask = Task {
            await generate(userId: userId, userLocation: userLocation, userInterfaceStyle: userInterfaceStyle)
        }
    }

    /// Called when a new run syncs, location changes, or color scheme changes. Cancels any in-flight generation.
    func invalidateAndRegenerate(userId: String, userLocation: CLLocationCoordinate2D?, userInterfaceStyle: UIUserInterfaceStyle = .light) {
        generationTask?.cancel()
        generationTask = Task {
            await generate(userId: userId, userLocation: userLocation, userInterfaceStyle: userInterfaceStyle)
        }
    }

    // MARK: - Private

    private func generate(userId: String, userLocation: CLLocationCoordinate2D?, userInterfaceStyle: UIUserInterfaceStyle) async {
        let result = await apiClient.heatmap()

        guard !Task.isCancelled else { return }

        switch result {
        case .failure(_, let message):
            state = .error(message)
            return

        case .success(let response):
            print("[Heatmap] polylines=\(response.polylines.count) run_count=\(response.run_count) bbox=\(String(describing: response.bounding_box))")

            if response.run_count < 3 {
                state = .insufficient
                return
            }

            let hasLocation = userLocation != nil
            let isDark = userInterfaceStyle == .dark
            if let cached = cache.load(userId: userId, runCount: response.run_count,
                                       hasLocation: hasLocation, isDark: isDark) {
                state = .ready(cached)
                return
            }

            // Cache miss — generate
            await runGeneration(response: response, userId: userId, userLocation: userLocation,
                                userInterfaceStyle: userInterfaceStyle)
        }
    }

    private func runGeneration(
        response: HeatmapResponse,
        userId: String,
        userLocation: CLLocationCoordinate2D?,
        userInterfaceStyle: UIUserInterfaceStyle
    ) async {
        do {
            // Decode polylines off main thread
            let coordinateGroups = await Task.detached(priority: .userInitiated) {
                PolylineDecoder.decodeAll(response.polylines)
            }.value

            print("[Heatmap] decoded \(coordinateGroups.count) groups from \(response.polylines.count) polylines")

            guard !Task.isCancelled else { return }

            // Compute region — primary: user location; fallback: run data
            guard let region = RegionCalculator.region(
                from: coordinateGroups,
                userLocation: userLocation,
                boundingBox: response.bounding_box
            ) else {
                state = .insufficient
                return
            }

            print("[Heatmap] region center=(\(region.center.latitude), \(region.center.longitude)) span=(\(region.span.latitudeDelta), \(region.span.longitudeDelta))")

            // Render basemap + routes with the requested map tile appearance
            let image = try await RouteRenderer.render(
                coordinateGroups: coordinateGroups,
                region: region,
                size: targetSize,
                userInterfaceStyle: userInterfaceStyle
            )

            guard !Task.isCancelled else { return }

            cache.save(image, userId: userId, runCount: response.run_count,
                       hasLocation: userLocation != nil, isDark: userInterfaceStyle == .dark)

            state = .ready(image)

        } catch {
            state = .error("Failed to render heatmap")
        }
    }
}
