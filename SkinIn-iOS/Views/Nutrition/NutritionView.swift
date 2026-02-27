// Views/Nutrition/NutritionView.swift
// SkinIn-iOS
//
// Nutrition tab — coming soon placeholder.

import SwiftUI

// MARK: - NutritionView

struct NutritionView: View {

    private let background = Color(red: 0.96, green: 0.96, blue: 0.96)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.brandGreen.opacity(0.12))
                        .frame(width: 80, height: 80)

                    Image(systemName: "fork.knife")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Color.brandGreen)
                }

                VStack(spacing: Spacing.xs) {
                    Text("Nutrition")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.black)

                    Text("Personalised meal plans and\nnutrition tracking coming soon.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(white: 0.50))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Spacing.xl)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Preview

#Preview {
    NutritionView()
}
