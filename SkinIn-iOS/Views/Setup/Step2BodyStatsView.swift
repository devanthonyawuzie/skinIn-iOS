// Views/Setup/Step2BodyStatsView.swift
// SkinIn-iOS
//
// Setup step 2: collect sex/gender, height (ft + in), and activity level.
// Light gray background. Progress bar lives in SetupContainerView.
// Pure layout — all validation lives in SetupViewModel.

import SwiftUI

// MARK: - Step2BodyStatsView

struct Step2BodyStatsView: View {

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

                // MARK: Header
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Body Stats")
                        .font(.displayHeadline)
                        .foregroundStyle(Color.black)
                        .accessibilityAddTraits(.isHeader)

                    Text("Help us personalise your plan with accurate calorie and macro targets.")
                        .font(.bodyRegular)
                        .foregroundStyle(Color(white: 0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, Spacing.lg)
                .padding(.horizontal, Spacing.lg)

                // MARK: Sex
                sectionHeader("Sex")
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.lg)

                HStack(spacing: Spacing.sm) {
                    ForEach(["Male", "Female"], id: \.self) { option in
                        Button(action: { vm.sex = option }) {
                            Text(option)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(vm.sex == option ? Color.black : Color(white: 0.45))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(vm.sex == option ? Color.brandGreen : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                                        .strokeBorder(vm.sex == option ? Color.brandGreen : Color.clear, lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: vm.sex)
                        .accessibilityLabel(option)
                        .accessibilityAddTraits(vm.sex == option ? [.isButton, .isSelected] : .isButton)
                    }
                }
                .padding(.top, Spacing.sm)
                .padding(.horizontal, Spacing.lg)

                // MARK: Height
                sectionHeader("Height")
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.lg)

                HStack(spacing: Spacing.md) {
                    HeightField(
                        label: "FT",
                        placeholder: "5",
                        text: Binding(
                            get: { vm.heightFeet },
                            set: { vm.heightFeet = $0 }
                        )
                    )
                    HeightField(
                        label: "IN",
                        placeholder: "7",
                        text: Binding(
                            get: { vm.heightInches },
                            set: { vm.heightInches = $0 }
                        )
                    )
                }
                .padding(.top, Spacing.sm)
                .padding(.horizontal, Spacing.lg)

                // MARK: Activity Level
                sectionHeader("Activity Level")
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.lg)

                Text("How active are you outside of planned workouts?")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.50))
                    .padding(.top, 4)
                    .padding(.horizontal, Spacing.lg)

                VStack(spacing: Spacing.sm) {
                    ForEach(ActivityLevel.allCases, id: \.rawValue) { level in
                        ActivityLevelCard(
                            level: level,
                            isSelected: vm.activityLevel == level,
                            onSelect: { vm.activityLevel = level }
                        )
                    }
                }
                .padding(.top, Spacing.sm)
                .padding(.horizontal, Spacing.lg)

                Spacer(minLength: Spacing.xxl)
            }
        }
        .scrollBounceBehavior(.basedOnSize)

        // MARK: Continue Button (pinned to bottom, outside scroll)
        VStack {
            Button(action: { vm.nextStep() }) {
                Text("Continue \u{2192}")
                    .font(.buttonLabel)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            }
            .disabled(!vm.canProceedBodyStats)
            .opacity(vm.canProceedBodyStats ? 1.0 : 0.5)
            .animation(.easeInOut(duration: 0.2), value: vm.canProceedBodyStats)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
            .accessibilityLabel("Continue to Goals")
            .accessibilityHint(vm.canProceedBodyStats ? "" : "Enter your height to continue")
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
    }

    // MARK: - Section Header

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.badgeLabel)
            .foregroundStyle(Color(white: 0.50))
            .kerning(0.5)
    }
}

// MARK: - HeightField

private struct HeightField: View {

    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                TextField(placeholder, text: $text)
                    .keyboardType(.numberPad)
                    .foregroundStyle(Color.black)
                    .accessibilityLabel(label == "FT" ? "Feet" : "Inches")

                Text(label)
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

// MARK: - ActivityLevelCard

private struct ActivityLevelCard: View {

    let level: ActivityLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandGreen : Color(white: 0.92))
                        .frame(width: 40, height: 40)

                    Image(systemName: isSelected ? "checkmark" : level.sfSymbol)
                        .font(.system(size: isSelected ? 14 : 18, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? Color.black : Color(white: 0.55))
                }
                .animation(.easeInOut(duration: 0.15), value: isSelected)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)

                    Text(level.activityDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.45))
                }

                Spacer()
            }
            .padding(Spacing.md)
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
        .accessibilityLabel("\(level.displayName): \(level.activityDescription)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
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

            Step2BodyStatsView(vm: SetupViewModel())
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
        .navigationBarBackButtonHidden(true)
    }
}
