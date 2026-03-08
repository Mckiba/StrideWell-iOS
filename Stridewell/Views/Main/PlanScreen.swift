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

    @State private var screenState: LoadableState<Void> = .loading
    @State private var retryTrigger = false
    @State private var selectedMonday: Date = DateUtils.mondayOfWeek(containing: Date())
    @State private var displayedWeek: PlanWeekResponse? = nil
    @State private var selectedDay: PlanDay? = nil
    @State private var showPlanChange = false

    var body: some View {
        ZStack {
            MapBackground()

            switch screenState {
            case .loading:
                LoadingStateView(message: "Loading your plan...")

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
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.large)
        .task(id: retryTrigger) { await loadWeek(for: selectedMonday) }
        .sheet(item: $selectedDay) { day in
            WorkoutDetailSheet(day: day)
        }
        .navigationDestination(isPresented: $showPlanChange) { PlanChangeScreen() }
    }

    // MARK: - Plan Content

    private var planContent: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                planChangeBannerSection
                weekNavigator
                weekDaysList
                metadataSection
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

        return CardView(padding: 0) {
            if days.isEmpty {
                Text("No workouts scheduled")
                    .font(.cardBody)
                    .foregroundStyle(.secondary)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        WorkoutCardView(day: day, isToday: day.date == todayString)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDay = day
                            }
                        if index < days.count - 1 {
                            Divider().padding(.leading, 68)
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

    // MARK: - Week Navigation

    private func navigateWeek(direction: Int) {
        let newMonday = (direction < 0)
            ? DateUtils.previousMonday(from: selectedMonday)
            : DateUtils.nextMonday(from: selectedMonday)
        selectedMonday = newMonday
        Task { await loadWeek(for: newMonday) }
    }

    // MARK: - Data Loading

    private func loadWeek(for monday: Date, forceRefresh: Bool = false) async {
        let startDate = DateUtils.format(monday)

        // Check cache first (unless force-refreshing)
        if !forceRefresh, let cached = planStore.cachedWeek(for: startDate) {
            displayedWeek = cached
            screenState = cached.days.isEmpty ? .empty : .loaded
            await prefetchAdjacentWeeks(around: monday)
            return
        }

        // Show loading only if nothing is displayed yet
        if displayedWeek == nil {
            screenState = .loading
        }

        let result = await apiClient.planWeek(start: startDate)

        switch result {
        case .success(let week):
            planStore.cacheWeek(week)
            displayedWeek = week
            screenState = week.days.isEmpty ? .empty : .loaded
            await prefetchAdjacentWeeks(around: monday)

        case .failure(let status, let message):
            if status == 404 {
                screenState = .empty
            } else {
                screenState = .error(message)
            }
        }
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
        if case .success(let week) = await apiClient.planWeek(start: startDate) {
            planStore.cacheWeek(week)
        }
    }
}
