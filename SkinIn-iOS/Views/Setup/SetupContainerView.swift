// Views/Setup/SetupContainerView.swift
// SkinIn-iOS
//
// Root container for the post-login setup flow.
// Owns SetupViewModel, renders SetupProgressBar, and switches on vm.currentStep.
// No business logic lives here — all logic is in SetupViewModel.

import SwiftUI

// MARK: - SetupContainerView

struct SetupContainerView: View {

    // MARK: Dependencies

    /// Called by the app root (SkinIn_iOSApp) when setup finishes successfully.
    let onSetupComplete: () -> Void

    // MARK: ViewModel

    @State private var vm = SetupViewModel()

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar — pinned at the very top, shared across all steps.
            SetupProgressBar(currentStep: vm.currentStep)
                .padding(.top, Spacing.md)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)

            // Step content fills remaining space.
            stepContent
        }
        .navigationBarBackButtonHidden(true)
        .background(
            // Step 3 uses dark background; steps 1 & 2 use light gray.
            vm.currentStep == 3
                ? Color.appBackground.ignoresSafeArea()
                : Color(red: 0.96, green: 0.96, blue: 0.96).ignoresSafeArea()
        )
        .alert("Setup Failed", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("Retry") { vm.saveProfile(onSuccess: onSetupComplete) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "An unexpected error occurred. Please try again.")
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.currentStep)
    }

    // MARK: - Step Routing

    @ViewBuilder
    private var stepContent: some View {
        switch vm.currentStep {
        case 1:
            Step1AboutYouView(vm: vm)
        case 2:
            Step2GoalsView(vm: vm)
        default:
            SetupLoadingView(vm: vm, onSetupComplete: onSetupComplete)
        }
    }
}

// MARK: - SetupProgressBar

/// Three-capsule progress indicator. Active/completed dots are wide green
/// pills; inactive dots are small gray circles.
/// Internal (not private) so step view previews can reference it.
struct SetupProgressBar: View {

    let currentStep: Int  // 1, 2, or 3

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(1...3, id: \.self) { step in
                Capsule()
                    .fill(dotColor(for: step))
                    .frame(width: dotWidth(for: step), height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentStep)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Setup progress, step \(currentStep) of 3")
        .accessibilityValue("\(currentStep) of 3 completed")
    }

    // MARK: Helpers

    private func dotColor(for step: Int) -> Color {
        step <= currentStep ? Color.brandGreen : Color.gray.opacity(0.3)
    }

    private func dotWidth(for step: Int) -> CGFloat {
        step <= currentStep ? 28 : 8
    }
}

// MARK: - Preview

#Preview("Step 1") {
    NavigationStack {
        SetupContainerView(onSetupComplete: { })
    }
}

#Preview("Progress Bar") {
    VStack(spacing: Spacing.lg) {
        SetupProgressBar(currentStep: 1)
        SetupProgressBar(currentStep: 2)
        SetupProgressBar(currentStep: 3)
    }
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
}
