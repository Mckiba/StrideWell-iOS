//
//  PlanScreen.swift
//  Stridewell
//
//  M8: Full training plan with week navigation, day detail sheet,
//  and in-memory caching for instant adjacent-week navigation.
//

import SwiftUI

struct PlanScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.planStore) private var planStore
    @Environment(\.authStore) private var authStore
    @Environment(\.settingsStore) private var settingsStore
    @Environment(\.connectivityStore) private var connectivityStore

    @State private var screenState: LoadableState<Void> = .loading
    @State private var retryTrigger = false
    @State private var selectedMonday: Date = DateUtils.mondayOfWeek(containing: Date())
    @State private var displayedWeek: PlanWeekResponse? = nil
    @State private var weekRuns: [Run] = []
    @State private var selectedDay: PlanDay? = nil
    @State private var selectedRun: Run? = nil
    @State private var showPlanChange = false

    var body: some View {
        ZStack {
            HeatmapBackgroundView(userId: authStore.userId ?? "")

            switch screenState {
            case .loading:
                // Keep the chevrons live so an uncached week is not a dead end
                // while its fetch is in flight.
                VStack(spacing: Spacing.md) {
                    weekNavigator
                    PlanScreenSkeleton()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

            case .empty:
                VStack(spacing: Spacing.md) {
                    weekNavigator
                    Spacer()
                    EmptyStateView(
                        title: "No workouts this week",
                        subtitle: "Your plan doesn't cover this date range."
                    )
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

            case .error(let message):
                ErrorStateView(message: message) {
                    retryTrigger.toggle()
                }

            case .loaded:
                planContent
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .task(id: retryTrigger) { await loadWeek(for: selectedMonday) }
        .sheet(item: $selectedDay) { day in
            WorkoutDetailSheet(day: day)
        }
        .fullScreenCover(item: $selectedRun) { run in
            RunDetailScreen(run: run)
        }
        .navigationDestination(isPresented: $showPlanChange) { PlanChangeScreen() }
        .onReceive(NotificationCenter.default.publisher(for: .openPlanChange)) { _ in
            showPlanChange = true
        }
    }

    // MARK: - Plan Content

    private var planContent: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if connectivityStore.isOffline {
                    OfflineBannerView(
                        lastFetchDate: planStore.lastFetched(for: DateUtils.format(selectedMonday))
                    )
                }
                planChangeBannerSection
                weekNavigator
                WeekOverviewCard(
                    days: displayedWeek?.days ?? [],
                    weekRuns: weekRuns,
                    monday: selectedMonday,
                    unit: settingsStore.unitSystem
                )
                weekDaysList
                metadataSection
                weeklySummaryLink
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .refreshable { await loadWeek(for: selectedMonday, forceRefresh: true) }
    }

    // MARK: - Plan Change Banner

    @ViewBuilder
    private var planChangeBannerSection: some View {
        if planStore.hasPlanChanged {
            CardView {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Your plan was updated")
                            .font(.cardTitle)
                        Text("Tap to see what changed")
                            .font(.cardCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { showPlanChange = true }
        }
    }

    // MARK: - Week Navigator

    private var weekNavigator: some View {
        HStack {
            Button {
                navigateWeek(direction: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }

            Spacer()

            Text(DateUtils.weekRangeLabel(monday: selectedMonday))
                .font(.sectionTitle)

            Spacer()

            Button {
                navigateWeek(direction: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
            }
        }
        .padding(.horizontal, Spacing.sm)
    }

    // MARK: - 7-Day List

    private var weekDaysList: some View {
        let days = displayedWeek?.days ?? []
        let todayString = DateUtils.format(Date())

        return Group {
            if days.isEmpty {
                CardView {
                    Text("No workouts scheduled")
                        .font(.cardBody)
                        .foregroundStyle(.secondary)
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(days) { day in
                        WorkoutCard(day: day, isToday: day.date == todayString)
                            .onTapGesture {
                                if (day.status == .completed || day.status == .modified),
                                   let run = day.linkedRun {
                                    selectedRun = run
                                } else {
                                    selectedDay = day
                                }
                            }
                    }
                }
            }
        }
    }

    // MARK: - Metadata (phase label, coaching notes)

    @ViewBuilder
    private var metadataSection: some View {
        if let week = displayedWeek,
           (week.phase_label != nil || week.coaching_notes != nil) {
            CardView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    if let label = week.phase_label {
                        Text(label.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                    if let notes = week.coaching_notes {
                        Text(notes)
                            .font(.cardBody)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Weekly Summary Link

    private var weeklySummaryLink: some View {
        NavigationLink {
            WeeklySummaryScreen(monday: selectedMonday)
        } label: {
            CardView {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Weekly Summary")
                            .font(.cardTitle)
                            .foregroundStyle(.primary)
                        Text("Volume, compliance, long run, quality sessions")
                            .font(.cardCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Week Navigation

    private func navigateWeek(direction: Int) {
        let newMonday = (direction < 0)
            ? DateUtils.previousMonday(from: selectedMonday)
            : DateUtils.nextMonday(from: selectedMonday)
        selectedMonday = newMonday
        weekRuns = []
        Task { await loadWeek(for: newMonday) }
    }

    // MARK: - Data Loading

    /// Renders the cached week immediately so navigation stays instant, then
    /// always revalidates against /plan/week. Without the revalidation a week
    /// prefetched earlier renders forever — stale statuses, stale replan content.
    private func loadWeek(for monday: Date, forceRefresh: Bool = false) async {
        let startDate = DateUtils.format(monday)

        // Fetch synced runs for this week in parallel with the plan data.
        async let runsResult = apiClient.runsForWeek(monday: monday)

        let cached = planStore.cachedWeek(for: startDate)
        if let cached, !forceRefresh {
            displayedWeek = cached
            screenState = cached.days.isEmpty ? .empty : .loaded
        } else if cached == nil {
            // Nothing cached for this week: clear rather than leave the previous
            // week's days rendering under the new date range.
            displayedWeek = nil
            screenState = .loading
        }

        let result = await apiClient.planWeek(start: startDate)

        // Resolve runs fetch alongside plan result
        if case .success(let r) = await runsResult, isCurrent(startDate) {
            weekRuns = r.runs
        }

        // The user may have navigated on while this was in flight.
        guard isCurrent(startDate) else { return }

        switch result {
        case .success(let week):
            planStore.cacheWeek(week)
            displayedWeek = week
            screenState = week.days.isEmpty ? .empty : .loaded
            await prefetchAdjacentWeeks(around: monday)

        case .failure(let status, let message):
            // A failed revalidation must not blank a week already on screen.
            if displayedWeek != nil { return }

            if status == 404 {
                screenState = .empty
            } else if let offline = planStore.serveCachedWeekOffline(for: startDate) {
                // Serve persistent cache when network is unavailable
                displayedWeek = offline
                screenState = offline.days.isEmpty ? .empty : .loaded
            } else {
                screenState = .error(message)
            }
        }
    }

    /// True while `startDate` is still the week the user is looking at. Guards
    /// every write so a slow response cannot clobber a week navigated to since.
    private func isCurrent(_ startDate: String) -> Bool {
        DateUtils.format(selectedMonday) == startDate
    }

    /// Prefetch previous and next week in parallel if not already cached.
    private func prefetchAdjacentWeeks(around monday: Date) async {
        let prevKey = DateUtils.format(DateUtils.previousMonday(from: monday))
        let nextKey = DateUtils.format(DateUtils.nextMonday(from: monday))

        async let prevFetch: Void = prefetchIfNeeded(startDate: prevKey)
        async let nextFetch: Void = prefetchIfNeeded(startDate: nextKey)
        _ = await (prevFetch, nextFetch)
    }

    private func prefetchIfNeeded(startDate: String) async {
        guard planStore.cachedWeek(for: startDate) == nil else { return }
        guard planStore.beginWeekFetch(startDate) else { return }
        defer { planStore.endWeekFetch(startDate) }

        if case .success(let week) = await apiClient.planWeek(start: startDate) {
            planStore.cacheWeek(week)
        }
    }
}
