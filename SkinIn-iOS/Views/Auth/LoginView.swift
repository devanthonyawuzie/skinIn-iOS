// Views/Auth/LoginView.swift
// SkinIn-iOS
//
// Clean dark-themed login screen. All auth logic lives in LoginViewModel —
// this file contains only layout and bindings.

import SwiftUI

// MARK: - LoginView

struct LoginView: View {

    // MARK: ViewModel

    @State private var vm = LoginViewModel()

    // MARK: Body

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: Header
                    VStack(spacing: Spacing.md) {
                        SkinInBadge()
                            .padding(.top, Spacing.xxl)

                        Text("Welcome Back")
                            .font(.sectionHeadline)
                            .foregroundStyle(Color.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Spacing.xxl)

                    // MARK: Form Fields
                    VStack(spacing: Spacing.md) {
                        // Email
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Email")
                                .font(.badgeLabel)
                                .foregroundStyle(Color.textSecondary)

                            TextField("you@example.com", text: $vm.email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .foregroundStyle(Color.textPrimary)
                                .padding(Spacing.md)
                                .background(Color.fieldFill)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                                        .strokeBorder(Color.fieldBorder, lineWidth: 1)
                                )
                                .accessibilityLabel("Email address")
                        }

                        // Password
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Password")
                                .font(.badgeLabel)
                                .foregroundStyle(Color.textSecondary)

                            SecureField("••••••••", text: $vm.password)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                                .foregroundStyle(Color.textPrimary)
                                .padding(Spacing.md)
                                .background(Color.fieldFill)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                                        .strokeBorder(Color.fieldBorder, lineWidth: 1)
                                )
                                .accessibilityLabel("Password")
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    // MARK: Error Message
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.bodyRegular)
                            .foregroundStyle(Color.textError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)
                            .accessibilityLabel("Error: \(error)")
                    }

                    // MARK: Login Button
                    Button(action: {
                        Task { await vm.signIn() }
                    }) {
                        ZStack {
                            Color.brandGreen
                            if vm.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(Color.black)
                            } else {
                                Text("Log In")
                                    .font(.buttonLabel)
                                    .foregroundStyle(Color.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                    }
                    .disabled(!vm.canSubmit)
                    .opacity(vm.canSubmit ? 1.0 : 0.6)
                    .animation(.easeInOut(duration: 0.2), value: vm.isLoading)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xl)
                    .accessibilityLabel("Log In")
                    .accessibilityHint(vm.isLoading ? "Logging in, please wait" : "Sign in to your account")

                    // TODO: Re-add "Don't have an account? Sign up" link here
                    //       once the signup flow (email verify → Step1AboutYouView) is built.

                    // TODO: Apple & Google Sign In

                    Spacer(minLength: Spacing.xxl)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            // Dismiss keyboard on background tap
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LoginView()
    }
}
