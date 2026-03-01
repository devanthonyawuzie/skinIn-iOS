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

// MARK: - ActivityLevel

enum ActivityLevel: String, CaseIterable, Sendable {
    case sedentary        = "sedentary"
    case lightlyActive    = "lightly_active"
    case moderatelyActive = "moderately_active"
    case veryActive       = "very_active"

    var displayName: String {
        switch self {
        case .sedentary:        return "Sedentary"
        case .lightlyActive:    return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive:       return "Very Active"
        }
    }

    var activityDescription: String {
        switch self {
        case .sedentary:        return "Office job, little exercise"
        case .lightlyActive:    return "Light exercise 1–3 days/week"
        case .moderatelyActive: return "Moderate exercise 3–5 days/week"
        case .veryActive:       return "Hard exercise 6–7 days/week"
        }
    }

    var sfSymbol: String {
        switch self {
        case .sedentary:        return "chair.lounge.fill"
        case .lightlyActive:    return "figure.walk"
        case .moderatelyActive: return "figure.run"
        case .veryActive:       return "figure.highintensity.intervaltraining"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary:        return 1.2
        case .lightlyActive:    return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive:       return 1.725
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
