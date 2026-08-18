//
//  SettingsDebugSection.swift
//  Stridewell
//
//  DEBUG-only developer controls. 
//

#if DEBUG
import SwiftUI

struct SettingsDebugSection: View {

    /// Forces weather-card fetches to use a preset location with active weather,
    /// so card rendering can be exercised from anywhere.
    @Binding var weatherCardsLocation: HomeCardsStore.DebugLocation

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Developer")
                .font(.sectionTitle)

            CardView {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Weather Cards Location")
                            .font(.cardTitle)
                        Text("Force a test location for /home/cards")
                            .font(.cardCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Weather Cards Location", selection: $weatherCardsLocation) {
                        ForEach(HomeCardsStore.DebugLocation.allCases) { loc in
                            Text(loc.label).tag(loc)
                        }
                    }
                    .pickerStyle(.menu)
                    .fixedSize()
                }
                .padding(.vertical, Spacing.sm)
            }
        }
    }
}

#Preview {
    SettingsDebugSection(weatherCardsLocation: .constant(.off))
        .padding()
}
#endif
