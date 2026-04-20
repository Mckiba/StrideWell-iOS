import SwiftUI

/// Apple Weather attribution required by WeatherKit guideline 5.2.5.
/// Visible row in Settings with the Apple Weather trademark and legal link.
struct SettingsWeatherAttributionSection: View {

    private let legalURL = URL(string: "https://weatherkit.apple.com/legal-attribution.html")!

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Weather")
                .font(.sectionTitle)

            CardView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 15, weight: .medium))
                        Text("Weather")
                            .font(.cardTitle)
                    }

                    Text("Weather data is provided by  Weather and other sources.")
                        .font(.cardCaption)
                        .foregroundStyle(.secondary)

                    Link(destination: legalURL) {
                        HStack(spacing: 4) {
                            Text("Other data sources")
                                .font(.cardCaption)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.xs)
            }
        }
    }
}

#Preview {
    SettingsWeatherAttributionSection()
        .padding()
}
