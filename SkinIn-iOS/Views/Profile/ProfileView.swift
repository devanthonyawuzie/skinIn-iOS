// Views/Profile/ProfileView.swift
// SkinIn-iOS

import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    @State private var vm = ProfileViewModel()

    var body: some View {
        // NavigationStack required so .navigationDestination works for EditProfileView.
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.96, blue: 0.96)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ProfileNavBar()

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            ProfileHeaderSection(vm: vm)

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
            // Avatar with green ring and pencil badge
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .strokeBorder(Color.brandGreen, lineWidth: 3)
                    .frame(width: 94, height: 94)

                Circle()
                    .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
                    .frame(width: 86, height: 86)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(Color(white: 0.65))
                    )

                // Pencil badge
                ZStack {
                    Circle()
                        .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
                        .frame(width: 26, height: 26)
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .offset(x: 4, y: 4)
            }
            .frame(width: 94, height: 94)
            .accessibilityLabel("Profile photo")

            Text(vm.fullName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.black)

            Button {
                vm.showEditProfile = true
            } label: {
                Text("Edit Profile")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(red: 0.10, green: 0.12, blue: 0.18))
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

// MARK: - StatsRow

private struct StatsRow: View {
    let vm: ProfileViewModel

    var body: some View {
        HStack(spacing: Spacing.sm) {
            StatCard(
                icon: "💰",
                label: "Protected",
                value: vm.protectedAmount,
                isEmoji: true,
                iconColor: .clear
            )
            StatCard(
                icon: "flame.fill",
                label: "Streak",
                value: "\(vm.streakDays) Days",
                isEmoji: false,
                iconColor: .orange
            )
            StatCard(
                icon: "⚖️",
                label: "Weight",
                value: vm.weightDisplay,
                isEmoji: true,
                iconColor: .clear
            )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let isEmoji: Bool
    let iconColor: Color

    var body: some View {
        VStack(spacing: 6) {
            if isEmoji {
                Text(icon)
                    .font(.system(size: 28))
            } else {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(iconColor)
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(white: 0.55))

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.black)
        }
        .frame(maxWidth: .infinity)
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
                    icon: "gearshape.fill",
                    title: "Account Settings",
                    subtitle: nil,
                    subtitleColor: nil
                )
                Divider().padding(.leading, 56)

                SettingsRow(
                    icon: "creditcard.fill",
                    title: "Subscription & Wager",
                    subtitle: vm.planLabel,
                    subtitleColor: Color.brandGreen
                )
                Divider().padding(.leading, 56)

                SettingsRow(
                    icon: "camera.fill",
                    title: "Progress Photos",
                    subtitle: nil,
                    subtitleColor: nil
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
                        .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
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
