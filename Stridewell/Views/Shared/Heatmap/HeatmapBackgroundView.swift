import SwiftUI

/// Renders the user's personal run heatmap as a full-screen background layer.
/// Falls back to a dark gradient for new users or on any error — never shows error UI.
struct HeatmapBackgroundView: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.locationStore) private var locationStore
    let userId: String

    @State private var viewModel: HeatmapViewModel?
    /// Prevents double-render when the 1.5s poll captures the location before .onChange fires.
    @State private var locationFired = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if let viewModel {
                    contentView(for: viewModel.state)
                        .animation(.easeIn(duration: 0.4), value: isReady(viewModel.state))
                }
            }
            .task {
                let vm = HeatmapViewModel(apiClient: apiClient)
                vm.targetSize = geo.size
                viewModel = vm

                // Request location permission + one-shot fix
                locationStore.requestLocation()

                // If no cached coordinate, poll up to 1.5 s for the OS location response.
                // Users with a cached location (2nd+ launch) exit immediately.
                if locationStore.coordinate == nil {
                    for _ in 0..<15 {
                        try? await Task.sleep(for: .milliseconds(100))
                        if locationStore.coordinate != nil { break }
                    }
                }

                let coord = locationStore.coordinate
                locationFired = coord != nil
                vm.load(userId: userId, userLocation: coord)
            }
            .onChange(of: locationStore.didReceiveLocation) { _, received in
                guard received, !locationFired, let vm = viewModel else { return }
                locationFired = true
                vm.invalidateAndRegenerate(userId: userId, userLocation: locationStore.coordinate)
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func contentView(for state: HeatmapState) -> some View {
        switch state {
        case .idle, .loading:
            Color.black.ignoresSafeArea()

        case .ready(let image):
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .overlay(Color.white.opacity(0.85))
                .transition(.opacity)

        case .insufficient, .error:
            LinearGradient(
                colors: [Color(hex: "#0D1117"), Color(hex: "#1A1F2E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private func isReady(_ state: HeatmapState) -> Bool {
        if case .ready = state { return true }
        return false
    }
}
