//
//  RunDetailScreen.swift
//  Stridewell
//
//  Full-bleed Mapbox map + three-detent draggable bottom sheet.
//  Sheet fills the full screen width with divider-based sections.
//

import SwiftUI
import CoreLocation

struct RunDetailScreen: View {

    private enum SheetDetent: CaseIterable {
        case small
        case mid
        case full
    }

    private static let detentSnapAnimation = Animation.spring(response: 0.34, dampingFraction: 0.86)

    let run: Run

    @Environment(\.apiClient)      private var apiClient
    @Environment(\.settingsStore)  private var settingsStore
    @Environment(\.dismiss)        private var dismiss

    @State private var detailState:    LoadableState<RunDetailResponse> = .loading
    @State private var analysisState:  LoadableState<RunAnalysisData>   = .loading
    @State private var analysisStatus: String?          = nil
    @State private var currentDetent:  SheetDetent = .mid
    @State private var sheetDragOffset: CGFloat = 0
    @State private var didAutoCollapseFromPull = false
    @State private var cityLabel:       String?          = nil

    // Overlay is visible only when the sheet is at mid detent.
    private var showOverlay: Bool {
        currentDetent == .mid
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                // Layer 1 — full-bleed map
                mapLayer

                // Layer 2 — navigation button
                closeButton

                // Layer 3 — custom edge-to-edge bottom sheet
                bottomSheet(totalHeight: UIScreen.main.bounds.height, safeBottom: proxy.safeAreaInsets.bottom)
            }
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.2), value: showOverlay)
        .onChange(of: currentDetent) { _, newDetent in
            if newDetent != .full {
                didAutoCollapseFromPull = false
            }
            if sheetDragOffset != 0 {
                sheetDragOffset = 0
            }
        }
        .task { await loadAll() }
    }

    // MARK: - Map Layer

    @ViewBuilder
    private var mapLayer: some View {
        if case .loaded(let detail) = detailState,
           let polyline = detail.run.route?.summary_polyline,
           !polyline.isEmpty {
            RouteMapView(
                coordinates: PolylineDecoder.decode(polyline),
                startLatLng: detail.run.start_latlng.map {
                    CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1])
                },
                bottomInset: mapBottomInset
            )
            .ignoresSafeArea()
        } else if case .loading = detailState {
            MapAreaSkeleton()
        } else {
            Color.black.ignoresSafeArea()
        }
    }



    // MARK: - Close Button

    private var closeButton: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.backward")
                        .font(.body.weight(.semibold))
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
            }
            .padding(.top, 56)
            .padding(.leading, Spacing.md)
            Spacer()
        }
    }

    // MARK: - Bottom Sheet

    private func bottomSheet(totalHeight: CGFloat, safeBottom: CGFloat) -> some View {
        let fullHeight = detentHeight(.full, totalHeight: totalHeight, safeBottom: safeBottom)
        let currentHeight = detentHeight(currentDetent, totalHeight: totalHeight, safeBottom: safeBottom)
        let minTop = totalHeight - fullHeight
        let maxTop = totalHeight - detentHeight(.small, totalHeight: totalHeight, safeBottom: safeBottom)
        let rawTop = totalHeight - currentHeight + sheetDragOffset
        let top = min(max(rawTop, minTop), maxTop)

        return VStack(spacing: 10) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xs)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())

            sheetContent
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: fullHeight, alignment: .top)
        .background(AppColor.surface)
        .contentShape(Rectangle())
        .gesture(
            currentDetent == .full
            ? nil
            : DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged { value in
                    sheetDragOffset = value.translation.height
                }
                .onEnded { value in
                    let projectedY = value.predictedEndTranslation.height
                    let targetDetent: SheetDetent
                    if projectedY < -20 {
                        targetDetent = oneStepUp(from: currentDetent)
                    } else if projectedY > 20 {
                        targetDetent = oneStepDown(from: currentDetent)
                    } else {
                        targetDetent = currentDetent
                    }
                    withAnimation(Self.detentSnapAnimation) {
                        currentDetent = targetDetent
                        sheetDragOffset = 0
                    }
                },
            including: .all
        )
        .clipped()
        .offset(y: top)
        .ignoresSafeArea(edges: .bottom)
    }

    private func detentHeight(_ detent: SheetDetent, totalHeight: CGFloat, safeBottom: CGFloat) -> CGFloat {
        switch detent {
        case .small:
            return 120 + safeBottom
        case .mid:
            return totalHeight * 0.5
        case .full:
            return totalHeight
        }
    }

    private func oneStepUp(from detent: SheetDetent) -> SheetDetent {
        switch detent {
        case .small: return .mid
        case .mid:   return .full
        case .full:  return .full
        }
    }

    private func oneStepDown(from detent: SheetDetent) -> SheetDetent {
        switch detent {
        case .full:  return .mid
        case .mid:   return .small
        case .small: return .small
        }
    }

    private func snap(to detent: SheetDetent) {
        guard detent != currentDetent else { return }
        withAnimation(Self.detentSnapAnimation) {
            currentDetent = detent
        }
    }

    // MARK: - Sheet Content

    private var sheetContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                switch detailState {
                case .loading:
                    RunDetailSheetSkeleton()

                case .error(let msg):
                    ErrorStateView(message: msg) { Task { await loadAll() } }
                        .frame(minHeight: 220)
                        .padding(Spacing.md)

                case .empty, .loaded:
                    if case .loaded(let detail) = detailState {
                        headerSection(detail.run)
                        divider
                        splitsSection(detail.splits)
                        divider
                        statsSection(detail.run)
                        divider
                        analysisSection
                        chartsSection(detail.streams)
                        Spacer(minLength: Spacing.xl)
                    }
                }
            }
        }
        .id(currentDetent == .full ? "run-detail-scroll-full" : "run-detail-scroll-collapsed")
        .scrollDisabled(currentDetent != .full)
        .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
            geometry.contentOffset.y
        }, action: { oldY, newY in
            guard currentDetent == .full else { return }

            // At full detent, pull-down past top collapses one step: full -> mid.
            if newY < -80, oldY >= -80, !didAutoCollapseFromPull {
                didAutoCollapseFromPull = true
                snap(to: .mid)
            }

            // Re-arm after the scroll settles near the top again.
            if newY > -20 {
                didAutoCollapseFromPull = false
            }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .scrollIndicators(.hidden)
    }

    private var divider: some View {
        Divider().padding(.horizontal, 0)
    }

    // MARK: - Header Section

    private func headerSection(_ run: RunDetail) -> some View {
        let unit = settingsStore.unitSystem
        return VStack(alignment: .leading, spacing: Spacing.md) {
            
            // Date · time
//            Text(DateUtils.activityDate(run.start_time) + "  ·  " + DateUtils.activityTime(run.start_time))
//                .font(.cardCaption)
//                .foregroundStyle(.secondary)

            // Title
            Text(run.title ?? run.sport_type.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.title3.bold())

            // City
            if let city = cityLabel {
                Text(city)
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
            }

            // Description
            if let desc = run.description, !desc.isEmpty {
                ExpandableText(text: desc, lineLimit: 3)
            }

            // Stats row 1
            HStack {
//                CardStat(label: "DISTANCE", value: FormatUtils.distance(run.distance_m, unit: unit))
//                Spacer()
                ActivityStat(label: "AVG PACE",  value: run.avg_pace_s_per_km.map { FormatUtils.pace($0, unit: unit) } ?? "—")
                Spacer()
                ActivityStat(label: "TIME",      value: FormatUtils.duration(run.duration_s))
                Spacer()
                ActivityStat(label: "CALORIES",  value: run.calories_kcal.map { "\($0) kcal" } ?? "—")
            }

            // Stats row 2
            HStack {
                ActivityStat(label: "ELEVATION", value: run.elevation_gain_m.map { String(format: "+%.0fm", $0) } ?? "—")
                Spacer()
                ActivityStat(label: "AVG HR",    value: run.avg_hr_bpm.map { "\($0) bpm" } ?? "—")
                Spacer()
//                CardStat(label: "MAX HR",    value: run.max_hr_bpm.map { "\($0) bpm" } ?? "—")
//                Spacer()
                ActivityStat(label: "CADENCE",   value: run.avg_cadence_spm.map { "\($0) spm" } ?? "—")
            }
        }
        .padding(Spacing.lg)
    }

    // MARK: - Splits Section

    private func splitsSection(_ splits: [RunSplit]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Splits")
                .font(.cardTitle)
                .padding(.horizontal, Spacing.md)
            SplitsTableView(splits: splits, unit: settingsStore.unitSystem)
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Stats Section

    private func statsSection(_ run: RunDetail) -> some View {
        let unit = settingsStore.unitSystem
        return VStack(alignment: .leading, spacing: 0) {
            Text("Details")
                .font(.cardTitle)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.sm)

            Group {
                statRow("Distance",       FormatUtils.distance(run.distance_m, unit: unit))
                statRow("Avg Pace",       run.avg_pace_s_per_km.map { FormatUtils.pace($0, unit: unit) } ?? "—")
                statRow("Fastest Pace",   run.best_pace_s_per_km.map { FormatUtils.pace($0, unit: unit) } ?? "—")
                statRow("Running Time",   FormatUtils.duration(run.duration_s))
                statRow("Elapsed Time",   run.elapsed_time_s.map { FormatUtils.duration($0) } ?? "—")
                statRow("Calories",       run.calories_kcal.map { "\($0) kcal" } ?? "—")
                statRow("Avg Cadence",    run.avg_cadence_spm.map { "\($0) spm" } ?? "—")
                statRow("Elevation Gain", run.elevation_gain_m.map { String(format: "+%.0f m", $0) } ?? "—")
                statRow("Elevation Loss", run.elevation_loss_m.map { String(format: "%.0f m", $0) } ?? "—")
                statRow("Avg HR",         run.avg_hr_bpm.map { "\($0) bpm" } ?? "—")
                statRow("Max HR",         run.max_hr_bpm.map { "\($0) bpm" } ?? "—")
            }
            .padding(.bottom, Spacing.sm)
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.cardBody)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.cardBody.weight(.semibold))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 6)
    }

    // MARK: - Analysis Section

    @ViewBuilder
    private var analysisSection: some View {
        switch analysisState {
        case .loading:
            RunAnalysisSkeleton()
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

        case .empty:
            EmptyStateView(
                title: "Analysis not ready",
                subtitle: "We're still processing this run."
            )
            .frame(height: 100)
            .padding(Spacing.md)

        case .error:
            EmptyView()

        case .loaded(let data):
            VStack(alignment: .leading, spacing: Spacing.md) {
                RunAnalysisSections(data: data, status: analysisStatus, unit: settingsStore.unitSystem)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
        }
    }

    // MARK: - Charts Section

    @ViewBuilder
    private func chartsSection(_ streams: RunStreams?) -> some View {
        if let streams {
            divider
            chartBlock(title: "Elevation", distances: streams.distance_m, values: streams.altitude_m, type: .elevation)
            divider
            chartBlock(title: "Heart Rate", distances: streams.distance_m, values: streams.heartrate, type: .heartRate)
            divider
            chartBlock(title: "Cadence", distances: streams.distance_m, values: streams.cadence, type: .cadence)
        }
    }

    private func chartBlock(title: String, distances: [Double], values: [Double]?, type: StreamChartType) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.cardTitle)
            RunStreamChart(distances: distances, values: values, type: type)
        }
        .padding(Spacing.md)
    }

    // MARK: - Data Loading

    private func loadAll() async {
        detailState   = .loading
        analysisState = .loading
        cityLabel     = nil

        async let detailResult   = apiClient.runDetail(runId: run.id)
        async let analysisResult = apiClient.runAnalysis(runId: run.id)
        let (detail, analysis)   = await (detailResult, analysisResult)

        switch detail {
        case .success(let r):
            detailState = .loaded(r)
            geocodeStart(r.run.start_latlng)
        case .failure(_, let msg):
            detailState = .error(msg)
        }

        switch analysis {
        case .success(let r):
            analysisStatus = r.status
            analysisState  = .loaded(r.analysisData)
        case .failure(let status, _):
            analysisState  = status == 404 ? .empty : .error("Analysis unavailable")
        }
    }

    private func geocodeStart(_ latlng: [Double]?) {
        guard let latlng, latlng.count >= 2 else { return }
        CLGeocoder().reverseGeocodeLocation(
            CLLocation(latitude: latlng[0], longitude: latlng[1])
        ) { placemarks, _ in
            let city = placemarks?.first?.locality ?? placemarks?.first?.administrativeArea
            Task { @MainActor in cityLabel = city }
        }
    }

    // MARK: - Camera Inset

    private var mapBottomInset: CGFloat {
        if currentDetent == .small {
            return 80
        } else if currentDetent == .mid {
            return UIScreen.main.bounds.height * 0.5
        } else {
            return 0
        }
    }
}

// MARK: - ExpandableText

private struct ExpandableText: View {
    let text: String
    let lineLimit: Int
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(text)
                .font(.cardBody)
                .foregroundStyle(.secondary)
                .lineLimit(expanded ? nil : lineLimit)

            if !expanded {
                Button("Show more") { expanded = true }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.accent)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RunDetailScreen(run: Run(
        id: "preview_run_001",
        provider: "strava",
        sport_type: "run",
        title: "CNW Track Workout",
        start_time: "2026-04-22T14:05:00Z",
        distance_m: 7242.0,
        duration_s: 2408,
        avg_pace_s_per_km: 332,
        elevation_gain_m: 9,
        route: nil
    ))
    .environment(\.apiClient, APIClient(tokenProvider: { nil }, onUnauthorized: {}))
    .environment(\.settingsStore, SettingsStore())
}
