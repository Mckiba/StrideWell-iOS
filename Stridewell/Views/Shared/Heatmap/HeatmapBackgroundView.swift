import SwiftUI

/// Renders the user's personal run heatmap as a full-screen background layer.
/// Falls back to a dark gradient for new users or on any error — never shows error UI.
///
/// Reads a shared HeatmapViewModel from the environment (injected at app startup).
/// All screens share the same instance so the rendered image is never re-generated
/// on tab switches — eliminating the black flash when navigating between tabs.
struct HeatmapBackgroundView: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.locationStore) private var locationStore
    @Environment(\.heatmapViewModel) private var sharedViewModel
    let userId: String

    /// Fallback for previews or contexts where no shared ViewModel is injected.
    @State private var localViewModel: HeatmapViewModel?
    @State private var locationFired = false

    /// The active ViewModel — shared takes priority, local is a safety fallback.
    private var viewModel: HeatmapViewModel? { sharedViewModel ?? localViewModel }

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
                let vm: HeatmapViewModel
                if let shared = sharedViewModel {
                    // Shared ViewModel already exists — update size, skip if already loaded
                    vm = shared
                    vm.targetSize = geo.size
                } else {
                    // No shared ViewModel injected (e.g. preview) — create a local one
                    let newVm = HeatmapViewModel(apiClient: apiClient)
                    newVm.targetSize = geo.size
                    localViewModel = newVm
                    vm = newVm
                }

                // Already loading or loaded by a previous screen — don't re-trigger
                guard case .idle = vm.state else { return }

                locationStore.requestLocation()

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
