//
//  OfflineBannerView.swift
//  Stridewell
//
//  Subtle offline indicator shown when plan data is served from cache.
//

import SwiftUI

struct OfflineBannerView: View {

    let lastFetchDate: Date?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "wifi.slash")
            Text(label)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, Spacing.xs)
    }

    /// Static formatter — created once, shared across all instances.
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private var label: String {
        guard let date = lastFetchDate else {
            return "Offline — using cached data"
        }
        return "Offline — cached \(Self.dateFormatter.string(from: date))"
    }
}
