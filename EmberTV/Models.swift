//
//  Untitled.swift
//  EmberTV
//
//  Created by Brandon Duncan on 11/26/25.
//

import Foundation

struct AuthResponse: Decodable {
    let token: String
    let user: User
}

struct User: Decodable {
    let id: Int
    let email: String
    let name: String?
}

struct Film: Identifiable, Decodable, Hashable {
    let id: Int
    let slug: String
    let title: String
    let description: String
    let genre: String?
    let runtimeMinutes: Int?
    let posterURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, slug, title, description, genre
        case runtimeMinutes = "runtime_minutes"
        case posterURL = "poster_url"
    }
}

struct PaginatedFilmsResponse: Decodable {
    let data: [Film]
    // meta if you need it
}

struct RentalFilmSummary: Decodable, Hashable {
    let id: String
    let slug: String?
    let title: String
    let posterURL: URL?
    let hlsURL: URL?

    // New fields (must be added to the /apiMyRentals film payload)
    let longDescription: String?
    let durationMinutes: Int?
    let genre: String?

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case title
        case posterURL = "poster_url"
        case hlsURL = "hls_url"
        case longDescription = "long_description"
        case durationMinutes = "duration_minutes"
        case genre
    }
}


struct Rental: Decodable, Hashable {
    let film: RentalFilmSummary

    // Optional – if/when you add them back to the API, they’ll start filling in
    let status: String?
    let purchasedAt: Date?
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case film
        case status
        case purchasedAt = "purchased_at"
        case expiresAt = "expires_at"
    }

    /// Convenience so the rest of the UI can still ask for `filmID`
    var filmID: String { film.id }
}

struct RentalsResponse: Decodable {
    let data: [Rental]
}

struct EntitlementResponse: Decodable {
    let hasAccess: Bool
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case hasAccess = "has_access"
        case expiresAt = "expires_at"
    }
}

struct PlaybackResponse: Decodable {
    let hasAccess: Bool
    let playbackURL: URL?     // legacy / fallback URL
    let hlsURL: URL?          // new preferred HLS URL
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case hasAccess = "has_access"
        case playbackURL = "playback_url"
        case hlsURL = "hls_url"
        case expiresAt = "expires_at"
    }

    /// Preferred stream URL – automatically picks HLS if available.
    var streamURL: URL? {
        hlsURL ?? playbackURL
    }
}
