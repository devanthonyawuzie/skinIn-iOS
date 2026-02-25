// Views/ActiveWorkout/ActiveWorkoutViewModel.swift
// SkinIn-iOS
//
// ViewModel for the live workout logging screen.
// Owns all mutable workout state: exercises, sets, timer.
// Architecture: MVVM — @Observable, no @Published, no callbacks.
// All mutations go through explicit methods to maintain @Observable
// property graph correctness (direct nested mutation on arrays of
// structs requires re-assignment at the array level, which these
// methods handle).

import Foundation

// MARK: - SetEntry

struct SetEntry: Identifiable {
    let id: UUID
    let setNumber: Int
    var weightLbs: String   // editable text field value
    var reps: String        // editable text field value
    var isDone: Bool
}

// MARK: - ActiveExercise

struct ActiveExercise: Identifiable {
    let id: UUID
    let name: String
    let category: String          // e.g. "HEAVY COMPOUND"
    let targetSets: Int
    let targetRepsRange: String   // e.g. "8-10 reps"
    var sets: [SetEntry]
    var isExpanded: Bool
    var isCompleted: Bool
}

// MARK: - ActiveWorkoutViewModel

@Observable
final class ActiveWorkoutViewModel {

    // MARK: Static workout metadata
    let workoutName: String = "Leg Day"
    let weekNumber: Int = 4
    let targetMinutes: Int = 60

    // MARK: Timer — static mock value for now (45:12 elapsed)
    var elapsedSeconds: Int = 2712

    // MARK: Exercise list
    var exercises: [ActiveExercise]

    // MARK: Init

    init() {
        exercises = [
            // 1. Barbell Squat — all sets done, card completed
            ActiveExercise(
                id: UUID(),
                name: "Barbell Squat",
                category: "HEAVY COMPOUND",
                targetSets: 3,
                targetRepsRange: "5 reps",
                sets: [
                    SetEntry(id: UUID(), setNumber: 1, weightLbs: "225", reps: "5", isDone: true),
                    SetEntry(id: UUID(), setNumber: 2, weightLbs: "225", reps: "5", isDone: true),
                    SetEntry(id: UUID(), setNumber: 3, weightLbs: "225", reps: "5", isDone: true),
                ],
                isExpanded: true,
                isCompleted: true
            ),
            // 2. Leg Press — active card (green border), last set not yet done
            ActiveExercise(
                id: UUID(),
                name: "Leg Press",
                category: "QUAD FOCUS",
                targetSets: 3,
                targetRepsRange: "8-10 reps",
                sets: [
                    SetEntry(id: UUID(), setNumber: 1, weightLbs: "400", reps: "10", isDone: true),
                    SetEntry(id: UUID(), setNumber: 2, weightLbs: "400", reps: "10", isDone: true),
                    SetEntry(id: UUID(), setNumber: 3, weightLbs: "400", reps: "1",  isDone: false),
                ],
                isExpanded: true,
                isCompleted: false
            ),
            // 3. Calf Raises — upcoming, collapsed
            ActiveExercise(
                id: UUID(),
                name: "Calf Raises",
                category: "ISOLATION",
                targetSets: 3,
                targetRepsRange: "15 reps",
                sets: [
                    SetEntry(id: UUID(), setNumber: 1, weightLbs: "0", reps: "15", isDone: false),
                    SetEntry(id: UUID(), setNumber: 2, weightLbs: "0", reps: "15", isDone: false),
                    SetEntry(id: UUID(), setNumber: 3, weightLbs: "0", reps: "15", isDone: false),
                ],
                isExpanded: false,
                isCompleted: false
            ),
            // 4. Leg Extensions — upcoming, collapsed
            ActiveExercise(
                id: UUID(),
                name: "Leg Extensions",
                category: "ISOLATION",
                targetSets: 3,
                targetRepsRange: "12 reps",
                sets: [
                    SetEntry(id: UUID(), setNumber: 1, weightLbs: "0", reps: "12", isDone: false),
                    SetEntry(id: UUID(), setNumber: 2, weightLbs: "0", reps: "12", isDone: false),
                    SetEntry(id: UUID(), setNumber: 3, weightLbs: "0", reps: "12", isDone: false),
                ],
                isExpanded: false,
                isCompleted: false
            ),
        ]
    }

    // MARK: - Computed Properties

    var completedCount: Int { exercises.filter { $0.isCompleted }.count }
    var totalCount: Int { exercises.count }

    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var progressPercent: Int { Int(progressFraction * 100) }

    var timerDisplay: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    // MARK: - Mutations

    /// Toggles the done state of a single set and re-evaluates the parent
    /// exercise completion state (all sets done → isCompleted = true).
    func toggleSetDone(exerciseId: UUID, setId: UUID) {
        guard let eIdx = exercises.firstIndex(where: { $0.id == exerciseId }),
              let sIdx = exercises[eIdx].sets.firstIndex(where: { $0.id == setId })
        else { return }

        exercises[eIdx].sets[sIdx].isDone.toggle()
        exercises[eIdx].isCompleted = exercises[eIdx].sets.allSatisfy { $0.isDone }
    }

    /// Appends a new set to an exercise, pre-filling weight/reps from the last set.
    func addSet(exerciseId: UUID) {
        guard let eIdx = exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        let nextNum = (exercises[eIdx].sets.last?.setNumber ?? 0) + 1
        let lastWeight = exercises[eIdx].sets.last?.weightLbs ?? "0"
        let lastReps   = exercises[eIdx].sets.last?.reps ?? "10"
        exercises[eIdx].sets.append(
            SetEntry(id: UUID(), setNumber: nextNum, weightLbs: lastWeight, reps: lastReps, isDone: false)
        )
    }

    /// Collapses or expands an exercise card.
    func toggleExpand(exerciseId: UUID) {
        guard let eIdx = exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        exercises[eIdx].isExpanded.toggle()
    }

    /// Updates the weight text for a specific set — used by TextField binding.
    func updateWeight(exerciseId: UUID, setId: UUID, value: String) {
        guard let eIdx = exercises.firstIndex(where: { $0.id == exerciseId }),
              let sIdx = exercises[eIdx].sets.firstIndex(where: { $0.id == setId })
        else { return }
        exercises[eIdx].sets[sIdx].weightLbs = value
    }

    /// Updates the reps text for a specific set — used by TextField binding.
    func updateReps(exerciseId: UUID, setId: UUID, value: String) {
        guard let eIdx = exercises.firstIndex(where: { $0.id == exerciseId }),
              let sIdx = exercises[eIdx].sets.firstIndex(where: { $0.id == setId })
        else { return }
        exercises[eIdx].sets[sIdx].reps = value
    }
}
