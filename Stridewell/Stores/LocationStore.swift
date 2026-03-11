import CoreLocation

/// Provides a one-shot current location for heatmap centering.
/// Persists the last-known coordinate to UserDefaults so subsequent launches
/// can center the map instantly before a fresh GPS fix arrives.
@Observable
@MainActor
final class LocationStore {

    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    /// Transitions false → true exactly once when the first location is available.
    /// Used by HeatmapBackgroundView to re-trigger generation after permission is granted.
    private(set) var didReceiveLocation: Bool = false

    private let manager = CLLocationManager()
    // IUO instead of lazy — @Observable rewrites stored property storage, lazy is unsupported
    private var locationDelegate: LocationDelegate!

    private static let latKey = "stridewell.heatmap.lastLat"
    private static let lngKey = "stridewell.heatmap.lastLng"

    init() {
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus

        // Restore cached coordinate for instant centering on next launch
        let lat = UserDefaults.standard.double(forKey: Self.latKey)
        let lng = UserDefaults.standard.double(forKey: Self.lngKey)
        if lat != 0 || lng != 0 {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            didReceiveLocation = true
        }

        // Delegate must be set after self is fully initialized
        locationDelegate = LocationDelegate(store: self)
        manager.delegate = locationDelegate
    }

    /// Requests when-in-use permission (if not yet determined) then fires a one-shot location fix.
    /// Safe to call multiple times — idempotent once authorized.
    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // requestLocation() called automatically in didChangeAuthorization after user grants
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break // denied/restricted — coordinate stays nil or uses cached value
        }
    }

    // MARK: - Internal (called from LocationDelegate)

    fileprivate func didChangeAuthorization(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    fileprivate func didUpdateLocation(_ location: CLLocation) {
        coordinate = location.coordinate
        didReceiveLocation = true
        UserDefaults.standard.set(location.coordinate.latitude, forKey: Self.latKey)
        UserDefaults.standard.set(location.coordinate.longitude, forKey: Self.lngKey)
    }
}

// MARK: - CLLocationManagerDelegate

/// Separate NSObject subclass to avoid @Observable / NSObject KVO conflicts.
private final class LocationDelegate: NSObject, CLLocationManagerDelegate {

    private weak var store: LocationStore?

    init(store: LocationStore) {
        self.store = store
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            self?.store?.didChangeAuthorization(manager.authorizationStatus)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [weak self] in
            self?.store?.didUpdateLocation(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Non-fatal — heatmap falls back to run-data region if coordinate is nil
    }
}
