//
//  RouteMapView.swift
//  Stridewell
//
//  Interactive Mapbox route map for RunDetailScreen.
//  Token must be set via MapboxOptions.accessToken before first use (done in StridewellApp.init).
//

import SwiftUI
import MapboxMaps
import CoreLocation

struct RouteMapView: UIViewRepresentable {

    let coordinates: [CLLocationCoordinate2D]
    let startLatLng: CLLocationCoordinate2D?
    let bottomInset: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MapView {
        let options = MapInitOptions(
            styleURI: StyleURI(rawValue: "mapbox://styles/mapbox/outdoors-v12")!
        )
        let mapView = MapView(frame: .zero, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.ornaments.options.scaleBar.visibility = .hidden
        mapView.ornaments.options.logo.margins       = .init(x: 8, y: 8)
        mapView.ornaments.options.attributionButton.margins = .init(x: 8, y: 8)

        let coordinator = context.coordinator
        coordinator.mapView      = mapView
        coordinator.coordinates  = coordinates
        coordinator.bottomInset  = bottomInset

        // Store the cancelable — if dropped, the observation is cancelled before the style loads.
        coordinator.styleLoadedObserver = mapView.mapboxMap.onStyleLoaded.observeNext { [weak coordinator] _ in
            coordinator?.styleLoadedObserver = nil   // release after firing
            coordinator?.addRoute()
            coordinator?.fitCamera()
        }

        return mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {
        context.coordinator.bottomInset = bottomInset
        // Re-fit camera whenever the sheet detent changes and style is already loaded.
        if uiView.mapboxMap.style.isLoaded {
            context.coordinator.fitCamera()
        }
    }

    // MARK: - Coordinator

    final class Coordinator {
        weak var mapView: MapView?
        var coordinates: [CLLocationCoordinate2D] = []
        var bottomInset: CGFloat = 0
        // Retains the Mapbox cancelable until the style-loaded event fires.
        var styleLoadedObserver: AnyCancelable?

        private let sourceId      = "sw-route-source"
        private let casingLayerId = "sw-route-casing"
        private let routeLayerId  = "sw-route-line"
        private var routeAdded    = false

        func addRoute() {
            guard !routeAdded, let mapView, coordinates.count >= 2 else { return }
            routeAdded = true

            var source = GeoJSONSource(id: sourceId)
            source.data = .geometry(.lineString(LineString(coordinates)))

            var casing = LineLayer(id: casingLayerId, source: sourceId)
            casing.lineColor = .constant(StyleColor(.white))
            casing.lineWidth = .constant(7)
            casing.lineCap   = .constant(.round)
            casing.lineJoin  = .constant(.round)

            var route = LineLayer(id: routeLayerId, source: sourceId)
            route.lineColor = .constant(StyleColor(UIColor(red: 0.157, green: 0.624, blue: 1.0, alpha: 1.0)))
            route.lineWidth = .constant(4)
            route.lineCap   = .constant(.round)
            route.lineJoin  = .constant(.round)

            try? mapView.mapboxMap.addSource(source)
            try? mapView.mapboxMap.addLayer(casing)
            try? mapView.mapboxMap.addLayer(route, layerPosition: .above(casingLayerId))

            addMarkers()
        }

        private func addMarkers() {
            guard let mapView,
                  let first = coordinates.first,
                  let last  = coordinates.last else { return }

            let manager = mapView.annotations.makePointAnnotationManager()

            var startPin = PointAnnotation(coordinate: first)
            startPin.image = .init(image: dot(color: .systemGreen), name: "sw-start-dot")

            var finishPin = PointAnnotation(coordinate: last)
            finishPin.image = .init(image: dot(color: UIColor(red: 0.157, green: 0.624, blue: 1.0, alpha: 1.0)), name: "sw-finish-dot")

            manager.annotations = [startPin, finishPin]
        }

        func fitCamera() {
            guard let mapView, coordinates.count >= 2 else { return }
            let padding = UIEdgeInsets(top: 60, left: 24, bottom: bottomInset + 24, right: 24)
            let camera  = mapView.mapboxMap.camera(
                for: coordinates,
                padding: padding,
                bearing: nil,
                pitch: nil
            )
            mapView.mapboxMap.setCamera(to: camera)
        }

        private func dot(color: UIColor) -> UIImage {
            let size = CGSize(width: 14, height: 14)
            return UIGraphicsImageRenderer(size: size).image { ctx in
                UIColor.white.setFill()
                ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
                color.setFill()
                ctx.cgContext.fillEllipse(in: CGRect(x: 2, y: 2, width: 10, height: 10))
            }
        }
    }
}

// MARK: - Preview

// Mapbox renders blank in Xcode canvas (requires a real device/simulator run).
// This stub shows the layout placeholder.
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        Text("Map renders on device")
            .foregroundStyle(.white.opacity(0.6))
            .font(.caption)
    }
    .ignoresSafeArea()
}
