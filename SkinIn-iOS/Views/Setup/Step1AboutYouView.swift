// Views/Setup/Step1AboutYouView.swift
// SkinIn-iOS
//
// Setup step 1: collect first name, last name, and date of birth.
// Light gray background. Progress bar lives in SetupContainerView above.
// Pure layout — all validation lives in SetupViewModel.

import SwiftUI

// MARK: - Step1AboutYouView

struct Step1AboutYouView: View {

    // MARK: ViewModel

    let vm: SetupViewModel

    // MARK: Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Back Button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .accessibilityLabel("Go back")
                .padding(.top, Spacing.md)
                .padding(.horizontal, Spacing.lg)

                // MARK: Header
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("About You")
                        .font(.displayHeadline)
                        .foregroundStyle(Color.black)
                        .accessibilityAddTraits(.isHeader)

                    Text("Tell us a bit about yourself to get started with your fitness journey.")
                        .font(.bodyRegular)
                        .foregroundStyle(Color(white: 0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, Spacing.lg)
                .padding(.horizontal, Spacing.lg)

                // MARK: Name Fields
                HStack(spacing: Spacing.md) {
                    NameField(
                        label: "First Name",
                        placeholder: "Jane",
                        text: Binding(
                            get: { vm.firstName },
                            set: { vm.firstName = $0 }
                        ),
                        contentType: .givenName
                    )

                    NameField(
                        label: "Last Name",
                        placeholder: "Doe",
                        text: Binding(
                            get: { vm.lastName },
                            set: { vm.lastName = $0 }
                        ),
                        contentType: .familyName
                    )
                }
                .padding(.top, Spacing.xl)
                .padding(.horizontal, Spacing.lg)

                // MARK: Date of Birth
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Date of Birth")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.black)

                    // White card wrapping the native wheel date picker.
                    VStack {
                        DatePicker(
                            "Date of Birth",
                            selection: Binding(
                                get: { vm.dateOfBirth },
                                set: { vm.dateOfBirth = $0 }
                            ),
                            in: ...vm.maximumDOB,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        // Tint the picker wheels to match the brand.
                        .tint(Color.brandGreen)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, Spacing.sm)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)

                    Text("We use this to calculate your fitness metrics.")
                        .font(.caption)
                        .foregroundStyle(Color(white: 0.55))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityHidden(true)
                }
                .padding(.top, Spacing.xl)
                .padding(.horizontal, Spacing.lg)

                // MARK: Sex
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Sex")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.black)

                    HStack(spacing: Spacing.sm) {
                        ForEach(["Male", "Female", "Other"], id: \.self) { option in
                            Button(action: { vm.sex = option }) {
                                Text(option)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(vm.sex == option ? Color.black : Color(white: 0.45))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(vm.sex == option ? Color.brandGreen : Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(option)
                            .accessibilityAddTraits(vm.sex == option ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                }
                .padding(.top, Spacing.xl)
                .padding(.horizontal, Spacing.lg)

                Spacer(minLength: Spacing.xxl)
            }
        }
        .scrollBounceBehavior(.basedOnSize)

        // MARK: Continue Button (outside scroll, pinned to bottom)
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
            .disabled(!vm.canProceedStep1)
            .opacity(vm.canProceedStep1 ? 1.0 : 0.5)
            .animation(.easeInOut(duration: 0.2), value: vm.canProceedStep1)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
            .accessibilityLabel("Continue to next step")
            .accessibilityHint(vm.canProceedStep1 ? "" : "Enter your first and last name to continue")
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
    }
}

// MARK: - NameField

/// Reusable label + text field component for the name row.
private struct NameField: View {

    let label: String
    let placeholder: String
    @Binding var text: String
    let contentType: UITextContentType

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.badgeLabel)
                .foregroundStyle(Color(white: 0.45))

            TextField(placeholder, text: $text)
                .textContentType(contentType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .foregroundStyle(Color.black)
                .padding(Spacing.md)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                .accessibilityLabel(label)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VStack(spacing: 0) {
            SetupProgressBar(currentStep: 1)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))

            Step1AboutYouView(vm: SetupViewModel())
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
        .navigationBarBackButtonHidden(true)
    }
}
