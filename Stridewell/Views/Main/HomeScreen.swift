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
    @Environment(\.authStore) private var authStore
    @Environment(\.weatherStore) private var weatherStore

    @State private var screenState: LoadableState<Void> = .loading
    @State private var retryTrigger = false
    @State private var recentRuns: [Run] = []
    @State private var showReflection = false
    @State private var showPlanChange = false
    
    var body: some View {
        ZStack(alignment: .center) {
            HeatmapBackgroundView(userId: authStore.userId ?? "")
            StormOverlayView(condition: weatherStore.activeCondition)
                .ignoresSafeArea()
                .allowsHitTesting(false)

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
        .task(id: retryTrigger) {
            weatherStore.fetchIfNeeded()
            await loadData()
        }
        .sheet(isPresented: $showReflection) { ReflectionScreen() }
        .navigationDestination(isPresented: $showPlanChange) { PlanChangeScreen() }
    }
    
    // MARK: - Home Content
    
    private var homeContent: some View {
        ScrollView {
            VStack(alignment: .center, spacing: Spacing.md) {
                if planStore.isOffline {
                    OfflineBannerView(lastFetchDate: planStore.lastFetched(for: "today"))
                }
                goalSection
                planChangeBannerSection
                reflectionPromptSection
                todayWorkoutSection
                recentActivitiesSection
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .refreshable { await loadData() }
    }
    
    // MARK: - Section 1: Today / Next Workout
    
    private var todayWorkoutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let (title, day) = nextDisplayedWorkout {
                Text(title)
                    .font(.sectionTitle)
                ActivityBannerView(
                    title1:   day.workout.label,
                    detail:   DateUtils.planDayDate(day.date),
                    workout:  day.workout,
                    subtitle: day.workout.description,
                    image:    Image("bg2")
                )
            }
        }
    }
    
    /// Returns the label + day to feature at the top of the home screen.
    /// Shows "Today" if today is a real workout; otherwise finds the next
    /// non-rest day from the current (or cached next) week.
    private var nextDisplayedWorkout: (String, PlanDay)? {
        let todayString = DateUtils.format(Date())
        
        // Today is a real workout — show it
        if let today = planStore.todayPlanDay,
           today.workout.type != .rest,
           today.workout.type != .recovery {
            return ("Today", today)
        }
        
        // Rest day or missing today — find next upcoming workout this week
        let thisWeekDays = planStore.currentWeek?.days ?? []
        if let next = thisWeekDays.first(where: {
            $0.date > todayString &&
            $0.workout.type != .rest &&
            $0.workout.type != .recovery
        }) {
            return ("Next Workout", next)
        }
        
        // Nothing left this week — check next week from cache
        let nextMondayStr = DateUtils.format(DateUtils.nextMonday(from: DateUtils.mondayOfWeek(containing: Date())))
        if let nextWeek = planStore.cachedWeek(for: nextMondayStr),
           let next = nextWeek.days.first(where: {
               $0.workout.type != .rest && $0.workout.type != .recovery
           }) {
            return ("Next Workout", next)
        }
        
        return nil
    }
    
    // MARK: - Section 2: Goal Card
    
    @ViewBuilder
    private var goalSection: some View {
        if let summary = planStore.goalSummary {
            GoalCardView(summary: summary)
        }
    }
    
    // MARK: - Section 3: Plan Change Banner
    
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
        ActivityBannerView(
            title1:   "Time to check In!",
            subtitle: "Lets check in to see how you're doing",
            image: Image("bg1")
            
        )
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
                Button("View all") {
                    NotificationCenter.default.post(name: .switchToActivities, object: nil)
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
                VStack(spacing: Spacing.sm) {
                    ForEach(recentRuns) { run in
                        ActivityCard(run: run)
                    }
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        if case .loaded = screenState {
            // Already loaded — pull-to-refresh, skip loading spinner
        } else {
            screenState = .loading
        }
        
        // Fetch today, week, recent runs, and goal summary in parallel
        async let todayResult = apiClient.planToday()
        async let weekResult = apiClient.planWeek(start: currentWeekStart)
        async let runsResult = apiClient.recentRuns()
        async let goalResult = apiClient.goalSummary()
        
        let today: ApiResult<PlanDay> = await todayResult
        let week: ApiResult<PlanWeekResponse> = await weekResult
        let runs: ApiResult<RecentRunsResponse> = await runsResult
        let goal: ApiResult<GoalSummary> = await goalResult
        
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
        
        // Goal summary is non-fatal — card simply doesn't render on 404 or error
        if case .success(let goalData) = goal {
            planStore.setGoalSummary(goalData)
        }
        
        screenState = .loaded
    }
    
    // MARK: - Date Helpers

    private var currentWeekStart: String {
        DateUtils.mondayString(containing: Date())
    }

}
