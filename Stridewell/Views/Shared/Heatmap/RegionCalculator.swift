import MapKit
import CoreLocation

/// Computes an MKCoordinateRegion for the heatmap.
enum RegionCalculator {

    /// Degrees of lat/lng span when centering on user location.
    /// 0.1° ≈ 11 km × 8 km at typical running latitudes — covers most urban running ranges.
    static let locationSpan: Double = 0.03

    static let paddingFactor: Double = 1.15

    /// Primary path: if userLocation is available, returns a fixed-span region centered on it.
    /// Fallback: if location is nil (permission denied/unavailable), derives region from
    /// decoded polylines using a median-anchored 50 km radius filter.
    static func region(
        from coordinateGroups: [[CLLocationCoordinate2D]],
        userLocation: CLLocationCoordinate2D?,
        boundingBox: BoundingBox? = nil
    ) -> MKCoordinateRegion? {
        if let loc = userLocation {
            return MKCoordinateRegion(
                center: loc,
                span: MKCoordinateSpan(latitudeDelta: locationSpan, longitudeDelta: locationSpan)
            )
        }
        return regionFromCoordinates(coordinateGroups, boundingBox: boundingBox)
    }

    // MARK: - Fallback (location denied / unavailable)

    private static func regionFromCoordinates(
        _ coordinateGroups: [[CLLocationCoordinate2D]],
        boundingBox: BoundingBox?
    ) -> MKCoordinateRegion? {
        let localGroups = filterOutlierGroups(coordinateGroups)
        let allCoords = localGroups.flatMap { $0 }
        guard !allCoords.isEmpty else { return regionFromBoundingBox(boundingBox) }

        let minLat = allCoords.map(\.latitude).min()!
        let maxLat = allCoords.map(\.latitude).max()!
        let minLng = allCoords.map(\.longitude).min()!
        let maxLng = allCoords.map(\.longitude).max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * paddingFactor, 0.01),
            longitudeDelta: max((maxLng - minLng) * paddingFactor, 0.01)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    /// Filters route groups to those starting within ~50 km of the median start coordinate.
    private static func filterOutlierGroups(
        _ groups: [[CLLocationCoordinate2D]]
    ) -> [[CLLocationCoordinate2D]] {
        let starts = groups.compactMap(\.first)
        guard starts.count >= 3 else { return groups }

        let sortedLats = starts.map(\.latitude).sorted()
        let sortedLngs = starts.map(\.longitude).sorted()
        let mid = starts.count / 2
        let medianLat = sortedLats[mid]
        let medianLng = sortedLngs[mid]

        // 1° lat ≈ 111 km → 0.45° ≈ 50 km
        let thresholdDeg = 0.45

        let filtered = groups.filter { group in
            guard let start = group.first else { return false }
            return abs(start.latitude - medianLat) <= thresholdDeg &&
                   abs(start.longitude - medianLng) <= thresholdDeg
        }
        return filtered.isEmpty ? groups : filtered
    }

    private static func regionFromBoundingBox(_ box: BoundingBox?) -> MKCoordinateRegion? {
        guard let box else { return nil }
        let center = CLLocationCoordinate2D(
            latitude: (box.min_lat + box.max_lat) / 2,
            longitude: (box.min_lng + box.max_lng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (box.max_lat - box.min_lat) * paddingFactor,
            longitudeDelta: (box.max_lng - box.min_lng) * paddingFactor
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
