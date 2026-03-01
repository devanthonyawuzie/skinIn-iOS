// Views/Setup/Step2GoalsView.swift
// SkinIn-iOS
//
// Setup step 2: select a fitness goal, enter weight stats, and optionally
// enable geofencing / push notifications / HealthKit.
// Light gray background. Progress bar lives in SetupContainerView.
// Pure layout — all permission requests and validation live in SetupViewModel.

import SwiftUI

// MARK: - Step2GoalsView

struct Step2GoalsView: View {

    // MARK: ViewModel

    let vm: SetupViewModel

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Back Button
                Button(action: { vm.previousStep() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("Go back to About You")
                .padding(.top, Spacing.md)
                .padding(.horizontal, Spacing.lg)

                // MARK: Header — inline "SkinIn" highlight
                titleView
                    .padding(.top, Spacing.lg)
                    .padding(.horizontal, Spacing.lg)

                Text("Select your primary objective to customize your challenge.")
                    .font(.bodyRegular)
                    .foregroundStyle(Color(white: 0.45))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.sm)
                    .padding(.horizontal, Spacing.lg)

                // MARK: Goal Cards
                sectionHeader("Main Focus")
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.lg)

                VStack(spacing: Spacing.sm) {
                    ForEach(Goal.allCases, id: \.rawValue) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: vm.goal == goal,
                            onSelect: { vm.goal = goal }
                        )
                    }
                }
                .padding(.top, Spacing.sm)
                .padding(.horizontal, Spacing.lg)

                // MARK: Experience Level
                sectionHeader("Experience Level")
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.lg)

                HStack(spacing: Spacing.sm) {
                    ForEach(ExperienceLevel.allCases, id: \.rawValue) { level in
                        ExperienceLevelCard(
                            level: level,
                            isSelected: vm.experienceLevel == level,
                            onSelect: { vm.experienceLevel = level }
                        )
                    }
                }
                .padding(.top, Spacing.sm)
                .padding(.horizontal, Spacing.lg)

                // MARK: Weight Stats
                sectionHeader("Your Stats")
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.lg)

                HStack(spacing: Spacing.md) {
                    WeightField(
                        label: "CURRENT WEIGHT",
                        text: Binding(
                            get: { vm.currentWeight },
                            set: { vm.currentWeight = $0 }
                        )
                    )
                    WeightField(
                        label: "GOAL WEIGHT",
                        text: Binding(
                            get: { vm.goalWeight },
                            set: { vm.goalWeight = $0 }
                        )
                    )
                }
                .padding(.top, Spacing.sm)
                .padding(.horizontal, Spacing.lg)

                // MARK: Permission Toggles
                sectionHeader("Permissions")
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.lg)

                VStack(spacing: Spacing.sm) {
                    PermissionToggleRow(
                        assetName: "perm.gym.geofencing",
                        fallbackSymbol: "location.fill",
                        title: "Gym Geofencing",
                        subtitle: "We verify your check-ins via GPS to ensure you're actually at the gym.",
                        isOn: Binding(
                            get: { vm.gymGeofencingEnabled },
                            set: { newValue in
                                vm.gymGeofencingEnabled = newValue
                                if newValue { vm.requestLocationPermission() }
                            }
                        )
                    )

                    PermissionToggleRow(
                        assetName: "perm.push.notifications",
                        fallbackSymbol: "bell.fill",
                        title: "Push Notifications",
                        subtitle: "Get timely reminders for workouts and challenge updates.",
                        isOn: Binding(
                            get: { vm.pushNotificationsEnabled },
                            set: { newValue in
                                vm.pushNotificationsEnabled = newValue
                                if newValue { vm.requestNotificationPermission() }
                            }
                        )
                    )

                    PermissionToggleRow(
                        assetName: "perm.healthkit",
                        fallbackSymbol: "heart.fill",
                        title: "Apple HealthKit Access",
                        subtitle: "Sync your health data to track your progress automatically.",
                        isOn: Binding(
                            get: { vm.healthKitEnabled },
                            set: { newValue in
                                vm.healthKitEnabled = newValue
                                if newValue { vm.requestHealthKitPermission() }
                            }
                        )
                    )
                }
                .padding(.top, Spacing.sm)
                .padding(.horizontal, Spacing.lg)

                Spacer(minLength: Spacing.xxl)
            }
        }
        .scrollBounceBehavior(.basedOnSize)

        // MARK: Next Button (pinned to bottom, outside scroll)
        VStack {
            Button(action: { vm.handleStep3NextTap() }) {
                Text("Next: Set Your Wager \u{2192}")
                    .font(.buttonLabel)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            }
            .disabled(!vm.canProceedStep2)
            .opacity(vm.canProceedStep2 ? 1.0 : 0.5)
            .animation(.easeInOut(duration: 0.2), value: vm.canProceedStep2)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
            .accessibilityLabel("Next: Set Your Wager")
            .accessibilityHint(vm.canProceedStep2 ? "" : "Select a goal and enter your weight to continue")
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
        .alert("Before You Continue", isPresented: Binding(
            get: { vm.showPermissionAlert },
            set: { vm.showPermissionAlert = $0 }
        )) {
            Button("Enable Now") {
                // Dismiss alert; user stays on page to enable toggles.
            }
            Button("Continue Anyway") {
                vm.continueAnywayFromPermissionAlert()
            }
        } message: {
            Text(
                "Gym Geofencing helps us verify you're actually at the gym. " +
                "Push Notifications keep you on track. " +
                "HealthKit lets us track your real progress. " +
                "You can enable these later in Settings."
            )
        }
    }

    // MARK: - Title with inline "SkinIn" highlight

    private var titleView: some View {
        // "Let's put some " [SkinIn] "\nthe game."
        // Using Text concatenation to inline a highlighted word.
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Let\u{2019}s put some ")
                .font(.displayHeadline)
                .foregroundStyle(Color.black)

            Text("SkinIn")
                .font(.displayHeadline)
                .foregroundStyle(Color.black)
                .padding(.horizontal, 4)
                .background(
                    Color.brandGreen.opacity(0.18)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                )

            Text("\nthe game.")
                .font(.displayHeadline)
                .foregroundStyle(Color.black)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Let's put some SkinIn the game.")
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Section Header

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.badgeLabel)
            .foregroundStyle(Color(white: 0.50))
            .kerning(0.5)
    }
}

