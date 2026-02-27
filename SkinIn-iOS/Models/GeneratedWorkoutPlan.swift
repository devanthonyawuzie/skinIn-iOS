// Models/GeneratedWorkoutPlan.swift
// SkinIn-iOS
//
// Codable model representing the AI-generated 12-week workout plan
// returned from POST /api/workout-plan/generate.
// CodingKeys map server snake_case → Swift camelCase throughout.

import Foundation

// MARK: - GeneratedWorkoutPlan

struct GeneratedWorkoutPlan: Codable, Sendable {

    let programName: String
    let tagline: String
    let splitType: String?
    let weeks: [GeneratedWeek]

    // MARK: CodingKeys

    enum CodingKeys: String, CodingKey {
        case programName = "program_name"
        case tagline
        case splitType = "split_type"
        case weeks
    }

    // MARK: - GeneratedWeek

    struct GeneratedWeek: Codable, Sendable {

        let weekNumber: Int
        let phaseTitle: String
        let days: [GeneratedDay]

        enum CodingKeys: String, CodingKey {
            case weekNumber  = "week_number"
            case phaseTitle  = "week_title"
            case days
        }
    }

    // MARK: - GeneratedDay

    struct GeneratedDay: Codable, Sendable {

        let dayNumber: Int
        let title: String

        enum CodingKeys: String, CodingKey {
            case dayNumber = "day_number"
            case title
        }
    }
}
