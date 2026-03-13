import MapKit
import UIKit

enum HeatmapError: Error {
    case snapshotFailed
    case insufficientData
    case renderFailed
}

/// Renders GPS routes onto a map snapshot image using Core Graphics.
/// All methods are safe to call from a background thread.
enum RouteRenderer {

    struct Config {
        /// Route line color. Accepts any UIColor — use UIColor(hex:alpha:) or UIColor(r:g:b:alpha:)
        var lineColor: UIColor = UIColor(hex: "#289FFF", alpha: 0.75)
        var lineWidth: CGFloat = 2.5
    }

    static func render(
        coordinateGroups: [[CLLocationCoordinate2D]],
        region: MKCoordinateRegion,
        size: CGSize,
        config: Config = Config(),
        userInterfaceStyle: UIUserInterfaceStyle = .light
    ) async throws -> UIImage {
        // Keep the full Snapshot (not just .image) so we can use snapshot.point(for:)
        // for correct Mercator-projected coordinate→pixel conversion.
        let snapshot = try await makeSnapshot(region: region, size: size, userInterfaceStyle: userInterfaceStyle)
        return drawRoutes(on: snapshot, coordinateGroups: coordinateGroups, config: config)
    }

    // MARK: - Private

    private static func makeSnapshot(
        region: MKCoordinateRegion,
        size: CGSize,
        userInterfaceStyle: UIUserInterfaceStyle = .light
    ) async throws -> MKMapSnapshotter.Snapshot {

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.scale = UIScreen.main.scale

        // Standard explore map — no .muted emphasis so roads and labels remain visible.
        let mapConfig = MKStandardMapConfiguration()
        mapConfig.showsTraffic = false
        options.preferredConfiguration = mapConfig

        // Apply the requested appearance style to the map tiles.
        options.traitCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyle)

        let snapshotter = MKMapSnapshotter(options: options)

        return try await withCheckedThrowingContinuation { continuation in
            snapshotter.start(with: DispatchQueue.global(qos: .userInitiated)) { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let snapshot else {
                    continuation.resume(throwing: HeatmapError.snapshotFailed)
                    return
                }
                continuation.resume(returning: snapshot)
            }
        }
    }

    private static func drawRoutes(
        on snapshot: MKMapSnapshotter.Snapshot,
        coordinateGroups: [[CLLocationCoordinate2D]],
        config: Config
    ) -> UIImage {

        let size = snapshot.image.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            snapshot.image.draw(at: .zero)

            let cgCtx = ctx.cgContext
            cgCtx.setStrokeColor(config.lineColor.cgColor)
            cgCtx.setLineWidth(config.lineWidth)
            cgCtx.setLineCap(.round)
            cgCtx.setLineJoin(.round)

            for coords in coordinateGroups {
                guard coords.count > 1 else { continue }

                // snapshot.point(for:) applies the same Mercator projection the
                // snapshotter used when rendering the basemap tile, so route points
                // land exactly on the correct pixel positions.
                let points = coords.map { snapshot.point(for: $0) }

                cgCtx.beginPath()
                cgCtx.move(to: points[0])
                for point in points.dropFirst() {
                    cgCtx.addLine(to: point)
                }
                cgCtx.strokePath()
            }
        }
    }
}
