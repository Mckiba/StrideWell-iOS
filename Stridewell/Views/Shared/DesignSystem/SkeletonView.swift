import SwiftUI

// MARK: - Generic Shimmer Primitive

struct SkeletonView<S: Shape>: View {
    var shape: S
    var color: Color
    init(_ shape: S, _ color: Color = .gray.opacity(0.3)) {
        self.shape = shape
        self.color = color
    }
    @State private var isAnimating: Bool = false
    var body: some View {
        shape
            .fill(color)
            .overlay {
                GeometryReader {
                    let size = $0.size
                    let skeletonWidth = size.width / 2
                    let blurRadius = max(skeletonWidth / 2, 30)
                    let blurDiameter = blurRadius * 2
                    let minX = -(skeletonWidth + blurDiameter)
                    let maxX = size.width + skeletonWidth + blurDiameter

                    Rectangle()
                        .fill(.gray)
                        .frame(width: skeletonWidth, height: size.height * 2)
                        .frame(height: size.height)
                        .blur(radius: blurRadius)
                        .rotationEffect(.init(degrees: rotation))
                        .blendMode(.softLight)
                        .offset(x: isAnimating ? maxX : minX)
                }
            }
            .clipShape(shape)
            .compositingGroup()
            .task { @MainActor in
                guard !isAnimating else { return }
                withAnimation(animation) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
            .transaction {
                if $0.animation != animation {
                    $0.animation = .none
                }
            }
    }

    var rotation: Double { 5 }

    var animation: Animation {
        .easeInOut(duration: 1.5).repeatForever(autoreverses: false)
    }
}

// MARK: - Convenience Block

/// Rounded-rectangle shimmer block — the most common skeleton primitive.
/// Defaults to a 6pt corner radius suitable for text-line placeholders.
struct SkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat
    var cornerRadius: CGFloat = 6

    var body: some View {
        SkeletonView(.rect(cornerRadius: cornerRadius))
            .frame(width: width, height: height)
    }
}

// MARK: - Map Area Skeleton

/// Shimmer covering only the visible map area above the bottom sheet
/// (top half of the screen at the mid detent). Sized so the shimmer
/// animation feels right rather than being hidden behind the sheet.
struct MapAreaSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            SkeletonView(.rect(cornerRadius: 0))
                .frame(height: UIScreen.main.bounds.height * 0.5)
            Spacer(minLength: 0)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Run Detail Skeletons

/// Mirrors RunDetailScreen's headerSection + splitsSection + statsSection layout
/// so the swap to real content doesn't shift the page.
struct RunDetailSheetSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            headerBlock
            Divider()
            splitsBlock
            Divider()
            statsBlock
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SkeletonBlock(height: 24, cornerRadius: 8)
                .frame(maxWidth: 220, alignment: .leading)
            SkeletonBlock(width: 140, height: 12)

            HStack {
                statPlaceholder
                Spacer()
                statPlaceholder
                Spacer()
                statPlaceholder
            }

            HStack {
                statPlaceholder
                Spacer()
                statPlaceholder
                Spacer()
                statPlaceholder
            }
        }
        .padding(Spacing.lg)
    }

    private var statPlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            SkeletonBlock(width: 64, height: 10)
            SkeletonBlock(width: 80, height: 18)
        }
    }

    private var splitsBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SkeletonBlock(width: 80, height: 18)
                .padding(.horizontal, Spacing.md)
            VStack(spacing: Spacing.xs) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonBlock(height: 32, cornerRadius: 8)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.md)
    }

    private var statsBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SkeletonBlock(width: 100, height: 18)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

            VStack(spacing: 10) {
                ForEach(0..<11, id: \.self) { _ in
                    HStack {
                        SkeletonBlock(width: 110, height: 14)
                        Spacer()
                        SkeletonBlock(width: 70, height: 14)
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.bottom, Spacing.sm)
        }
    }
}

/// Skeleton for the analysis section while it loads independently.
struct RunAnalysisSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SkeletonBlock(width: 160, height: 18)
            SkeletonBlock(height: 12)
            SkeletonBlock(height: 12)
                .frame(maxWidth: 260, alignment: .leading)
        }
    }
}

// MARK: - Home Screen Skeleton

/// Mirrors HomeScreen.homeContent layout: goal card, banner carousel,
/// today's workout, recent activities.
struct HomeScreenSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                goalCardBlock
                bannerCarouselBlock
                todayWorkoutBlock
                recentActivitiesBlock
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
    }

    private var goalCardBlock: some View {
        SkeletonBlock(height: 80, cornerRadius: CornerRadius.md)
    }

    private var bannerCarouselBlock: some View {
        SkeletonBlock(height: 140, cornerRadius: CornerRadius.lg)
    }

    private var todayWorkoutBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SkeletonBlock(width: 80, height: 18)
            SkeletonBlock(height: 110, cornerRadius: CornerRadius.md)
        }
    }

    private var recentActivitiesBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                SkeletonBlock(width: 140, height: 18)
                Spacer()
                SkeletonBlock(width: 60, height: 12)
            }
            VStack(spacing: Spacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonBlock(height: 70, cornerRadius: CornerRadius.md)
                }
            }
        }
    }
}

// MARK: - Plan Screen Skeleton

/// Mirrors PlanScreen.planContent layout: week navigator, week overview,
/// 7-day list, metadata, summary link.
struct PlanScreenSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                weekNavigatorBlock
                weekOverviewBlock
                weekDaysBlock
                metadataBlock
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .scrollDisabled(true)
    }

    private var weekNavigatorBlock: some View {
        HStack {
            SkeletonBlock(width: 32, height: 32, cornerRadius: 16)
            Spacer()
            SkeletonBlock(width: 160, height: 18)
            Spacer()
            SkeletonBlock(width: 32, height: 32, cornerRadius: 16)
        }
        .frame(height: 44)
    }

    private var weekOverviewBlock: some View {
        SkeletonBlock(height: 120, cornerRadius: CornerRadius.md)
    }

    private var weekDaysBlock: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(0..<7, id: \.self) { _ in
                SkeletonBlock(height: 84, cornerRadius: CornerRadius.md)
            }
        }
    }

    private var metadataBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SkeletonBlock(width: 140, height: 14)
            SkeletonBlock(height: 12)
            SkeletonBlock(height: 12)
                .frame(maxWidth: 240, alignment: .leading)
        }
    }
}

// MARK: - Activities Screen Skeleton

/// Mirrors ActivitiesScreen.activityList layout: a vertical list of
/// activity-card-shaped rows. Sized to fill the screen so the skeleton
/// extends past the visible viewport while loading.
struct ActivitiesScreenSkeleton: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(0..<10, id: \.self) { _ in
                    SkeletonBlock(height: 70, cornerRadius: CornerRadius.md)
                        .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .scrollDisabled(true)
    }
}

// MARK: - Preview

#Preview("Primitive") {
    VStack(alignment: .leading, spacing: Spacing.md) {
        SkeletonBlock(width: 200, height: 24, cornerRadius: 8)
        SkeletonBlock(height: 12)
        SkeletonBlock(height: 12)
        SkeletonView(.circle).frame(width: 44, height: 44)
    }
    .padding()
}

#Preview("Run Detail Sheet") {
    ScrollView { RunDetailSheetSkeleton() }
}

#Preview("Home") {
    HomeScreenSkeleton()
}

#Preview("Plan") {
    PlanScreenSkeleton()
}
