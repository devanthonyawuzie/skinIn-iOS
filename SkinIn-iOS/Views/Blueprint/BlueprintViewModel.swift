// Views/Blueprint/BlueprintViewModel.swift
// SkinIn-iOS
//
// ViewModel for the Blueprint screen.
// Derives all display content from the user's selected Goal.
// Pure @Observable — no side effects, no system imports.

import SwiftUI

// MARK: - BlueprintViewModel

@Observable
final class BlueprintViewModel {

    // MARK: Goal

    let goal: Goal

    init(goal: Goal) {
        self.goal = goal
    }

    // MARK: - Dynamic Content

    /// Large multi-line title at the top of the Blueprint screen.
    var blueprintTitle: String {
        switch goal {
        case .muscleGain:        return "Your Muscle Gain\nBlueprint"
        case .fatLoss:           return "Your Fat Loss\nBlueprint"
        case .bodyRecomposition: return "Your Body Recomposition\nBlueprint"
        }
    }

    var blueprintSubtitle: String {
        switch goal {
        case .muscleGain:        return "12 Weeks to Your Strongest Self"
        case .fatLoss:           return "12 Weeks to Your Leanest Self"
        case .bodyRecomposition: return "12 Weeks to Your Best Body"
        }
    }

    var roadmapWeeks: [RoadmapWeek] {
        switch goal {
        case .muscleGain:
            return [
                RoadmapWeek(title: "Week 1: Hypertrophy Foundations",
                            detail: "4 Days/Week", status: .unlocked),
                RoadmapWeek(title: "Week 2: Progressive Overload",
                            detail: "Locked until completion of Week 1", status: .locked),
                RoadmapWeek(title: "Week 3–12: Advanced Techniques",
                            detail: "", status: .lockedDim)
            ]
        case .fatLoss:
            return [
                RoadmapWeek(title: "Week 1: Metabolic Conditioning",
                            detail: "5 Days/Week", status: .unlocked),
                RoadmapWeek(title: "Week 2: HIIT Intensification",
                            detail: "Locked until completion of Week 1", status: .locked),
                RoadmapWeek(title: "Week 3–12: Advanced Fat Burning",
                            detail: "", status: .lockedDim)
            ]
        case .bodyRecomposition:
            return [
                RoadmapWeek(title: "Week 1: Foundation & Baseline",
                            detail: "4 Days/Week", status: .unlocked),
                RoadmapWeek(title: "Week 2: Simultaneous Adaptation",
                            detail: "Locked until completion of Week 1", status: .locked),
                RoadmapWeek(title: "Week 3–12: Recomposition Phase",
                            detail: "", status: .lockedDim)
            ]
        }
    }

    /// Feature rows for the "What's Included" section.
    /// Nutrition row intentionally excluded per spec.
    var features: [BlueprintFeature] {
        [
            BlueprintFeature(
                sfSymbol: "brain.head.profile",
                color: .blue,
                title: "AI-Adjusted Loads",
                subtitle: "Smart weight suggestions"
            ),
            BlueprintFeature(
                sfSymbol: "figure.strengthtraining.traditional",
                color: .orange,
                title: "Form Correction",
                subtitle: "Real-time feedback"
            )
        ]
    }
}

// MARK: - RoadmapWeek

struct RoadmapWeek: Sendable {
    let title: String
    let detail: String
    let status: Status

    enum Status: Sendable {
        case unlocked
        case locked
        case lockedDim
    }
}

// MARK: - BlueprintFeature

struct BlueprintFeature: Sendable {
    let sfSymbol: String
    /// Tint color for the icon container and icon itself.
    let color: Color
    let title: String
    let subtitle: String
}
