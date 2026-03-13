//
//  WeatherStore.swift
//  Stridewell
//
//  Fetches current weather via WeatherKit and exposes a StormCondition
//  that drives the storm overlay on HomeScreen.
//
//
//  Falls back to .clear silently if WeatherKit isn't configured or location
//  is unavailable — no crash, no visible error.
//

import CoreLocation
import WeatherKit

@Observable
final class WeatherStore: NSObject, CLLocationManagerDelegate {

    // MARK: - State

    var condition: StormCondition = .clear

    // Set to override the live condition for testing:
    // weatherStore.debugCondition = .rain
    var debugCondition: StormCondition? = nil

    var activeCondition: StormCondition {
        debugCondition ?? condition
    }

    // MARK: - Private

    private let manager = CLLocationManager()
    private var lastFetchTime: Date?
    private let refreshInterval: TimeInterval = 900  // 15 min

    // MARK: - Init

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Public

    func fetchIfNeeded() {
        if let last = lastFetchTime, Date().timeIntervalSince(last) < refreshInterval { return }
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in await self.fetchWeather(for: location) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    // MARK: - Weather Fetch

    @MainActor
    private func fetchWeather(for location: CLLocation) async {
        do {
            let weather = try await WeatherService.shared.weather(for: location)
            lastFetchTime = Date()
            condition = map(weather.currentWeather.condition)
        } catch {
            // Silent fallback — condition stays .clear
        }
    }

    private func map(_ wkCondition: WeatherKit.WeatherCondition) -> StormCondition {
        switch wkCondition {
        case .drizzle, .rain, .heavyRain, .freezingDrizzle, .freezingRain,
             .sleet, .hail, .sunShowers, .isolatedThunderstorms,
             .scatteredThunderstorms, .thunderstorms, .strongStorms,
             .tropicalStorm, .hurricane:
            return .rain
        case .flurries, .sunFlurries, .snow, .heavySnow, .blizzard,
             .blowingSnow, .wintryMix:
            return .snow
        default:
            return .clear
        }
    }
}
