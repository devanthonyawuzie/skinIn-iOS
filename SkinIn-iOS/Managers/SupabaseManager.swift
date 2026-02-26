// Managers/SupabaseManager.swift
// SkinIn-iOS

import Foundation
import Observation
import Supabase

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case invalidCredentials
    case networkUnavailable
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Incorrect email or password. Please try again."
        case .networkUnavailable:
            return "No internet connection. Check your network and try again."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - SupabaseManager

@Observable
final class SupabaseManager {

    // MARK: Singleton

    static let shared = SupabaseManager()

    let client = SupabaseClient(
        supabaseURL: URL(string: Config.supabaseURL)!,
        supabaseKey: Config.supabaseAnonKey
    )

    private init() {}

    // MARK: State

    private(set) var isAuthenticated: Bool = false
    private(set) var currentUserEmail: String? = nil

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            UserDefaults.standard.set(
                session.accessToken,
                forKey: Config.UserDefaultsKey.supabaseSessionToken
            )
            currentUserEmail = session.user.email
            isAuthenticated = true
            // TESTING: always restart from setup so the full flow can be reviewed.
            // Remove this line before App Store submission.
            UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKey.hasCompletedSetup)
        } catch {
            let message = error.localizedDescription.lowercased()
            if message.contains("invalid") || message.contains("credentials") || message.contains("password") {
                throw AuthError.invalidCredentials
            } else if message.contains("network") || message.contains("offline") {
                throw AuthError.networkUnavailable
            } else {
                throw AuthError.unknown(error.localizedDescription)
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        Task { try? await client.auth.signOut() }
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKey.supabaseSessionToken)
        currentUserEmail = nil
        isAuthenticated = false
    }

    // MARK: - Profile Setup

    /// Persists the user's setup data to the backend via a real POST to the calibrate endpoint.
    func saveUserProfile(_ data: SetupViewModel) async throws {
        guard let token = UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken) else {
            throw ProfileError.missingAuthToken
        }

        let dobFormatter = ISO8601DateFormatter()
        dobFormatter.formatOptions = [.withFullDate]

        let payload = ProfilePayload(
            firstName: data.firstName,
            lastName: data.lastName,
            dateOfBirth: dobFormatter.string(from: data.dateOfBirth),
            sex: data.sex,
            goal: data.goal?.rawValue ?? "",
            experienceLevel: data.experienceLevel.rawValue,
            currentWeight: Double(data.currentWeight) ?? 0,
            goalWeight: Double(data.goalWeight) ?? 0,
            gymGeofencingEnabled: data.gymGeofencingEnabled,
            pushNotificationsEnabled: data.pushNotificationsEnabled,
            healthKitEnabled: data.healthKitEnabled,
            timezone: data.timezone
        )

        guard let url = URL(string: Config.apiBaseURL + "/api/profile/calibrate") else {
            throw ProfileError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ProfileError.serverError(statusCode)
        }
    }

    // MARK: - Session Restoration

    func restoreSession() async {
        do {
            // SDK automatically refreshes using the stored keychain session
            let session = try await client.auth.session
            // Refresh the UserDefaults token used for API calls
            UserDefaults.standard.set(
                session.accessToken,
                forKey: Config.UserDefaultsKey.supabaseSessionToken
            )
            currentUserEmail = session.user.email
            isAuthenticated = true
        } catch {
            UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKey.supabaseSessionToken)
            isAuthenticated = false
        }
    }
}

// MARK: - Supporting Types

/// Request body sent to POST /api/profile/calibrate.
private struct ProfilePayload: Encodable {
    let firstName: String
    let lastName: String
    let dateOfBirth: String   // ISO 8601 date string "yyyy-MM-dd"
    let sex: String
    let goal: String
    let experienceLevel: String
    let currentWeight: Double
    let goalWeight: Double
    let gymGeofencingEnabled: Bool
    let pushNotificationsEnabled: Bool
    let healthKitEnabled: Bool
    let timezone: String      // IANA identifier e.g. "America/New_York"
}

/// Errors specific to the profile-save flow.
enum ProfileError: LocalizedError {
    case missingAuthToken
    case invalidURL
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .missingAuthToken:
            return "You are not signed in. Please sign in and try again."
        case .invalidURL:
            return "The profile endpoint URL is invalid. Contact support."
        case .serverError(let code):
            return "The server returned an error (HTTP \(code)). Please try again."
        }
    }
}
