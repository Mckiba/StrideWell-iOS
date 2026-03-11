//
//  RoutePathShape.swift
//  Stridewell
//
//  A SwiftUI Shape that renders decoded GPS coordinates as a normalized
//  polyline path within any given frame. Used by ActivityCard to draw
//  a per-run route thumbnail.
//

import SwiftUI
import CoreLocation

/// Renders an array of GPS coordinates as a stroked path scaled to fill
/// the view's frame. Coordinate projection uses a simple linear normalization
/// (not Mercator) which is accurate enough for small, thumbnail-scale drawings.
struct RoutePathShape: Shape {

    let coordinates: [CLLocationCoordinate2D]

    func path(in rect: CGRect) -> Path {
        guard coordinates.count > 1 else { return Path() }

        let lats = coordinates.map(\.latitude)
        let lngs = coordinates.map(\.longitude)

        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLng = lngs.min(), let maxLng = lngs.max() else { return Path() }

        let latSpan = maxLat - minLat
        let lngSpan = maxLng - minLng

        // Guard against degenerate routes (e.g. a single repeated point).
        guard latSpan > 0 || lngSpan > 0 else { return Path() }

        // Use the larger span as the denominator so the aspect ratio is
        // preserved inside the frame — the shape fills the shorter axis fully
        // and is centered on the longer axis.
        let scale = min(
            latSpan > 0 ? rect.height / latSpan : .greatestFiniteMagnitude,
            lngSpan > 0 ? rect.width  / lngSpan : .greatestFiniteMagnitude
        )

        let drawWidth  = lngSpan * scale
        let drawHeight = latSpan * scale
        let xOffset    = (rect.width  - drawWidth)  / 2
        let yOffset    = (rect.height - drawHeight) / 2

        func point(for coord: CLLocationCoordinate2D) -> CGPoint {
            let x = xOffset + (coord.longitude - minLng) * scale
            // Invert Y: latitude increases upward, screen Y increases downward.
            let y = yOffset + (maxLat - coord.latitude) * scale
            return CGPoint(x: x + rect.minX, y: y + rect.minY)
        }

        var p = Path()
        p.move(to: point(for: coordinates[0]))
        for coord in coordinates.dropFirst() {
            p.addLine(to: point(for: coord))
        }
        return p
    }
}
