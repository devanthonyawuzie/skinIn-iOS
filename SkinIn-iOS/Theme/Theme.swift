// Theme/Theme.swift
// SkinIn-iOS
//
// Central design token system. All colors, typography, and spacing
// values must be referenced from here — never hardcode hex values in views.

import SwiftUI

// MARK: - Colors

extension Color {
    /// Rich black used for the main app background
    static let appBackground = Color(red: 0.05, green: 0.05, blue: 0.05)

    /// Slightly lighter surface for layered cards/sheets
    static let surfaceDark = Color(red: 0.10, green: 0.10, blue: 0.10)

    /// White card background used on onboarding bottom cards
    static let cardWhite = Color.white

    /// Body text on dark backgrounds
    static let textPrimary = Color.white

    /// Secondary/subtitle text on dark backgrounds
    static let textSecondary = Color(white: 0.60)

    /// Error state text
    static let textError = Color(red: 1.0, green: 0.27, blue: 0.27)

    /// Text fields border color
    static let fieldBorder = Color(white: 0.35)

    /// Text fields fill color
    static let fieldFill = Color(white: 0.12)
}

// MARK: - Typography

extension Font {
    /// Large display headline used on onboarding cards (~32pt bold)
    static let displayHeadline = Font.system(size: 32, weight: .bold, design: .default)

    /// Section headline
    static let sectionHeadline = Font.system(size: 24, weight: .bold, design: .default)

    /// Standard body copy
    static let bodyRegular = Font.system(size: 16, weight: .regular, design: .default)

    /// Small caption / badge label
    static let badgeLabel = Font.system(size: 13, weight: .semibold, design: .default)

    /// Button label
    static let buttonLabel = Font.system(size: 17, weight: .bold, design: .default)

    /// Link / tertiary action
    static let linkLabel = Font.system(size: 15, weight: .medium, design: .default)
}

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum Radius {
    static let card: CGFloat = 28
    static let button: CGFloat = 14
    static let badge: CGFloat = 20
    static let field: CGFloat = 12
}
