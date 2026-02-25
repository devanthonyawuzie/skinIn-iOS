// Models/Goal.swift
// SkinIn-iOS
//
// Fitness goal model extracted from the setup flow.
// Used by SetupViewModel, Step2GoalsView, and the Supabase profile payload.

import Foundation

// MARK: - Goal

enum Goal: String, CaseIterable, Sendable {
    case muscleGain = "muscle_gain"
    case fatLoss = "fat_loss"
    case bodyRecomposition = "body_recomposition"

    var displayName: String {
        switch self {
        case .muscleGain:        return "Muscle Gain"
        case .fatLoss:           return "Fat Loss"
        case .bodyRecomposition: return "Body Recomposition"
        }
    }

    var subtitle: String {
        switch self {
        case .muscleGain:        return "Build strength and add lean mass over time."
        case .fatLoss:           return "Burn calories and reduce body fat percentage."
        case .bodyRecomposition: return "Simultaneously lose fat and build muscle."
        }
    }

    var sfSymbolFallback: String {
        switch self {
        case .muscleGain:        return "dumbbell.fill"
        case .fatLoss:           return "flame.fill"
        case .bodyRecomposition: return "figure.mixed.cardio"
        }
    }

    var assetName: String {
        switch self {
        case .muscleGain:        return "goal.muscle.gain"
        case .fatLoss:           return "goal.fat.loss"
        case .bodyRecomposition: return "goal.body.recomposition"
        }
    }
}

// MARK: - ExperienceLevel

enum ExperienceLevel: String, CaseIterable, Sendable {
    case beginner     = "beginner"
    case intermediate = "intermediate"

    var displayName: String {
        switch self {
        case .beginner:     return "Beginner"
        case .intermediate: return "Intermediate"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner:     return "Starting out"
        case .intermediate: return "Experienced"
        }
    }

    var sfSymbol: String {
        switch self {
        case .beginner:     return "face.smiling"
        case .intermediate: return "figure.martial.arts"
        }
    }
}
