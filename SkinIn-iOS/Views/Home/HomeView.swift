// Views/Home/HomeView.swift
// SkinIn-iOS
//
// Main dashboard screen shown after the user completes onboarding + setup.
// All data comes from HomeViewModel (mock values for now).
// Layout: custom top nav bar + ScrollView content + bottom padding to clear custom tab bar.

import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    @State private var vm = HomeViewModel()

    // Light gray background matches setup screens — not the dark appBackground.
    private let background = Color(red: 0.96, green: 0.96, blue: 0.96)

    var body: some View {
        ZStack(alignment: .top) {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Custom Navigation Bar
                HomeNavBar(streakDays: vm.streakDays, onBellTap: { vm.showNotifications = true })
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.md)
                    .background(background)

                // MARK: Scrollable Dashboard Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Spacing.md) {
                        TotalStakeCard(
                            totalStake: vm.totalStake,
                            targetStake: vm.targetStake,
                            progress: vm.protectionProgress
                        )

                        WeekProgressCard(
                            currentWeek: vm.currentWeek,
                            completedWorkouts: vm.completedWorkouts,
                            totalWorkoutsThisWeek: vm.totalWorkoutsThisWeek,
                            graceWeeksLeft: vm.graceWeeksLeft
                        )

                        if vm.cooldownActive {
                            CooldownBanner(countdown: vm.cooldownCountdown)
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }

                        WeekPlanSection()

                        AISnudgeCard(message: vm.aiNudgeMessage)
                    }
                    .padding(.horizontal, Spacing.md)
                    // 80pt bottom padding clears the 60pt custom tab bar + safe area.
                    .padding(.bottom, 80)
                }
            }
        }
        .overlay {
            if vm.showNotifications {
                NotificationsOverlay(vm: vm)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: vm.showNotifications)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.cooldownActive)
        .task { await vm.fetchCooldownStatus() }
        // The NavigationStack in the app root hides back buttons for the home flow;
        // make sure the custom bar renders correctly even when embedded.
        .navigationBarHidden(true)
    }
}

// MARK: - HomeNavBar

private struct HomeNavBar: View {

    let streakDays: Int
    let onBellTap: () -> Void

    var body: some View {
        HStack(alignment: .center) {

            // MARK: Brand Mark (left)
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.brandGreen)

                Text("SkinIn")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.black)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("SkinIn")

            Spacer()

            // MARK: Streak Pill (center)
            HStack(spacing: 4) {
                Image(systemName: "house.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.black)

                Text("\(streakDays) Days")
                    .font(.badgeLabel)
                    .foregroundStyle(Color.black)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(Color.brandGreen)
            .clipShape(Capsule())
            .accessibilityLabel("\(streakDays) day streak")

            Spacer()

            // MARK: Notifications Bell (right)
            Button(action: onBellTap) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.black)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Notifications")
            .accessibilityLabel("Profile avatar")
            .accessibilityHint("Tap to view your profile")
        }
        .frame(height: 44)
    }
}

// MARK: - TotalStakeCard

private struct TotalStakeCard: View {

    let totalStake: Double
    let targetStake: Double
    let progress: Double

    private let stakeFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private func formatted(_ value: Double) -> String {
        stakeFormatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {

            // MARK: Label
            Text("TOTAL STAKE")
                .font(.badgeLabel)
                .foregroundStyle(Color(white: 0.50))
                .kerning(1.5)
                .accessibilityAddTraits(.isHeader)

            // MARK: Amount
            Text(formatted(totalStake))
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(Color.black)
                .accessibilityLabel("Total stake: \(formatted(totalStake))")

            // MARK: Protected Badge
            Text("Protected")
                .font(.badgeLabel)
                .foregroundStyle(Color.black)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 6)
                .background(Color.brandGreen)
                .clipShape(Capsule())
                .accessibilityLabel("Status: Protected")

            // MARK: Divider
            Divider()
                .padding(.vertical, Spacing.xs)

            // MARK: Progress Row
            VStack(spacing: Spacing.xs) {
                HStack {
                    Text("Money Protected")
                        .font(.badgeLabel)
                        .foregroundStyle(Color(white: 0.50))

                    Spacer()

                    Text("Target: \(formatted(targetStake))")
                        .font(.badgeLabel)
                        .foregroundStyle(Color(white: 0.50))
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(Color(white: 0.88))
                            .frame(height: 10)

                        // Fill
                        Capsule()
                            .fill(Color.brandGreen)
                            .frame(width: geo.size.width * progress, height: 10)
                            .animation(.spring(duration: 0.6), value: progress)
                    }
                }
                .frame(height: 10)
                .accessibilityLabel("Protection progress: \(Int(progress * 100)) percent")
                .accessibilityValue("\(formatted(totalStake)) of \(formatted(targetStake))")
            }

