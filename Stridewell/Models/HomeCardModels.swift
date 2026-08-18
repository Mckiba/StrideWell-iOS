//
//  HomeCardModels.swift
//  Stridewell
//
//  Weather cards from GET /home/cards. Content is generated entirely on the
//  backend, pre-sorted by priority; the client renders it verbatim.
//

import Foundation

struct HomeCard: Codable, Identifiable {
    let type: String
    let severity: String
    let priority: Int
    let icon: String
    let title: String
    let subtitle: String?
    let deep_link: String?
    let external_id: String?
    let details_url: String?
    let expires_at: String?

    /// Stable identity for the carousel: alert id when present, else type+title.
    var id: String { external_id ?? "\(type)-\(title)" }
}

struct HomeCardAttribution: Codable {
    let provider: String
    let url: String
}

struct HomeCardsResponse: Codable {
    let cards: [HomeCard]
    let attribution: HomeCardAttribution
}
