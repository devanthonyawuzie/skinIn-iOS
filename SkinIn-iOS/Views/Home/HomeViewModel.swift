// Views/Home/HomeViewModel.swift
// SkinIn-iOS
//
// Owns all data and actions for HomeView. All properties are mock values
// until real API integration is added. The view reads state and calls
// actions — it never touches SupabaseManager directly.

import Foundation
import Observation
import SwiftUI

// MARK: - HomeViewModel

@Observable
final class HomeViewModel {

    // MARK: Stake State

    var totalStake: Double = 0.00

    // MARK: Week Progress State

    var currentWeek: Int = 1
    var completedWorkouts: Int = 3
    var totalWorkoutsThisWeek: Int = 4
    var graceWeeksLeft: Int = 1

    // MARK: AI Nudge State

    var aiNudgeMessage: String = "I noticed you usually workout at 6pm. Ready to crush Leg Day?"

    // MARK: Computed

    /// Fractional progress through the 12-week program (0.0–1.0).
    var protectionProgress: Double {
        min(Double(currentWeek) / 12.0, 1.0)
    }

    // MARK: - Notifications

    var showNotifications: Bool = false

    enum NotificationGroup: String, CaseIterable {
        case today = "TODAY"
        case yesterday = "YESTERDAY"
        case lastThirtyDays = "LAST 30 DAYS"
    }

    struct AppNotification: Identifiable {
        let id: UUID
        let group: NotificationGroup
        let icon: String          // SF Symbol name
        let iconColor: Color
        let title: String
        let subtitle: String
        let timeAgo: String
    }

    var notifications: [AppNotification] = [
        AppNotification(
            id: UUID(),
            group: .today,
            icon: "flame.fill",
            iconColor: Color.orange,
            title: "Workout Reminder",
            subtitle: "Don't forget — 1 workout left this week to stay eligible.",
            timeAgo: "2h ago"
        ),
        AppNotification(
            id: UUID(),
            group: .today,
            icon: "shield.fill",
            iconColor: Color.brandGreen,
            title: "Refund Protection Active",
            subtitle: "You're on track. Keep it up to protect your $80 pledge.",
            timeAgo: "5h ago"
        ),
        AppNotification(
            id: UUID(),
            group: .yesterday,
            icon: "checkmark.circle.fill",
            iconColor: Color.brandGreen,
            title: "Workout Logged",
            subtitle: "Metabolic Burn logged successfully. Great work!",
            timeAgo: "1d ago"
        ),
        AppNotification(
            id: UUID(),
            group: .yesterday,
            icon: "bolt.fill",
            iconColor: Color.brandGreen,
            title: "SkinIn AI Insight",
            subtitle: "Your squat is up 10%. Add 5lbs to bench next session.",
            timeAgo: "1d ago"
        ),
        AppNotification(
            id: UUID(),
            group: .lastThirtyDays,
            icon: "trophy.fill",
            iconColor: Color(red: 1.0, green: 0.75, blue: 0.0),
            title: "New Personal Record",
            subtitle: "Leg Press 450x12 — that's a PR!",
            timeAgo: "5d ago"
        ),
        AppNotification(
            id: UUID(),
            group: .lastThirtyDays,
            icon: "creditcard.fill",
            iconColor: Color(white: 0.55),
            title: "Payment Confirmed",
            subtitle: "Your $80 SkinIn pledge has been received.",
            timeAgo: "12d ago"
        ),
    ]

    // MARK: - Cooldown State

    /// The server-authoritative time at which the 18-hour cooldown expires.
    /// nil when no cooldown is active.
    var cooldownUnlocksAt: Date? = nil

    /// Live HH:MM:SS string driven by the 1-second timer below.
    /// Empty string when no cooldown is active.
    var cooldownCountdown: String = ""

    /// True while a cooldown is in progress.
    var cooldownActive: Bool { cooldownUnlocksAt != nil }

    private var cooldownTimer: Timer?

    // MARK: - Cooldown Methods

    /// Fetches the user's subscription data (amount paid + current week) from
    /// GET /api/workouts/current-week and updates totalStake + currentWeek.
    func fetchSubscriptionData() async {
        guard let token = UserDefaults.standard.string(
            forKey: Config.UserDefaultsKey.supabaseSessionToken
        ) else { return }

        guard let url = URL(string: Config.apiBaseURL + "/api/workouts/current-week") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        await MainActor.run {
            if let paid = json["amount_paid"] as? Double { totalStake = paid }
            if let week = json["week_number"] as? Int    { currentWeek = week }
        }
    }

    /// Fetches cooldown status from the server and starts the countdown timer
    /// if the user is still within the 18-hour window.
    /// All time math is server-side — only the returned `unlocks_at` is used locally.
    func fetchCooldownStatus() async {
        guard let token = UserDefaults.standard.string(
            forKey: Config.UserDefaultsKey.supabaseSessionToken
        ) else { return }

        guard let url = URL(string: Config.apiBaseURL + "/api/workout-logs/cooldown-status") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let isActive = json["cooldown_active"] as? Bool else { return }

        if isActive,
           let unlocksAtStr = json["unlocks_at"] as? String,
           let unlocksAt = ISO8601DateFormatter().date(from: unlocksAtStr) {
            await MainActor.run { beginCooldownCountdown(unlocksAt: unlocksAt) }
        } else {
            await MainActor.run { stopCooldownTimer() }
        }
    }

    /// Starts (or restarts) the 1-second countdown timer.
    /// Must be called on the main thread.
    func beginCooldownCountdown(unlocksAt: Date) {
        cooldownTimer?.invalidate()
        cooldownUnlocksAt = unlocksAt
        tickCooldown()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            self.tickCooldown()
        }
    }

    func stopCooldownTimer() {
        cooldownTimer?.invalidate()
        cooldownTimer = nil
        cooldownUnlocksAt = nil
        cooldownCountdown = ""
    }

    private func tickCooldown() {
        guard let unlocksAt = cooldownUnlocksAt else { return }
        let remaining = unlocksAt.timeIntervalSinceNow
        guard remaining > 0 else {
            stopCooldownTimer()
            return
        }
        let h = Int(remaining) / 3600
        let m = (Int(remaining) % 3600) / 60
        let s = Int(remaining) % 60
        cooldownCountdown = String(format: "%02d:%02d:%02d", h, m, s)
    }

    // MARK: - Actions

    func signOut() {
        stopCooldownTimer()
        SupabaseManager.shared.signOut()
        // The app-level router in SkinIn_iOSApp observes isAuthenticated and
        // automatically transitions back to OnboardingView / LoginView.
    }
}
