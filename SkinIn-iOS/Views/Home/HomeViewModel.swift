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

    // MARK: - Init (load UserDefaults cache for instant cold-launch display)

    init() {
        let cachedStake = UserDefaults.standard.double(forKey: "skinin_home_stake")
        if cachedStake > 0 { totalStake = cachedStake }
        let cachedWeek = UserDefaults.standard.integer(forKey: "skinin_home_week")
        if cachedWeek > 0 { currentWeek = cachedWeek }
    }

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

    // MARK: - Week Countdown State

    /// Server-authoritative time at which the current program week ends.
    var weekEndsAt: Date? = nil

    /// Live "Xd Xh Xm" string updated every minute.
    var weekCountdown: String = ""

    private var weekTimer: Timer?

    func beginWeekCountdown(endsAt: Date) {
        weekTimer?.invalidate()
        weekEndsAt = endsAt
        tickWeek()
        weekTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            self.tickWeek()
        }
    }

    func stopWeekTimer() {
        weekTimer?.invalidate()
        weekTimer = nil
        weekEndsAt = nil
        weekCountdown = ""
    }

    private func tickWeek() {
        guard let endsAt = weekEndsAt else { return }
        let remaining = endsAt.timeIntervalSinceNow
        guard remaining > 0 else { stopWeekTimer(); return }
        let days    = Int(remaining) / 86400
        let hours   = (Int(remaining) % 86400) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if days > 0      { weekCountdown = "\(days)d \(hours)h \(minutes)m" }
        else if hours > 0 { weekCountdown = "\(hours)h \(minutes)m" }
        else              { weekCountdown = "\(minutes)m" }
    }

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

        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoBasic = ISO8601DateFormatter()

        await MainActor.run {
            if let paid = json["amount_paid"] as? Double { totalStake = paid }
            if let week = json["week_number"] as? Int    { currentWeek = week }

            if let str = json["week_ends_at"] as? String,
               let date = isoFull.date(from: str) ?? isoBasic.date(from: str) {
                beginWeekCountdown(endsAt: date)
            }

            // Persist for instant display on the next cold launch
            UserDefaults.standard.set(totalStake,  forKey: "skinin_home_stake")
            UserDefaults.standard.set(currentWeek, forKey: "skinin_home_week")
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

    // MARK: - AI Tip State

    var aiTipText: String    = ""
    var aiTipExpanded: Bool  = false
    var aiTipLoading: Bool   = false

    /// True when a tip is loaded AND the user hasn't dismissed it within 24h.
    var aiTipVisible: Bool {
        guard !aiTipText.isEmpty else { return false }
        if let until = UserDefaults.standard.object(forKey: "skinin_ai_tip_dismissed_until") as? Date {
            return Date() > until
        }
        return true
    }

    // MARK: - AI Tip Methods

    func fetchAITip() async {
        guard let token = UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken),
              let url   = URL(string: Config.apiBaseURL + "/api/ai-tip")
        else { return }

        await MainActor.run { aiTipLoading = true }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tip  = json["tip"] as? String
        else {
            await MainActor.run { aiTipLoading = false }
            return
        }

        await MainActor.run {
            aiTipText    = tip
            aiTipLoading = false
        }
    }

    /// Hides the AI tip card for 24 hours (stored in UserDefaults).
    func dismissAITip() {
        let until = Date().addingTimeInterval(24 * 60 * 60)
        UserDefaults.standard.set(until, forKey: "skinin_ai_tip_dismissed_until")
        aiTipExpanded = false
        aiTipText     = ""
    }

    /// Broadcasts a tab-switch to the Workouts tab via NotificationCenter.
    /// MainTabView listens for this notification and updates selectedTab.
    func switchToWorkoutsTab() {
        NotificationCenter.default.post(name: .skinInSwitchToWorkouts, object: nil)
    }

    // MARK: - Actions

    func signOut() {
        stopCooldownTimer()
        stopWeekTimer()
        SupabaseManager.shared.signOut()
        // The app-level router in SkinIn_iOSApp observes isAuthenticated and
        // automatically transitions back to OnboardingView / LoginView.
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let skinInSwitchToWorkouts = Notification.Name("skinInSwitchToWorkouts")
}
