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
    let reps: String       // API returns "8-10", "60", etc.
    let repUnit: String    // "Reps" or "Secs"
    let imageName: String  // tried with UIImage(named:) first; falls back to sfSymbol
    let sfSymbol: String   // SF Symbol fallback
}

// MARK: - WorkoutDetailViewModel

@Observable
final class WorkoutDetailViewModel {

    // MARK: Workout metadata

    let workoutId: String
    var workoutName: String
    let durationMinutes: Int = 45
    let difficulty: String = "Interm."
    let calories: Int = 320
    let stakeAmount: Double = 80.0

    // MARK: Exercise list

    var exercises: [Exercise] = []

    // MARK: Loading state

    var isLoading: Bool = false

    // MARK: Progress (0.0 → 1.0)

    var progress: Double = 0.0

    // MARK: Video preview sheet state

    var selectedExercise: Exercise? = nil
    var showVideoPreview: Bool = false

    // MARK: Init

    init(workoutId: String, workoutName: String) {
        self.workoutId = workoutId
        self.workoutName = workoutName
    }

    // MARK: Computed helpers

    var progressPercent: String { "\(Int(progress * 100))%" }
    var movementsLabel: String  { "\(exercises.count) Movements" }
    var stakeLabel: String      { String(format: "$%.0f", stakeAmount) }

    // MARK: - Fetch

    func fetch() async {
        guard let token = UserDefaults.standard.string(
            forKey: Config.UserDefaultsKey.supabaseSessionToken
        ) else { return }

        guard let url = URL(
            string: Config.apiBaseURL + "/api/workouts/\(workoutId)/exercises"
        ) else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        isLoading = true

        defer { isLoading = false }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let exercisesArr = json["exercises"] as? [[String: Any]]
            else { return }

            let mapped: [Exercise] = exercisesArr.compactMap { ex in
                guard let name = ex["name"] as? String else { return nil }
                let sets = ex["sets"] as? Int ?? 3
                let repsStr = ex["reps"] as? String ?? "10"
                let idString = ex["id"] as? String ?? ""

                return Exercise(
                    id: UUID(uuidString: idString) ?? UUID(),
                    name: name,
                    sets: sets,
                    reps: repsStr,
                    repUnit: "Reps",
                    imageName: "",
                    sfSymbol: "figure.strengthtraining.traditional"
                )
            }

            if !mapped.isEmpty {
                exercises = mapped
            }
        } catch {
            // Non-fatal — exercises remain empty; UI shows empty state
        }
    }
}
