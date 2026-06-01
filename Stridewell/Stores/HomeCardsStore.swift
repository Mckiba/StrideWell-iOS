//
//  HomeCardsStore.swift
//  Stridewell
//
//  Owns the fetch + state for weather/home cards. Decorative feature: any
//  failure or missing location resolves to `.empty` with no error surfaced.
//

import CoreLocation

@Observable
@MainActor
final class HomeCardsStore {

    enum HomeCardsState {
        case idle
        case loading
        case ready([HomeCard])
        case empty   // success-with-no-cards, and also silent-failure
    }

    private(set) var state: HomeCardsState = .idle

    #if DEBUG
    /// Debug-only preset locations to exercise card rendering from areas with
    /// active weather. Surfaced via the Settings debug section. `.off` uses the
    /// real device location. Compiled out of release builds entirely.
    enum DebugLocation: String, CaseIterable, Identifiable {
        case off, dubai, delhi, bangkok, singapore
        var id: String { rawValue }
        var label: String {
            switch self {
            case .off:       return "Off"
            case .dubai:     return "Dubai"
            case .delhi:     return "Delhi"
            case .bangkok:   return "Bangkok"
            case .singapore: return "S'pore"
            }
        }
        var coordinate: CLLocationCoordinate2D? {
            switch self {
            case .off:       return nil
            case .dubai:     return CLLocationCoordinate2D(latitude: 25.2026, longitude: 55.2708)
            case .delhi:     return CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090)
            case .bangkok:   return CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018)
            case .singapore: return CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
            }
        }
    }
    /// When not `.off`, `fetch` uses this preset's coordinate instead of the device's.
    var debugLocation: DebugLocation = .off
    #endif

    /// Last time a fetch *successfully* completed (ready or empty). Drives the
    /// 5-minute refresh policy on HomeScreen re-appear.
    private var lastSuccessfulFetch: Date?
    private let refreshInterval: TimeInterval = 300

    /// The sorted cards to render, or [] in any non-ready state.
    var cards: [HomeCard] {
        if case .ready(let cards) = state { return cards }
        return []
    }

    /// Fetches cards for the given coordinate. No-ops if a successful fetch
    /// happened within the refresh window (unless `force`). Nil coordinate or
    /// any failure → `.empty`, silently.
    func fetch(
        apiClient: APIClient,
        coordinate: CLLocationCoordinate2D?,
        units: UnitSystem,
        force: Bool = false
    ) async {
        #if DEBUG
        let overrideCoord = debugLocation.coordinate
        #else
        let overrideCoord: CLLocationCoordinate2D? = nil
        #endif

        if !force, overrideCoord == nil,
           let last = lastSuccessfulFetch,
           Date().timeIntervalSince(last) < refreshInterval {
            return
        }

        guard let coord = overrideCoord ?? coordinate else {
            state = .empty
            return
        }

        if case .idle = state { state = .loading }

        let result = await apiClient.homeCards(
            lat: coord.latitude,
            lng: coord.longitude,
            units: units.rawValue
        )

        switch result {
        case .success(let response):
            lastSuccessfulFetch = Date()
            state = response.cards.isEmpty ? .empty : .ready(response.cards)
        case .failure:
            state = .empty   // silent — decorative feature, no error UI
        }
    }

    func reset() {
        state = .idle
        lastSuccessfulFetch = nil
    }
}
