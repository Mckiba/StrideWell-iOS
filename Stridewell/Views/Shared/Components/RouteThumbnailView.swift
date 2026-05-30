//
//  RouteThumbnailView.swift
//  Stridewell
//
//  Small polyline preview shared by ActivityCard (35×37) and the Completed
//  variant of WorkoutCard (55×55). Decodes `run.route.summary_polyline`
//  asynchronously on .task and renders a stroked RoutePathShape; falls back
//  to a rounded placeholder while the decode is in flight or when no route
//  is present on the Run.
//

import SwiftUI
import CoreLocation

struct RouteThumbnailView: View {

    let run: Run
    var size: CGSize = CGSize(width: 35, height: 37)
    var lineWidth: CGFloat = 1.5

    @State private var routeCoordinates: [CLLocationCoordinate2D] = []

    var body: some View {
        Group {
            if routeCoordinates.count > 1 {
                RoutePathShape(coordinates: routeCoordinates)
                    .stroke(
                        AppColor.accent,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
            } else {
                // Placeholder shown while decoding or when no polyline is available.
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(AppColor.textTertiary, lineWidth: 1)
            }
        }
        .frame(width: size.width, height: size.height)
        .task {
            if let encoded = run.route?.summary_polyline, !encoded.isEmpty {
                routeCoordinates = await Task.detached(priority: .utility) {
                    await PolylineDecoder.decode(encoded)
                }.value
            }
        }
    }
}
