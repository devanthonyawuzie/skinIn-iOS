// Views/Workouts/WorkoutsViewModel.swift
// SkinIn-iOS
//
// ViewModel for the Workouts screen.
// Owns the weekly schedule data, week-strip day generation, and the
// mock countdown timer display. All state is @Observable (iOS 17+).

import Foundation
import Observation

// MARK: - WorkoutStatus

enum WorkoutStatus {
    case completed  // workout logged / past
    case today      // active session, timer visible
    case locked     // future / not yet unlocked
}

// MARK: - WorkoutSession

struct WorkoutSession: Identifiable {
    let id: UUID
    let shortDay: String         // e.g. "MON, MAR 25"
    let name: String
    let description: String
    let durationMinutes: Int
    let calories: Int
    let focusArea: String        // e.g. "Cardio", "Strength"
    let status: WorkoutStatus
}

// MARK: - WeekDayItem

/// A single cell in the week-day strip at the top of the screen.
struct WeekDayItem: Identifiable {
    let id: UUID
    let abbreviation: String   // "SUN", "MON", …
    let dayNumber: Int         // calendar day of month
    let isToday: Bool
    let hasCompletedWorkout: Bool
}

// MARK: - WorkoutsViewModel

@Observable
final class WorkoutsViewModel {

    // MARK: Header State

    let month: String = "MARCH"
    let weekNumber: Int = 4
    let completedCount: Int = 3
    let totalCount: Int = 5

    // MARK: Timer (mock — no live ticking yet)

    let timerDisplay: String = "14:22:05"

    // MARK: Week Day Strip
    // Mock "today" is Wednesday March 27, 2024.
    // Week runs Sun Mar 24 – Sat Mar 30.

    let weekDays: [WeekDayItem] = [
        WeekDayItem(id: UUID(), abbreviation: "SUN", dayNumber: 24,
                    isToday: false, hasCompletedWorkout: false),
        WeekDayItem(id: UUID(), abbreviation: "MON", dayNumber: 25,
                    isToday: false, hasCompletedWorkout: true),
        WeekDayItem(id: UUID(), abbreviation: "TUE", dayNumber: 26,
                    isToday: false, hasCompletedWorkout: true),
        WeekDayItem(id: UUID(), abbreviation: "WED", dayNumber: 27,
                    isToday: true,  hasCompletedWorkout: false),
        WeekDayItem(id: UUID(), abbreviation: "THU", dayNumber: 28,
                    isToday: false, hasCompletedWorkout: false),
        WeekDayItem(id: UUID(), abbreviation: "FRI", dayNumber: 29,
                    isToday: false, hasCompletedWorkout: false),
        WeekDayItem(id: UUID(), abbreviation: "SAT", dayNumber: 30,
                    isToday: false, hasCompletedWorkout: false)
    ]

    // MARK: Sessions (mock)

    let sessions: [WorkoutSession] = [
        WorkoutSession(
            id: UUID(),
            shortDay: "MON, MAR 25",
            name: "Upper Body Strength",
            description: "Build pushing and pulling strength across chest, back, and shoulders.",
            durationMinutes: 45,
            calories: 520,
            focusArea: "Strength",
            status: .completed
        ),
        WorkoutSession(
            id: UUID(),
            shortDay: "TUE, MAR 26",
            name: "Active Recovery Yoga",
            description: "Low-intensity mobility work to reduce soreness and improve flexibility.",
            durationMinutes: 30,
            calories: 150,
            focusArea: "Recovery",
            status: .completed
        ),
        WorkoutSession(
            id: UUID(),
            shortDay: "WED, MAR 27",
            name: "Metabolic Burn",
            description: "High intensity interval training to maximize calorie burn.",
            durationMinutes: 45,
            calories: 480,
            focusArea: "Cardio",
            status: .today
        ),
        WorkoutSession(
            id: UUID(),
            shortDay: "THU, MAR 28",
            name: "Lower Body Power",
            description: "Heavy compound movements targeting quads, hamstrings, and glutes.",
            durationMinutes: 50,
            calories: 540,
            focusArea: "Strength",
            status: .locked
        ),
        WorkoutSession(
            id: UUID(),
            shortDay: "FRI, MAR 29",
            name: "Full Body HIIT",
            description: "Total-body conditioning circuit for maximum metabolic output.",
            durationMinutes: 40,
            calories: 510,
            focusArea: "Cardio",
            status: .locked
        )
    ]
}
