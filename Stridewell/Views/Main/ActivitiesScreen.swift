//
//  ActivitiesScreen.swift
//  Stridewell
//
//  Paginated activity list with a liquid glass search bar and date filter chip.
//  Search and date filtering are server-side — results always cover the full dataset.
//  New pages load automatically as the user scrolls to the bottom.
//

import SwiftUI

struct ActivitiesScreen: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(\.activitiesStore) private var activitiesStore
    @Environment(\.authStore) private var authStore
    @Environment(\.weatherStore) private var weatherStore

    @State private var searchText = ""
    @State private var selectedDate: Date? = nil
    @State private var showDatePicker = false
    @State private var searchDebounce: Task<Void, Never>? = nil

    // MARK: - Body

    var body: some View {
        ZStack {
            HeatmapBackgroundView(userId: authStore.userId ?? "")
            StormOverlayView(condition: weatherStore.activeCondition)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            contentLayer
        }
        .navigationTitle("Activities")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search activities")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                dateFilterChip
            }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .task {
            if case .loading = activitiesStore.state {
                await activitiesStore.refresh(search: "", date: nil, apiClient: apiClient)
            }
        }
        .refreshable {
            await activitiesStore.refresh(search: searchText, date: selectedDate, apiClient: apiClient)
        }
        .onChange(of: searchText) { _, newValue in
            // Debounce: wait 350 ms after the user stops typing before hitting the server.
            searchDebounce?.cancel()
            searchDebounce = Task {
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                await activitiesStore.refresh(search: newValue, date: selectedDate, apiClient: apiClient)
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            Task { await activitiesStore.refresh(search: searchText, date: newDate, apiClient: apiClient) }
        }
    }

    // MARK: - Content Layer

    private var contentLayer: some View {
        Group {
            switch activitiesStore.state {
            case .loading:
                LoadingStateView(message: "Loading activities...")

            case .empty:
                EmptyStateView(
                    title: "No activities yet",
                    subtitle: "Sync a run from Strava to see it here."
                )

            case .error(let message):
                ErrorStateView(message: message) {
                    Task { await activitiesStore.refresh(search: searchText, date: selectedDate, apiClient: apiClient) }
                }

            case .loaded:
                activityList
            }
        }
    }

    // MARK: - Activity List

    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                if activitiesStore.runs.isEmpty {
                    noResultsView
                } else {
                    ForEach(activitiesStore.runs) { run in
                        ActivityCard(run: run)
                            .padding(.horizontal, Spacing.md)
                    }

                    // Scroll sentinel — becomes visible when the user reaches the bottom.
                    // Triggers the next page fetch; hidden once there are no more pages.
                    if activitiesStore.hasMore {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                Task {
                                    await activitiesStore.loadMore(
                                        search: searchText,
                                        date: selectedDate,
                                        apiClient: apiClient
                                    )
                                }
                            }

                        if activitiesStore.isLoadingMore {
                            ProgressView()
                                .padding(.vertical, Spacing.sm)
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    private var noResultsView: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No activities found")
                .font(.cardTitle)
                .foregroundStyle(.secondary)
            Text("Try a different search or date.")
                .font(.cardBody)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xl)
    }

    // MARK: - Date Filter Chip

    private static let chipDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private var dateFilterChip: some View {
        Button {
            showDatePicker = true
        } label: {
            HStack(spacing: 4) {
                if let date = selectedDate {
                    Text(Self.chipDateFormatter.string(from: date))
                        .font(.caption.weight(.medium))
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .onTapGesture { selectedDate = nil }
                } else {
                    Text("All dates")
                        .font(.caption.weight(.medium))
                    Image(systemName: "calendar")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Picker Sheet

    private var datePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select date",
                    selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: { selectedDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                Spacer()
            }
            .navigationTitle("Filter by date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        selectedDate = nil
                        showDatePicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
