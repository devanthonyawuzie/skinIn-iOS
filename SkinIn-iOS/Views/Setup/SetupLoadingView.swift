// Views/Setup/SetupLoadingView.swift
// SkinIn-iOS
//
// Step 3 — full-screen loading view shown while the profile API call runs.
// On success, navigates to BlueprintView rather than completing setup directly.
// The user must tap "Pay & Start Training Now" in BlueprintView to finalise
// setup; this prevents hasCompletedSetup being set before payment intent.

import SwiftUI

// MARK: - SetupLoadingView

struct SetupLoadingView: View {

    // MARK: ViewModel + Callbacks

    let vm: SetupViewModel
    /// Called when the user commits via BlueprintView (Pay button or dismiss).
    let onSetupComplete: () -> Void

    // MARK: Navigation State

    @State private var navigateToBlueprint = false

    // MARK: Body

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.96).ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                if let error = vm.errorMessage {
                    // Error state
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.brandGreen)
                        .accessibilityHidden(true)

                    Text("Something went wrong")
                        .font(.sectionHeadline)
                        .foregroundStyle(Color.black)
                        .multilineTextAlignment(.center)

                    Text(error)
                        .font(.bodyRegular)
                        .foregroundStyle(Color(white: 0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                        .accessibilityLabel("Error: \(error)")

                    Button(action: { vm.saveProfile(onSuccess: { navigateToBlueprint = true }) }) {
                        Text("Retry")
                            .font(.buttonLabel)
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.brandGreen)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.sm)
                    .accessibilityLabel("Retry profile setup")
                } else {
                    // Loading state
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.4)
                        .tint(Color.brandGreen)
                        .accessibilityLabel("Loading")

                    Text("Setting up your SkinIn...")
                        .font(.sectionHeadline)
                        .foregroundStyle(Color.black)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.sm)

                    Text("This only takes a second.")
                        .font(.bodyRegular)
                        .foregroundStyle(Color(white: 0.45))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        // Prevent any navigation chrome from appearing on this screen.
        .navigationBarBackButtonHidden(true)
        // Push to BlueprintView once saveProfile succeeds.
        .navigationDestination(isPresented: $navigateToBlueprint) {
            BlueprintView(
                goal: vm.goal ?? .muscleGain,
                onComplete: {
                    // Pop BlueprintView off the stack before switching the root
                    // to MainTabView. Without this, navigateToBlueprint stays
                    // true and SwiftUI leaves BlueprintView on screen even after
                    // hasCompletedSetup flips to true.
                    navigateToBlueprint = false
                    onSetupComplete()
                },
                onDismiss: { navigateToBlueprint = false }
            )
        }
        .onAppear {
            // Trigger save when this view first appears (step 3 entry).
            // Guard against re-triggering on error/retry cycles — saveProfile
            // is idempotent; the ViewModel guards isLoading internally.
            if vm.errorMessage == nil && !vm.isLoading {
                vm.saveProfile(onSuccess: { navigateToBlueprint = true })
            }
        }
    }
}

// MARK: - Previews

#Preview("Loading") {
    NavigationStack {
        SetupLoadingView(vm: SetupViewModel(), onSetupComplete: { })
    }
}

#Preview("Error") {
    let vm = SetupViewModel()
    // Simulate an error state for the preview.
    // In production this is set by SetupViewModel.saveProfile() on failure.
    let _ = { vm.errorMessage = "The server could not be reached. Check your internet connection." }()
    return NavigationStack {
        SetupLoadingView(vm: vm, onSetupComplete: { })
    }
}
