// Views/Onboarding/OnboardingView.swift
// SkinIn-iOS
//
// Container for the 3-page onboarding flow. Owns the OnboardingViewModel,
// renders the TabView and PageDotIndicator. Page content lives in the
// individual OnboardingPage*View files.

import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {

    let onFinished: () -> Void

    @State private var vm = OnboardingViewModel()
    @State private var navigateToLogin = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            TabView(selection: $vm.currentPage) {
                OnboardingPage1View()
                    .tag(0)

                OnboardingPage2View()
                    .tag(1)

                OnboardingPage3View(onGetStarted: {
                    vm.finish {
                        onFinished()
                    }
                    navigateToLogin = true
                })
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: vm.currentPage)

            // Custom dot indicator pinned to bottom
            VStack {
                Spacer()
                PageDotIndicator(totalPages: vm.totalPages, currentPage: vm.currentPage)
                    .padding(.bottom, Spacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToLogin) {
            LoginView()
        }
    }
}

// MARK: - PageDotIndicator

private struct PageDotIndicator: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.brandGreen : Color.white.opacity(0.35))
                    .frame(width: index == currentPage ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

// MARK: - Preview

#Preview("Onboarding Flow") {
    OnboardingView(onFinished: {})
}
