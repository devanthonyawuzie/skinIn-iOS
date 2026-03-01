// Views/Profile/ProfileView.swift
// SkinIn-iOS

import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    @State private var vm = ProfileViewModel()

    private let background = Color(red: 0.96, green: 0.96, blue: 0.96)

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ProfileNavBar()

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            ProfileHeaderSection(vm: vm)

                            WeekProgressCard(
                                currentWeek: vm.currentWeek,
                                completedWorkouts: vm.completedWorkouts,
                                totalWorkoutsThisWeek: vm.totalWorkoutsThisWeek
                            )
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)

                            RefundStatusCard(
                                refundEligible: vm.refundEligible,
                                graceDayUsed: vm.graceDayUsed
                            )
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.sm)

                            StatsRow(vm: vm)

                            SettingsSection(vm: vm)

                            LogOutButton(vm: vm)

                            VersionLabel(vm: vm)

                            Spacer(minLength: 80)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: Binding(
                get: { vm.showEditProfile },
                set: { vm.showEditProfile = $0 }
            )) {
                EditProfileView(vm: vm)
            }
            .task { await vm.fetchAll() }
        }
    }
}

// MARK: - ProfileNavBar

private struct ProfileNavBar: View {
    var body: some View {
        HStack {
            Text("Profile")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color.black)
                .accessibilityAddTraits(.isHeader)

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: 56)
        .background(Color.white.ignoresSafeArea(edges: .top))
    }
}

// MARK: - ProfileHeaderSection

private struct ProfileHeaderSection: View {
    let vm: ProfileViewModel

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Name above avatar
            if !vm.fullName.isEmpty {
                Text(vm.fullName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Avatar with green ring
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .strokeBorder(Color.brandGreen, lineWidth: 3)
                    .frame(width: 94, height: 94)

                Circle()
                    .fill(Color(white: 0.92))
                    .frame(width: 86, height: 86)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(Color(white: 0.65))
                    )

                // Pencil badge
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 26, height: 26)
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .offset(x: 4, y: 4)
            }
            .frame(width: 94, height: 94)
            .accessibilityLabel("Profile photo")

            Button {
                vm.showEditProfile = true
            } label: {
                Text("Edit Profile")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            }
            .accessibilityLabel("Edit Profile")
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }
}

// MARK: - WeekProgressCard

private struct WeekProgressCard: View {

    let currentWeek: Int
    let completedWorkouts: Int
    let totalWorkoutsThisWeek: Int

    private var trailingMessage: String {
        guard totalWorkoutsThisWeek > 0 else { return " workouts this week." }
        let remaining = totalWorkoutsThisWeek - completedWorkouts
        switch remaining {
        case ..<1: return " workouts. You've completed all workouts this week!"
        case 1:    return " workouts. Just one more to lock in this week's deposit!"
        default:   return " workouts. \(remaining) more to go this week!"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {

            ZStack {
                Circle()
                    .fill(Color.brandGreen.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "arrow.trianglehead.2.counterclockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.brandGreen)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {

                Text("Week \(currentWeek) Progress")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black)
                    .accessibilityAddTraits(.isHeader)

                (
                    Text("You've crushed ")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(white: 0.40))
                    + Text("\(completedWorkouts)/\(totalWorkoutsThisWeek)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.brandGreen)
                    + Text(trailingMessage)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(white: 0.40))
                )
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(
                    "You've crushed \(completedWorkouts) of \(totalWorkoutsThisWeek) workouts.\(trailingMessage)"
                )
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - RefundStatusCard

private struct RefundStatusCard: View {

    let refundEligible: Bool
    let graceDayUsed: Bool

    private var icon: String {
        if !refundEligible { return "xmark.circle.fill" }
        if graceDayUsed    { return "exclamationmark.triangle.fill" }
        return "checkmark.circle.fill"
    }

    private var iconColor: Color {
        if !refundEligible { return Color(red: 0.85, green: 0.15, blue: 0.15) }
        if graceDayUsed    { return Color.orange }
        return Color.brandGreen
    }

    private var title: String {
        if !refundEligible { return "Refund Eligibility Lost" }
        if graceDayUsed    { return "Grace Day Used This Week" }
        return "Refund Eligible"
    }

    private var subtitle: String {
        if !refundEligible { return "You missed the required workouts two weeks in a row." }
        if graceDayUsed    { return "Complete 4 workouts every remaining week to stay eligible." }
        return "Complete 4 workouts per week to keep your refund."
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.black)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.50))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - StatsRow

private struct StatsRow: View {
    let vm: ProfileViewModel

    var body: some View {
        StatCard(
            icon: "flame.fill",
            label: "Streak",
            value: "\(vm.streakDays) Days",
            iconColor: .orange
        )
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.55))
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - SettingsSection

private struct SettingsSection: View {
    let vm: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SETTINGS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(white: 0.55))
                .kerning(0.8)
                .padding(.bottom, Spacing.sm)

            VStack(spacing: 0) {
                SettingsRow(
                    icon: "creditcard.fill",
                    title: "Subscription & Wager",
                    subtitle: vm.planLabel,
                    subtitleColor: Color.brandGreen
                )
                Divider().padding(.leading, 56)

                SettingsRow(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    subtitle: "Geofencing & Alerts",
                    subtitleColor: nil
                )
                Divider().padding(.leading, 56)

                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: nil,
                    subtitleColor: nil
                )
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
    }
}

// MARK: - SettingsRow

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let subtitleColor: Color?

    var body: some View {
        Button(action: {}) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.black)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(subtitleColor ?? Color(white: 0.55))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(white: 0.75))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - LogOutButton

private struct LogOutButton: View {
    let vm: ProfileViewModel

    var body: some View {
        Button(action: vm.signOut) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                Text("Log Out")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Color(red: 0.85, green: 0.15, blue: 0.15))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .accessibilityLabel("Log Out")
    }
}

// MARK: - VersionLabel

private struct VersionLabel: View {
    let vm: ProfileViewModel

    var body: some View {
        Text(vm.appVersion)
            .font(.system(size: 12))
            .foregroundStyle(Color(white: 0.60))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.top, Spacing.md)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
