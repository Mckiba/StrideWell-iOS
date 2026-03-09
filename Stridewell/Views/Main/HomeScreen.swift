//
//  HomeScreen.swift
//  Stridewell
//
//  M7: Daily dashboard — today's workout, plan change detection,
//  reflection prompt, and recent activities.
//

import SwiftUI

struct HomeScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.planStore) private var planStore

    @State private var screenState: LoadableState<Void> = .loading
    @State private var retryTrigger = false
    @State private var recentRuns: [Run] = []
    @State private var showReflection = false
    @State private var showPlanChange = false

    var body: some View {
        ZStack {
            MapBackground()

            switch screenState {
            case .loading:
                LoadingStateView(message: "Loading your plan...")

            case .empty:
                EmptyStateView(
                    title: "No plan yet",
                    subtitle: "Complete onboarding to get your training plan."
                )

            case .error(let message):
                ErrorStateView(message: message) {
                    retryTrigger.toggle()
                }

            case .loaded:
                homeContent
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .task(id: retryTrigger) { await loadData() }
        .sheet(isPresented: $showReflection) { ReflectionScreen() }
        .navigationDestination(isPresented: $showPlanChange) { PlanChangeScreen() }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if planStore.isOffline {
                    OfflineBannerView(lastFetchDate: planStore.lastFetched(for: "today"))
                }
                todayWorkoutSection
                planChangeBannerSection
                reflectionPromptSection
                recentActivitiesSection
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .refreshable { await loadData() }
    }

    // MARK: - Section 1: Today's Workout

    private var todayWorkoutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Today")
                .font(.sectionTitle)

            if let day = planStore.todayPlanDay {
                CardView(padding: 0) {
                    WorkoutCardView(day: day, isToday: true)
                }
            } else {
                CardView {
                    Text("No workout scheduled")
                        .font(.cardBody)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, Spacing.sm)
                }
            }
        }
    }

    // MARK: - Section 2: Plan Change Banner

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

    // MARK: - Section 3: Reflection Prompt

    private var reflectionPromptSection: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Daily check-in")
                        .font(.cardTitle)
                    Text("How are you feeling today?")
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { showReflection = true }
    }

    // MARK: - Section 4: Recent Activities

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Recent activities")
                    .font(.sectionTitle)
                Spacer()
                Button("See all") {
                    // Future: Navigate to full activity list
                }
                .font(.cardCaption)
            }

            if recentRuns.isEmpty {
                CardView {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 28))
                            .foregroundStyle(.tertiary)
                        Text("No recent activities")
                            .font(.cardBody)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                }
            } else {
                CardView(padding: Spacing.sm) {
                    VStack(spacing: 0) {
                        ForEach(Array(recentRuns.enumerated()), id: \.element.id) { index, run in
                            runRow(run)
                            if index < recentRuns.count - 1 {
                                Divider().padding(.horizontal, Spacing.sm)
                            }
                        }
                    }
                }
            }
        }
    }

    private func runRow(_ run: Run) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(run.sport_type.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.cardTitle)
                Text(Self.formatRunDate(run.start_time))
                    .font(.cardCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(FormatUtils.distance(run.distance_m))
                    .font(.cardBody)
                if let pace = run.avg_pace_s_per_km {
                    Text(FormatUtils.pace(pace))
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
    }

    private static func formatRunDate(_ isoString: String) -> String {
        DateUtils.displayDate(isoString)
    }

    // MARK: - Data Loading

    private func loadData() async {
        if case .loaded = screenState {
            // Already loaded — pull-to-refresh, skip loading spinner
        } else {
            screenState = .loading
        }

        // Fetch today, week, and recent runs in parallel
        async let todayResult = apiClient.planToday()
        async let weekResult = apiClient.planWeek(start: currentWeekStart)
        async let runsResult = apiClient.recentRuns()

        let today: ApiResult<PlanDay> = await todayResult
        let week: ApiResult<PlanWeekResponse> = await weekResult
        let runs: ApiResult<RecentRunsResponse> = await runsResult

        switch today {
        case .success(let day):
            planStore.setTodayPlanDay(day)
        case .failure(let status, let message):
            if status == 404 {
                screenState = .empty
                return
            }
            // Serve persistent cache when network is unavailable
            guard planStore.serveCachedTodayOffline() != nil else {
                screenState = .error(message)
                return
            }
            // Cache served — fall through to populate week/runs and show content
        }

        // Week fetch is non-fatal — plan change detection won't work without it
        // but today's workout still shows.
        if case .success(let weekData) = week {
            planStore.setWeekData(weekData)
        }

        // Runs fetch is non-fatal — empty state shown if it fails
        if case .success(let runsData) = runs {
            recentRuns = runsData.runs
        }

        screenState = .loaded
    }

    // MARK: - Date Helpers

    private var currentWeekStart: String {
        DateUtils.mondayString(containing: Date())
    }
}
