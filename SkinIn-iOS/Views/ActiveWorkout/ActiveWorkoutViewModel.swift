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
import SwiftUI

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

    /// The UUID of the workout being logged. Passed in from WorkoutDetailView;
    /// defaults to a mock ID so previews and existing call sites still compile.
    let workoutId: String

    // MARK: Timer — static mock value for now (45:12 elapsed)
    var elapsedSeconds: Int = 2712

    // MARK: Exercise list
    var exercises: [ActiveExercise]

    // MARK: Submission State

    /// True while the POST /api/workout-logs request is in-flight.
    var isSubmitting: Bool = false

    /// Set to true on a 201 response — observed by the View to trigger dismiss.
    var submittedSuccessfully: Bool = false

    /// Populated on any non-201 response. Drives the error alert.
    var submitError: String? = nil

    /// Controls the error alert sheet.
    var showSubmitError: Bool = false

    // MARK: Init

    init(workoutId: String = "20000000-0003-0003-0000-000000000000") {
        self.workoutId = workoutId
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

    // MARK: - Fetch Exercises

    func fetchExercises() async {
        guard let token = UserDefaults.standard.string(
            forKey: Config.UserDefaultsKey.supabaseSessionToken
        ) else { return }

        guard let url = URL(string: Config.apiBaseURL + "/api/workouts/\(workoutId)/exercises") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let exercisesArr = json["exercises"] as? [[String: Any]],
                  !exercisesArr.isEmpty else { return }

            let mapped = exercisesArr.enumerated().compactMap { index, ex -> ActiveExercise? in
                guard let name = ex["name"] as? String else { return nil }
                let targetSets = ex["sets"] as? Int ?? 3
                let repsStr = ex["reps"] as? String ?? "10"

                let sets = (1...targetSets).map { setNum in
                    SetEntry(id: UUID(), setNumber: setNum, weightLbs: "0", reps: repsStr, isDone: false)
                }

                return ActiveExercise(
                    id: UUID(),
                    name: name,
                    category: "WORKOUT",
                    targetSets: targetSets,
                    targetRepsRange: "\(repsStr) Reps",
                    sets: sets,
                    isExpanded: index == 0,
                    isCompleted: false
                )
            }

            if !mapped.isEmpty {
                exercises = mapped
            }
        } catch {
            // Non-fatal — keep mock exercises as fallback
        }
    }

    // MARK: - Submit Log

    /// POSTs the completed workout to the server.
    ///
    /// On success (201): sets `submittedSuccessfully = true` — the View observes
    ///   this and calls `dismiss()`.
    /// On cooldown (429): parses `hours_remaining` and surfaces a user-readable
    ///   countdown in `submitError`.
    /// On any other error: populates `submitError` with the server message.
    ///
    /// All checks are server-side. Device time is never used to pre-validate.
    func submitLog() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        submitError = nil

        defer { isSubmitting = false }

        // Retrieve the JWT stored at sign-in
        guard let token = UserDefaults.standard.string(
            forKey: Config.UserDefaultsKey.supabaseSessionToken
        ) else {
            submitError = "You are not signed in. Please sign in and try again."
            showSubmitError = true
            return
        }

        guard let url = URL(string: Config.apiBaseURL + "/api/workout-logs") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["workout_id": workoutId])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let http = response as? HTTPURLResponse
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

            switch http?.statusCode {
            case 201:
                submittedSuccessfully = true

            case 429:
                // Cooldown active — format remaining time as HHh MMm
                if let hrs = json?["hours_remaining"] as? Double {
                    let h = Int(hrs)
                    let m = Int((hrs - Double(h)) * 60)
                    let parts = [h > 0 ? "\(h)h" : nil, m > 0 ? "\(m)m" : nil]
                    let formatted = parts.compactMap { $0 }.joined(separator: " ")
                    submitError = "Next workout unlocks in \(formatted.isEmpty ? "a moment" : formatted)."
                } else {
                    submitError = json?["error"] as? String ?? "Too soon since your last workout."
                }
                showSubmitError = true

            case 403:
                submitError = json?["error"] as? String ?? "Subscription issue. Please contact support."
                showSubmitError = true

            default:
                submitError = json?["error"] as? String ?? "Failed to submit workout. Please try again."
                showSubmitError = true
            }
        } catch {
            submitError = "Network error. Check your connection and try again."
            showSubmitError = true
        }
    }
}
