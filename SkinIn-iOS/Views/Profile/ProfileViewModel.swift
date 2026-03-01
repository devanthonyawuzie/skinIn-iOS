// Views/Profile/ProfileViewModel.swift
// SkinIn-iOS

import Foundation
import Observation

// MARK: - ProfileViewModel

@Observable
final class ProfileViewModel {

    // MARK: - User data (loaded from API)

    var firstName: String       = ""
    var lastName: String        = ""
    var goal: String            = ""
    var experienceLevel: String = ""
    var currentWeight: String   = ""
    var goalWeight: String      = ""

    // MARK: - Computed display helpers

    var weightDisplay: String {
        get { currentWeight.isEmpty ? "" : "\(currentWeight) lbs" }
        set { currentWeight = newValue.replacingOccurrences(of: " lbs", with: "") }
    }

    // MARK: - Stats

    var streakDays: Int = 0

    // MARK: - Workout progress (from /api/workouts/current-week)

    var currentWeek: Int           = 1
    var completedWorkouts: Int     = 0
    var totalWorkoutsThisWeek: Int = 0
    var refundEligible: Bool       = true
    var graceDayUsed: Bool         = false

    // MARK: - Settings navigation

    var showEditProfile: Bool = false

    // MARK: - Init (load cached data for instant display)

    init() {
        // Name is written to UserDefaults at setup time (SetupViewModel.saveProfile)
        // and refreshed after each fetchProfile() call — no loading state needed.
        let cached = UserDefaults.standard.string(forKey: "skinin_profile_name") ?? ""
        if !cached.isEmpty {
            let parts = cached.split(separator: "|", maxSplits: 1)
            firstName = parts.count > 0 ? String(parts[0]) : ""
            lastName  = parts.count > 1 ? String(parts[1]) : ""
        }
    }

    // MARK: - Computed

    var fullName: String   { firstName.isEmpty ? "" : "\(firstName) \(lastName)" }
    var planLabel: String  {
        guard !goal.isEmpty else { return "Active Plan" }
        return "$80 \(goal.replacingOccurrences(of: "_", with: " ").capitalized) Plan"
    }
    var appVersion: String { "Version 2.4.0" }

    // MARK: - Fetch

    func fetchAll() async {
        async let _ = fetchProfile()
        async let _ = fetchWorkoutProgress()
    }

    private func authToken() -> String? {
        UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken)
    }

    /// Loads the user's real name and goal from GET /api/profile.
    func fetchProfile() async {
        guard let token = authToken(),
              let url   = URL(string: Config.apiBaseURL + "/api/profile")
        else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profile = json["profile"] as? [String: Any]
        else { return }

        await MainActor.run {
            if let first = profile["first_name"]       as? String { firstName       = first }
            if let last  = profile["last_name"]        as? String { lastName        = last  }
            if let g     = profile["goal"]             as? String { goal            = g     }
            if let exp   = profile["experience_level"] as? String { experienceLevel = exp   }
            if let cw    = profile["current_weight"]   as? Double { currentWeight   = String(Int(cw)) }
            if let gw    = profile["goal_weight"]      as? Double { goalWeight      = String(Int(gw)) }
            // Cache name for instant display on next visit
            UserDefaults.standard.set("\(firstName)|\(lastName)", forKey: "skinin_profile_name")
        }
    }

    /// Loads current week number and workout completion counts from /api/workouts/current-week.
    func fetchWorkoutProgress() async {
        guard let token = authToken(),
              let url   = URL(string: Config.apiBaseURL + "/api/workouts/current-week")
        else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        await MainActor.run {
            if let week = json["week_number"] as? Int { currentWeek = week }
            if let workouts = json["workouts"] as? [[String: Any]] {
                completedWorkouts      = workouts.filter { ($0["status"] as? String) == "completed" }.count
                totalWorkoutsThisWeek  = workouts.count
            }
            if let eligible = json["refund_eligible"] as? Bool { refundEligible = eligible }
            if let grace    = json["grace_day_used"]   as? Bool { graceDayUsed   = grace   }
        }
    }

    // MARK: - Actions

    func signOut() {
        SupabaseManager.shared.signOut()
    }
}