// MARK: - GoalCard

private struct GoalCard: View {

    let goal: Goal
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Icon — try named asset first, fall back to SF Symbol.
                Group {
                    if UIImage(named: goal.assetName) != nil {
                        Image(goal.assetName)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: goal.sfSymbolFallback)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.brandGreen)
                    }
                }
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.black)

                    Text(goal.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(white: 0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Selection checkmark
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandGreen : Color(white: 0.90))
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            .padding(Spacing.md)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.brandGreen : Color.clear,
                        lineWidth: 2
                    )
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(goal.displayName): \(goal.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - WeightField

private struct WeightField: View {

    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.badgeLabel)
                .foregroundStyle(Color(white: 0.45))

            HStack(spacing: Spacing.xs) {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(Color.black)
                    .accessibilityLabel(label)

                Text("LBS")
                    .font(.badgeLabel)
                    .foregroundStyle(Color(white: 0.50))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ExperienceLevelCard

private struct ExperienceLevelCard: View {

    let level: ExperienceLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandGreen : Color(white: 0.92))
                        .frame(width: 44, height: 44)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.black)
                    } else {
                        Image(systemName: level.sfSymbol)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(white: 0.55))
                    }
                }

                Text(level.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.black)

                Text(level.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color(white: 0.50))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                    .strokeBorder(isSelected ? Color.brandGreen : Color.clear, lineWidth: 2)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(level.displayName): \(level.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - PermissionToggleRow

private struct PermissionToggleRow: View {

    let assetName: String
    let fallbackSymbol: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Icon
            Group {
                if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: fallbackSymbol)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.brandGreen)
                }
            }
            .frame(width: 22, height: 22)
            .padding(.top, 2)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.black)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(white: 0.45))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.brandGreen)
                .accessibilityLabel(title)
                .accessibilityValue(isOn ? "enabled" : "disabled")
        }
        .padding(Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VStack(spacing: 0) {
            SetupProgressBar(currentStep: 2)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))

            Step2GoalsView(vm: SetupViewModel())
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
        .navigationBarBackButtonHidden(true)
    }
}
