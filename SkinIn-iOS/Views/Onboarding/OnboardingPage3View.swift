// Views/Onboarding/OnboardingPage3View.swift
// SkinIn-iOS
//
// Onboarding page 3: "Get Fit or Get Your Money Back"
// Receives onGetStarted closure from OnboardingView. Pure layout — no logic.

import SwiftUI

// MARK: - OnboardingPage3View

struct OnboardingPage3View: View {
    let onGetStarted: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Dark gym aesthetic background
            LinearGradient(
                colors: [Color(white: 0.06), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Hero icon — strength training silhouette
                Spacer()
                Image(systemName: "figure.strengthtraining.traditional")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 130)
                    .foregroundStyle(Color.brandGreen)
                    .shadow(color: Color.brandGreen.opacity(0.45), radius: 30, x: 0, y: 0)
                Spacer()
                Color.clear.frame(height: 300)
            }

            // MOMENTUM badge — top-leading
            MomentumBadge()
                .padding(.top, Spacing.xl + Spacing.lg)
                .padding(.leading, Spacing.lg)
                .accessibilityLabel("Momentum app badge")

            // Bottom card with CTA
            BottomCard {
                Group {
                    Text("Get Fit or Get\n")
                        .foregroundStyle(Color.black)
                    + Text("Your Money Back")
                        .foregroundStyle(Color.brandGreen)
                }
                .font(.displayHeadline)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Get Fit or Get Your Money Back")

                Text("The only fitness app that pays you to stay consistent. Pledge money, check in, keep it.")
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Primary CTA
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(.buttonLabel)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                }
                .padding(.top, Spacing.sm)
                .accessibilityLabel("Get Started")
                .accessibilityHint("Navigates to account creation or login")

                // Secondary link
                Button(action: onGetStarted) {
                    Text("Already have an account? ")
                        .foregroundStyle(Color.textSecondary)
                    + Text("Log in")
                        .foregroundStyle(Color.black)
                }
                .font(.linkLabel)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xs)
                .accessibilityLabel("Already have an account? Log in")
            }
        }
    }
}

// MARK: - BottomCard

private struct BottomCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: Spacing.md) {
                content()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl + Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardWhite)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Preview

#Preview("Page 3") {
    OnboardingPage3View(onGetStarted: {})
}
