// Views/Profile/EditProfileView.swift
// SkinIn-iOS

import SwiftUI

// MARK: - EditProfileView

struct EditProfileView: View {

    // Passed in from ProfileView; reference type (@Observable) so mutations
    // are reflected back in ProfileView without needing a binding wrapper.
    var vm: ProfileViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: Local editable copies

    @State private var firstName: String
    @State private var lastName: String
    @State private var currentWeight: String
    @State private var goalWeight: String
    @State private var selectedGoal: String
    @State private var selectedLevel: String

    // MARK: - Init

    init(vm: ProfileViewModel) {
        self.vm = vm
        _firstName     = State(initialValue: vm.firstName)
        _lastName      = State(initialValue: vm.lastName)
        _currentWeight = State(initialValue: vm.currentWeight)
        _goalWeight    = State(initialValue: vm.goalWeight)
        _selectedGoal  = State(initialValue: vm.goal)
        _selectedLevel = State(initialValue: vm.experienceLevel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                EditProfileNavBar(
                    onBack: { dismiss() },
                    onSave: saveAndDismiss
                )

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        AvatarSection()

                        NameAndWeightCard(
                            firstName: $firstName,
                            lastName: $lastName,
                            currentWeight: $currentWeight,
                            goalWeight: $goalWeight
                        )

                        GoalPickerCard(selectedGoal: $selectedGoal)

                        ExperienceLevelCard(selectedLevel: $selectedLevel)

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Actions

    private func saveAndDismiss() {
        vm.firstName       = firstName
        vm.lastName        = lastName
        vm.currentWeight   = currentWeight
        vm.goalWeight      = goalWeight
        vm.goal            = selectedGoal
        vm.experienceLevel = selectedLevel
        vm.weightDisplay   = "\(currentWeight) lbs"
        dismiss()
    }
}

// MARK: - EditProfileNavBar

private struct EditProfileNavBar: View {
    let onBack: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack {
            // Center title
            Text("Edit Profile")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.black)

            HStack {
                // Back button — 44pt target
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")

                Spacer()

                // Save button
                Button(action: onSave) {
                    Text("Save")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.brandGreen)
                        .frame(height: 44)
                        .padding(.horizontal, Spacing.xs)
                }
                .accessibilityLabel("Save profile changes")
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 56)
        .background(Color.white)
    }
}

// MARK: - AvatarSection

private struct AvatarSection: View {
    var body: some View {
        VStack(spacing: 0) {
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
            // No-op tap — photo picker not yet implemented.
            .onTapGesture {}
            .accessibilityLabel("Change profile photo")
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - NameAndWeightCard

private struct NameAndWeightCard: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var currentWeight: String
    @Binding var goalWeight: String

    var body: some View {
        VStack(spacing: 0) {
            EditFieldRow(label: "FIRST NAME", placeholder: "First name", text: $firstName)
            Divider()
            EditFieldRow(label: "LAST NAME", placeholder: "Last name", text: $lastName)
            Divider()
            EditFieldRow(
                label: "CURRENT WEIGHT (LBS)",
                placeholder: "e.g. 185",
                text: $currentWeight,
                keyboardType: .decimalPad
            )
            Divider()
            EditFieldRow(
                label: "GOAL WEIGHT (LBS)",
                placeholder: "e.g. 175",
                text: $goalWeight,
                keyboardType: .decimalPad
            )
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
    }
}

// MARK: - EditFieldRow

private struct EditFieldRow: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(white: 0.55))
                .kerning(0.3)

            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundStyle(Color.black)
                .keyboardType(keyboardType)
                .accessibilityLabel(label)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - GoalPickerCard

private struct GoalPickerCard: View {
    @Binding var selectedGoal: String

    private let goals = ["Muscle Gain", "Fat Loss", "Body Recomposition"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("GOAL")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(white: 0.55))
                .kerning(0.3)

            // Allow chips to wrap onto multiple lines when the screen is narrow.
            HStack(spacing: Spacing.sm) {
                ForEach(goals, id: \.self) { option in
                    Text(option)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedGoal == option ? Color.black : Color(white: 0.50))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedGoal == option ? Color.brandGreen : Color(white: 0.92))
                        .clipShape(Capsule())
                        .onTapGesture { selectedGoal = option }
                        .accessibilityLabel(option)
                        .accessibilityAddTraits(selectedGoal == option ? .isSelected : [])
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
    }
}

// MARK: - ExperienceLevelCard

private struct ExperienceLevelCard: View {
    @Binding var selectedLevel: String

    private let levels = ["Beginner", "Intermediate"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("EXPERIENCE LEVEL")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(white: 0.55))
                .kerning(0.3)

            HStack(spacing: Spacing.sm) {
                ForEach(levels, id: \.self) { level in
                    Text(level)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedLevel == level ? Color.black : Color(white: 0.50))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedLevel == level ? Color.brandGreen : Color(white: 0.92))
                        .clipShape(Capsule())
                        .onTapGesture { selectedLevel = level }
                        .accessibilityLabel(level)
                        .accessibilityAddTraits(selectedLevel == level ? .isSelected : [])
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
    }
}

// MARK: - Preview

#Preview {
    EditProfileView(vm: ProfileViewModel())
}
