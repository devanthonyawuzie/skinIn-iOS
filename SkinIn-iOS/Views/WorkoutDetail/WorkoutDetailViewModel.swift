// Views/WorkoutDetail/WorkoutDetailViewModel.swift
// SkinIn-iOS
//
// ViewModel for the WorkoutDetail screen.
// Owns workout metadata, exercise list, progress tracking, and
// the video-preview sheet state.
//
// Architecture: MVVM — @Observable (iOS 17+). No @Published wrappers.
// No force-unwraps. Sendable-safe data types.

import Foundation
import Observation

// MARK: - Exercise

struct Exercise: Identifiable {
    let id: UUID
    let name: String
    let sets: Int
    let reps: Int
    let repUnit: String    // "Reps" or "Secs"
    let imageName: String  // tried with UIImage(named:) first; falls back to sfSymbol
    let sfSymbol: String   // SF Symbol fallback
}

// MARK: - WorkoutDetailViewModel

@Observable
final class WorkoutDetailViewModel {

    // MARK: Workout metadata

    let workoutName: String
    let durationMinutes: Int
    let difficulty: String   // e.g. "Interm.", "Beginner", "Advanced"
    let calories: Int
    let exercises: [Exercise]
    let stakeAmount: Double  // displayed as "$5.00"

    // MARK: Progress (0.0 → 1.0)

    var progress: Double = 0.0

    // MARK: Video preview sheet state

    var selectedExercise: Exercise? = nil
    var showVideoPreview: Bool = false

    // MARK: Init

    init() {
        workoutName     = "Full Body Ignite"
        durationMinutes = 45
        difficulty      = "Interm."
        calories        = 320
        stakeAmount     = 5.00
        exercises = [
            Exercise(
                id: UUID(),
                name: "Barbell Squat",
                sets: 4, reps: 10, repUnit: "Reps",
                imageName: "exercise.squat",
                sfSymbol: "figure.strengthtraining.traditional"
            ),
            Exercise(
                id: UUID(),
                name: "Bench Press",
                sets: 3, reps: 12, repUnit: "Reps",
                imageName: "exercise.bench",
                sfSymbol: "figure.strengthtraining.traditional"
            ),
            Exercise(
                id: UUID(),
                name: "Bent Over Rows",
                sets: 3, reps: 12, repUnit: "Reps",
                imageName: "exercise.rows",
                sfSymbol: "figure.strengthtraining.traditional"
            ),
            Exercise(
                id: UUID(),
                name: "Plank",
                sets: 3, reps: 60, repUnit: "Secs",
                imageName: "exercise.plank",
                sfSymbol: "figure.core.training"
            ),
        ]
    }

    // MARK: Computed helpers

    var progressPercent: String { "\(Int(progress * 100))%" }
    var movementsLabel: String  { "\(exercises.count) Movements" }
    var stakeLabel: String      { String(format: "$%.2f", stakeAmount) }
}
