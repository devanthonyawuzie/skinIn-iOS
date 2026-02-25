// Views/Onboarding/OnboardingPage2View.swift
// SkinIn-iOS
//
// Onboarding page 2: "Meet Momentum"
// Pure layout — no logic.

import SwiftUI

// MARK: - OnboardingPage2View

struct OnboardingPage2View: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.08), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                Image(systemName: "bolt.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 120)
                    .foregroundStyle(Color.brandGreen)
                    .shadow(color: Color.brandGreen.opacity(0.5), radius: 30, x: 0, y: 0)
                Spacer()
                Color.clear.frame(height: 260)
            }

            BottomCard {
                Group {
                    Text("Meet ")
                        .foregroundStyle(Color.black)
                    + Text("Momentum")
                        .foregroundStyle(Color.brandGreen)
                }
                .font(.displayHeadline)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Meet Momentum")

                Text("Your AI-powered coach that keeps you accountable, motivated, and on track every single day.")
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

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

#Preview("Page 2") {
    OnboardingPage2View()
}
