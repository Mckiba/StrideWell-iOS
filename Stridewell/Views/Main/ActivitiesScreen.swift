//
//  ActivitiesScreen.swift
//  Stridewell
//
//  Activities overview: range picker, period dropdown, period totals, a volume
//  chart, and the period's activities grouped by date. The full searchable list
//  lives in AllActivitiesScreen under the Search tab.
//

import SwiftUI

struct ActivitiesScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.activitySummaryStore) private var store
    @Environment(\.authStore) private var authStore
    @Environment(\.weatherStore) private var weatherStore
    @Environment(\.connectivityStore) private var connectivityStore
    @Environment(\.settingsStore) private var settingsStore

    @State private var selectedRun: Run? = nil

    // MARK: - Body

    var body: some View {
        ZStack {
            HeatmapBackgroundView(userId: authStore.userId ?? "")
            StormOverlayView(condition: weatherStore.activeCondition)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            contentLayer
        }
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(item: $selectedRun) { run in
            RunDetailScreen(run: run)
        }
        .task(id: store.selectionKey) {
            await store.load(apiClient: apiClient)
        }
    }

    // MARK: - Content Layer

    private var contentLayer: some View {
        Group {
            switch store.state {
            case .loading:
                ActivitiesOverviewSkeleton()

            case .empty:
                EmptyStateView(
                    title: "No activities yet",
                    subtitle: "Sync a run from Strava to see it here."
                )

            case .error(let message):
                ErrorStateView(message: message) {
                    Task { await store.load(apiClient: apiClient, force: true) }
                }

            case .loaded:
                overview
            }
        }
    }

    // MARK: - Overview

    private var overview: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xl2) {
                if connectivityStore.isOffline {
                    OfflineBannerView(lastFetchDate: nil)
                }

                ActivityRangePicker(selection: Binding(
                    get: { store.range },
                    set: { store.select(range: $0) }
                ))

                if let summary = store.summary {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        periodMenu
                        heroDistance(summary.totals.distance_m)
                        ActivityStatsRow(totals: summary.totals)
                    }
                    .opacity(store.isLoadingSummary ? 0.5 : 1)

                    ActivityVolumeChart(
                        range: ActivityRange(rawValue: summary.range) ?? store.range,
                        buckets: summary.buckets,
                        loadRun: { bucket in await store.run(for: bucket, apiClient: apiClient) },
                        onOpenRun: { selectedRun = $0 }
                    )
                    .opacity(store.isLoadingSummary ? 0.5 : 1)
                }

                activityList
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .refreshable {
            await store.load(apiClient: apiClient, force: true)
        }
    }

    // MARK: - Period Dropdown

    @ViewBuilder
    private var periodMenu: some View {
        let label = DateUtils.periodLabel(for: store.range, start: store.periodStart)
        if store.range == .all {
            periodLabel(label, showsChevron: false)
        } else {
            Menu {
                Picker("Period", selection: Binding(
                    get: { store.periodStart },
                    set: { store.select(periodStart: $0) }
                )) {
                    ForEach(store.periodStarts, id: \.self) { start in
                        Text(DateUtils.periodLabel(for: store.range, start: start)).tag(start)
                    }
                }
            } label: {
                periodLabel(label, showsChevron: true)
            }
        }
    }

    private func periodLabel(_ text: String, showsChevron: Bool) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(text)
                .font(.activityPeriodLabel)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .foregroundStyle(AppColor.textPrimary)
    }

    // MARK: - Hero Distance

    private func heroDistance(_ metres: Double) -> some View {
        let unit = settingsStore.unitSystem
        return VStack(alignment: .leading, spacing: 0) {
            Text(String(format: "%.1f", FormatUtils.distanceValue(metres, unit: unit)))
                .font(.activityHeroValue)
                .foregroundStyle(AppColor.textPrimary)
            Text(FormatUtils.distanceUnitName(unit))
                .font(.activityHeroUnit)
                .foregroundStyle(AppColor.textPrimary)
        }
    }

    // MARK: - Activity List

    @ViewBuilder
    private var activityList: some View {
        let sections = store.sections()
        if sections.isEmpty {
            if store.isLoadingRuns {
                ActivityListSkeleton()
            } else {
                Text("No runs in this period")
                    .font(.activitySectionTitle)
                    .foregroundStyle(AppColor.textSecondary)
            }
        } else {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(section.title)
                        .font(.activitySectionTitle)
                        .foregroundStyle(AppColor.textSecondary)
                    ForEach(section.runs) { run in
                        card(for: run)
                    }
                }
            }

            // Scroll sentinel — loads the next page when the user reaches the bottom.
            if store.hasMore {
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        Task { await store.loadMore(apiClient: apiClient) }
                    }

                if store.isLoadingMore {
                    ActivityListSkeleton(cardCount: 1, showsHeader: false)
                }
            }
        }
    }

    @ViewBuilder
    private func card(for run: Run) -> some View {
        if let day = store.planDaysByRunId[run.id] {
            WorkoutCard(day: day)
                .onTapGesture { selectedRun = run }
        } else {
            ActivityCard(run: run)
                .onTapGesture { selectedRun = run }
        }
    }
}
