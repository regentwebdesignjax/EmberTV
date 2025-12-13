//
//  EmberAPIClient.swift
//  EmberTV
//

import Foundation
import Combine

@MainActor
final class EmberAPIClient: ObservableObject {

    // MARK: - Nested Types

    struct LoginBody: Encodable {
        let email: String
        let password: String
    }

    struct AuthUser: Decodable {
        let id: String
        let email: String
        let name: String?
    }

    struct AuthResponse: Decodable {
        let token: String
    }

    enum LoginError: Error {
        case invalidCredentials
        case serverError
    }

    struct PlaybackBody: Encodable {
        let film_id: String
    }

    // MARK: - Singleton

    static let shared = EmberAPIClient()

    // MARK: - Published auth state

    @Published var token: String?
    
    private let tokenKey = "EmberAuthToken"

    // MARK: - Init

    private init() {
        // Restore token on launch if it exists
        self.token = UserDefaults.standard.string(forKey: tokenKey)
    }

    // MARK: - Core Request Builder

    /// Builds a URLRequest for either the main Ember API or the Base44 functions API.
    private func makeRequest(
        path: String,
        method: String = "GET",
        body: Encodable? = nil,
        useAuthAPI: Bool = false
    ) throws -> URLRequest {

        let base = useAuthAPI ? EmberAPIConfig.authBaseURL : EmberAPIConfig.base44URL
        let url = base.appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }

        return request
    }


    /// JSON decoder helper
    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Auth

    /// Logs in against the Ember auth API and persists the token.
    func login(email: String, password: String) async throws {
        // Clear previous token
        self.token = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)

        let body = LoginBody(email: email, password: password)
        let request = try makeRequest(
            path: "authLogin",      // 👈 THIS is your Base44 function name
            method: "POST",
            body: body,
            useAuthAPI: true        // authBaseURL == base44URL so this is fine
        )

        // Debug: log what we're sending
        if let httpBody = request.httpBody,
           let json = String(data: httpBody, encoding: .utf8) {
            print("LOGIN REQUEST BODY:", json)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw LoginError.serverError
        }

        print("LOGIN STATUS:", http.statusCode)
        print("LOGIN BODY:", String(data: data, encoding: .utf8) ?? "N/A")

        switch http.statusCode {
        case 200:
            let auth = try decode(AuthResponse.self, from: data)
            self.token = auth.token
            UserDefaults.standard.set(auth.token, forKey: tokenKey)
            print("✅ Stored token (prefix):", String(auth.token.prefix(16)))

        case 401:
            throw LoginError.invalidCredentials

        default:
            throw LoginError.serverError
        }
    }



    /// Clears stored auth and returns the app to the login state (if you add a logout button).
    /// Clears stored auth and returns the app to the login state.
    func logout() {
        // Clear auth
        token = nil

        // Clear persisted token
        UserDefaults.standard.removeObject(forKey: tokenKey)

        // (Optional) Clear any other Ember-related keys if you add them later,
        // e.g., playback progress, cached rentals, etc.
    }


    // MARK: - Films (optional – if you use a browse/catalog view later)

    func fetchFilms() async throws -> [Film] {
        let request = try makeRequest(
            path: "films",               // adjust to your real films endpoint
            useAuthAPI: true
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let result = try decode(PaginatedFilmsResponse.self, from: data)
        return result.data
    }

    // MARK: - Rentals (Base44 /apiMyRentals)

    /// Fetches active rentals for the logged-in user via the Base44 `/apiMyRentals` function.
    func fetchMyRentals() async throws -> [Rental] {
        print("🔐 fetchMyRentals using token:", String(token?.prefix(16) ?? "nil"))

        let request = try makeRequest(
            path: "apiMyRentals",
            useAuthAPI: false
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("fetchMyRentals → HTTP", http.statusCode)
        }
        if let bodyString = String(data: data, encoding: .utf8) {
            print("fetchMyRentals → Body:", bodyString)
        }

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let rentalsResponse = try decode(RentalsResponse.self, from: data)
        return rentalsResponse.data
    }


    // MARK: - Playback (if you still use a playback function)

    func fetchPlayback(for filmID: String) async throws -> PlaybackResponse {
        let body = PlaybackBody(film_id: filmID)

        let request = try makeRequest(
            path: "apiPlayback",        // adjust to your actual playback function path
            method: "POST",
            body: body,
            useAuthAPI: false           // Base44 functions
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            print("fetchPlayback → non-HTTP response")
            throw URLError(.badServerResponse)
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<non-UTF8>"
        print("fetchPlayback → HTTP \(http.statusCode)")
        print("fetchPlayback → Body: \(bodyString)")

        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let playback = try decode(PlaybackResponse.self, from: data)
        print("fetchPlayback → hasAccess=\(playback.hasAccess), hlsURL=\(String(describing: playback.hlsURL)), playbackURL=\(String(describing: playback.playbackURL))")
        return playback
    }
}

