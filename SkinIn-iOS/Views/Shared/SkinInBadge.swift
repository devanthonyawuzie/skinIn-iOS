// Views/Shared/SkinInBadge.swift
// SkinIn-iOS
//
// Reusable pill badge used on onboarding page 3, LoginView, and HomeView.

import SwiftUI

// MARK: - SkinInBadge

public struct SkinInBadge: View {
    public init() {}

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.brandGreen)
            Text("SkinIn")
                .font(.badgeLabel)
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        SkinInBadge()
    }
}
