// Views/Profile/ProfileViewModel.swift
// SkinIn-iOS

import Foundation
import Observation

// MARK: - ProfileViewModel

@Observable
final class ProfileViewModel {

    // MARK: - User data (mock — will come from API later)

    var firstName: String = "Alex"
    var lastName: String = "Johnson"
    var currentWeight: String = "185"
    var goalWeight: String = "175"
    var goal: String = "Muscle Gain"
    var experienceLevel: String = "Intermediate"

    // MARK: - Stats (mock)

    var protectedAmount: String = "$240"
    var streakDays: Int = 21
    var weightDisplay: String = "185 lbs"

    // MARK: - Settings navigation

    var showEditProfile: Bool = false

    // MARK: - Computed

    var fullName: String { "\(firstName) \(lastName)" }
    var planLabel: String { "$80 \(goal) Plan" }
    var appVersion: String { "Version 2.4.0" }

    // MARK: - Actions

    func signOut() {
        SupabaseManager.shared.signOut()
        // The app-level router in SkinIn_iOSApp observes isAuthenticated and
        // automatically transitions back to OnboardingView / LoginView.
    }
}