            // MARK: Refund Eligible Row
            HStack(spacing: 4) {
                Image(systemName: "shield.checkmark.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.brandGreen)

                Text("Refund Eligible")
                    .font(.caption)
                    .foregroundStyle(Color(white: 0.50))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Refund eligible")
        }
        .padding(Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - WeekProgressCard

private struct WeekProgressCard: View {

    let currentWeek: Int
    let completedWorkouts: Int
    let totalWorkoutsThisWeek: Int
    let graceWeeksLeft: Int

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {

            // MARK: Icon Circle
            ZStack {
                Circle()
                    .fill(Color.brandGreen.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "arrow.trianglehead.2.counterclockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.brandGreen)
            }
            .accessibilityHidden(true)

            // MARK: Text Content
            VStack(alignment: .leading, spacing: Spacing.xs) {

                Text("Week \(currentWeek) Progress")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black)
                    .accessibilityAddTraits(.isHeader)

                // Inline bold green fraction using Text concatenation
                (
                    Text("You've crushed ")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(white: 0.40))
                    + Text("\(completedWorkouts)/\(totalWorkoutsThisWeek)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.brandGreen)
                    + Text(" workouts. Just one more to lock in this week's deposit!")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(white: 0.40))
                )
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(
                    "You've crushed \(completedWorkouts) of \(totalWorkoutsThisWeek) workouts. Just one more to lock in this week's deposit!"
                )

                if graceWeeksLeft > 0 {
                    Text("\(graceWeeksLeft) Grace Week\(graceWeeksLeft == 1 ? "" : "s") Left")
                        .font(.badgeLabel)
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                        .padding(.top, 2)
                        .accessibilityLabel("\(graceWeeksLeft) grace week\(graceWeeksLeft == 1 ? "" : "s") remaining")
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - WeekPlanSection

private struct WeekPlanSection: View {

    // Hardcoded plan data — replace with ViewModel data when API is ready.
    private let workoutDays: [WorkoutDayItem] = [
        WorkoutDayItem(day: "MON", name: "Upper Body", duration: "45 mins", isCompleted: true),
        WorkoutDayItem(day: "TUE", name: "HIIT Cardio", duration: "30 mins", isCompleted: true),
        WorkoutDayItem(day: "WED", name: "Active Recovery", duration: "20 mins", isCompleted: false),
        WorkoutDayItem(day: "THU", name: "Leg Day", duration: "50 mins", isCompleted: false),
        WorkoutDayItem(day: "FRI", name: "Push Pull", duration: "40 mins", isCompleted: false)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {

            // MARK: Section Header
            HStack {
                Text("This Week's Plan")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button(action: {}) {
                    Text("View All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.brandGreen)
                }
                .accessibilityLabel("View all workouts")
            }

            // MARK: Horizontal Scroll of Day Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(workoutDays) { day in
                        WorkoutDayCard(item: day)
                    }
                }
                // Add horizontal padding so the first/last cards don't clip at edges.
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - WorkoutDayItem

private struct WorkoutDayItem: Identifiable {
    let id = UUID()
    let day: String
    let name: String
    let duration: String
    let isCompleted: Bool
}

// MARK: - WorkoutDayCard

private struct WorkoutDayCard: View {

    let item: WorkoutDayItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {

            // Day label
            Text(item.day)
                .font(.badgeLabel)
                .foregroundStyle(Color(white: 0.50))

            // Checkmark / empty circle
            ZStack {
                Circle()
                    .fill(item.isCompleted ? Color.brandGreen : Color(white: 0.88))
                    .frame(width: 28, height: 28)

                if item.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .accessibilityHidden(true)

            // Workout name
            Text(item.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.black)
                .lineLimit(1)

            // Duration
            Text(item.duration)
                .font(.caption)
                .foregroundStyle(Color(white: 0.50))

            // Status label — only shown for completed workouts
            if item.isCompleted {
                Text("COMPLETED")
                    .font(.badgeLabel)
                    .foregroundStyle(Color.brandGreen)
            }
        }
        .padding(Spacing.sm)
        .frame(width: 120, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(item.day): \(item.name), \(item.duration), \(item.isCompleted ? "Completed" : "Upcoming")"
        )
    }
}

// MARK: - AISnudgeCard

private struct AISnudgeCard: View {

    let message: String

    var body: some View {
        ZStack(alignment: .topTrailing) {

            HStack(alignment: .top, spacing: Spacing.sm) {

                // MARK: AI Icon Circle
                ZStack {
                    Circle()
                        .fill(Color.brandGreen.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.brandGreen)
                }
                .accessibilityHidden(true)

                // MARK: Message — "SkinIn AI:" bold + message gray inline
                (
                    Text("SkinIn AI: ")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.black)
                    + Text(message)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(white: 0.40))
                )
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("SkinIn AI: \(message)")
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)

            // MARK: Red Notification Badge
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .offset(x: -Spacing.sm, y: Spacing.sm)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("SkinIn AI nudge: \(message). New notification.")
    }
}

// MARK: - NotificationsOverlay

private struct NotificationsOverlay: View {

    let vm: HomeViewModel

    var body: some View {
        ZStack(alignment: .top) {

            // MARK: Dimmed Backdrop
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { vm.showNotifications = false }
                .accessibilityLabel("Dismiss notifications")
                .accessibilityHint("Tap to close the notifications panel")

            // MARK: Slide-down Panel
            VStack(spacing: 0) {

                // MARK: Handle + Header
                VStack(spacing: 0) {
                    // Drag handle
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: 0.75))
                        .frame(width: 36, height: 4)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.md)
                        .accessibilityHidden(true)

                    HStack {
                        Text("Notifications")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.black)

                        Spacer()

                        Button {
                            vm.showNotifications = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(white: 0.55))
                                .frame(width: 32, height: 32)
                                .background(Color(white: 0.93))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Close notifications")
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.md)
                }

                Divider()

                // MARK: Grouped Notification List
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(HomeViewModel.NotificationGroup.allCases, id: \.self) { group in
                            let groupNotifs = vm.notifications.filter { $0.group == group }
                            if !groupNotifs.isEmpty {
                                // Section header
                                Text(group.rawValue)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(white: 0.55))
                                    .kerning(0.8)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.top, Spacing.lg)
                                    .padding(.bottom, Spacing.xs)
                                    .accessibilityAddTraits(.isHeader)

                                // Notification rows
                                ForEach(groupNotifs) { notif in
                                    NotificationRow(notif: notif)

                                    // Inset divider between rows (skip after last)
                                    if notif.id != groupNotifs.last?.id {
                                        Divider()
                                            .padding(.leading, 70)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
            .frame(maxHeight: 560)
            .background(Color.white)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: 24,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - NotificationRow

private struct NotificationRow: View {

    let notif: HomeViewModel.AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {

            // MARK: Icon Circle
            ZStack {
                Circle()
                    .fill(notif.iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: notif.icon)
                    .font(.system(size: 17))
                    .foregroundStyle(notif.iconColor)
            }
            .accessibilityHidden(true)

            // MARK: Text Content
            VStack(alignment: .leading, spacing: 3) {
                Text(notif.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.black)

                Text(notif.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // MARK: Time Label
            Text(notif.timeAgo)
                .font(.system(size: 11))
                .foregroundStyle(Color(white: 0.65))
                .padding(.top, 1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notif.title). \(notif.subtitle). \(notif.timeAgo).")
    }
}

// MARK: - CooldownBanner

/// Shows a live HH:MM:SS countdown while the 18-hour inter-workout cooldown
/// is active. The timer runs in HomeViewModel and is driven by a 1-second
/// server-authoritative schedule — device time is never used to compute it.
private struct CooldownBanner: View {

    let countdown: String

    var body: some View {
        HStack(spacing: Spacing.md) {

            // Lock icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.orange)
            }
            .accessibilityHidden(true)

            // Text content
            VStack(alignment: .leading, spacing: 3) {
                Text("NEXT WORKOUT UNLOCKS IN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.orange.opacity(0.75))
                    .kerning(0.6)

                Text(countdown)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(Color.orange)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.25), value: countdown)
            }

            Spacer()

            Image(systemName: "hourglass")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Color.orange.opacity(0.4))
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .background(Color.orange.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next workout unlocks in \(countdown)")
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
