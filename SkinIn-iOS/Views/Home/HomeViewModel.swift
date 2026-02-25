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

    var totalStake: Double = 150.00
    var targetStake: Double = 200.00
    var protectedAmount: Double = 150.00

    // MARK: Week Progress State

    var currentWeek: Int = 4
    var completedWorkouts: Int = 3
    var totalWorkoutsThisWeek: Int = 4
    var graceWeeksLeft: Int = 1

    // MARK: Streak State

    var streakDays: Int = 12

    // MARK: AI Nudge State

    var aiNudgeMessage: String = "I noticed you usually workout at 6pm. Ready to crush Leg Day?"

    // MARK: Computed

    /// Fractional progress of protected amount toward the staking target (0.0–1.0).
    var protectionProgress: Double {
        guard targetStake > 0 else { return 0 }
        return min(protectedAmount / targetStake, 1.0)
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
            title: "Momentum AI Insight",
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

    // MARK: - Actions

    func signOut() {
        SupabaseManager.shared.signOut()
        // The app-level router in SkinIn_iOSApp observes isAuthenticated and
        // automatically transitions back to OnboardingView / LoginView.
    }
}
