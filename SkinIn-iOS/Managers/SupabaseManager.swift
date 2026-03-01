// Managers/SupabaseManager.swift
// SkinIn-iOS

import Foundation
import Observation
import Supabase

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailNotConfirmed
    case networkUnavailable
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Incorrect email or password. Please try again."
        case .emailNotConfirmed:
            return "This account email is not confirmed yet. In Supabase, confirm the user email (or enable auto-confirm) and try again."
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
        #if DEBUG
        print("[SupabaseManager] signIn() called for email: \(email)")
        #endif
        
        do {
            #if DEBUG
            print("[SupabaseManager] Calling client.auth.signIn()...")
            #endif
            
            let session = try await client.auth.signIn(email: email, password: password)
            
            #if DEBUG
            print("[SupabaseManager] Supabase signIn succeeded, updating local state...")
            #endif
            UserDefaults.standard.set(
                session.accessToken,
                forKey: Config.UserDefaultsKey.supabaseSessionToken
            )
            
            // Update state on main thread to ensure UI updates
            await MainActor.run {
                currentUserEmail = session.user.email
                isAuthenticated = true
                #if DEBUG
                print("[SkinIn][Auth] Sign in succeeded for \(email)")
                print("[SkinIn][Auth] isAuthenticated set to true on main thread")
                #endif
            }
        } catch {
            let message = error.localizedDescription.lowercased()
            if message.contains("invalid") || message.contains("credentials") || message.contains("password") {
                #if DEBUG
                print("[SkinIn][Auth] Sign in failed: invalid credentials")
                #endif
                throw AuthError.invalidCredentials
            } else if message.contains("email") && message.contains("confirm") {
                #if DEBUG
                print("[SkinIn][Auth] Sign in failed: email not confirmed")
                #endif
                throw AuthError.emailNotConfirmed
            } else if message.contains("network") || message.contains("offline") {
                #if DEBUG
                print("[SkinIn][Auth] Sign in failed: network unavailable")
                #endif
                throw AuthError.networkUnavailable
            } else {
                #if DEBUG
                print("[SkinIn][Auth] Sign in failed: \(error.localizedDescription)")
                #endif
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
            heightCm: data.heightCm,
            activityLevel: data.activityLevel.rawValue,
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

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ProfileError.serverError(statusCode)
        }

        // Cache nutrition targets locally so BlueprintView can display them
        // immediately without an extra network call.
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let tdee = json["tdee"] as? [String: Any] {
            if let cals = tdee["targetCalories"] as? Int {
                UserDefaults.standard.set(cals, forKey: "skinin_target_calories")
            }
            if let protein = tdee["proteinGrams"] as? Int {
                UserDefaults.standard.set(protein, forKey: "skinin_protein_grams")
            }
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

    /// Validates that the stored auth token is still accepted by the backend.
    /// Returns false for unauthorized/forbidden responses (e.g. deleted user),
    /// true for any non-auth response (including 200 and 404).
    func isSessionValidOnBackend() async -> Bool {
        guard let token = UserDefaults.standard.string(
            forKey: Config.UserDefaultsKey.supabaseSessionToken
        ) else { return false }

        guard let url = URL(string: Config.apiBaseURL + "/api/workouts/current-week") else {
            return false
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return http.statusCode != 401 && http.statusCode != 403
        } catch {
            return false
        }
    }

    // MARK: - Setup State Check

    /// Returns true when the backend reports a current-week workout plan.
    /// A 200 status implies setup/payment was previously completed.
    func hasSavedWorkoutPlan() async -> Bool {
        guard let token = UserDefaults.standard.string(
            forKey: Config.UserDefaultsKey.supabaseSessionToken
        ) else { return false }

        guard let url = URL(string: Config.apiBaseURL + "/api/workouts/current-week") else {
            return false
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return http.statusCode == 200
        } catch {
            return false
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
    let heightCm: Double      // derived from ft + in inputs
    let activityLevel: String // e.g. "moderately_active"
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
