// Views/Onboarding/OnboardingPage1View.swift
// SkinIn-iOS
//
// Onboarding page 1: "Pledge Your Way to Results"
// Pure layout — no logic.

import SwiftUI

// MARK: - OnboardingPage1View

struct OnboardingPage1View: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(white: 0.08), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Hero icon area
                Spacer()
                Image(systemName: "dollarsign.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(Color.brandGreen)
                    .shadow(color: Color.brandGreen.opacity(0.5), radius: 30, x: 0, y: 0)
                Spacer()

                // Bottom card — spacer to offset the card height
                Color.clear.frame(height: 260)
            }

            BottomCard {
                // Headline
                Group {
                    Text("Pledge Your ")
                        .foregroundStyle(Color.black)
                    + Text("Way to Results")
                        .foregroundStyle(Color.brandGreen)
                }
                .font(.displayHeadline)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Pledge Your Way to Results")

                // Subtitle
                Text("Put real money on the line. Stay consistent and keep every penny.")
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Swipe hint
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                    Text("Swipe to continue")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, Spacing.xs)
            }
        }
    }
}

// MARK: - BottomCard

/// Reusable white rounded card anchored to the bottom of the screen.
/// Private to the Onboarding group — only page views use it.
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
            // Extra bottom padding so content clears the page indicator + home indicator
            .padding(.bottom, Spacing.xxl + Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardWhite)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Preview

#Preview("Page 1") {
    OnboardingPage1View()
}
