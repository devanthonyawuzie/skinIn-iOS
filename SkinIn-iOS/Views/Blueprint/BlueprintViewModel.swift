// Views/Blueprint/BlueprintViewModel.swift
// SkinIn-iOS
//
// ViewModel for the Blueprint screen.
// Derives all display content from the user's selected Goal.
// Auto-generates the AI workout plan on appear; saves it to the server only after payment.

import SwiftUI

// MARK: - BlueprintViewModel

@Observable
final class BlueprintViewModel {

    // MARK: Goal

    let goal: Goal

    init(goal: Goal) {
        self.goal = goal
    }

    // MARK: - Plan Generation State

    var isGenerating: Bool = false
    var generateError: String? = nil
    var generatedPlan: GeneratedWorkoutPlan? = nil

    // MARK: - Roadmap UI State

    /// When true the roadmap shows all 12 weeks; false shows 2 real rows + summary row.
    var showAllWeeks: Bool = false

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

    // MARK: - Roadmap Weeks

    /// Returns roadmap rows derived from the AI-generated plan when available,
    /// otherwise falls back to static goal-based content.
    var roadmapWeeks: [RoadmapWeek] {
        if let plan = generatedPlan {
            return generatedRoadmapWeeks(from: plan)
        }
        return staticRoadmapWeeks
    }

    /// Builds roadmap rows from the generated plan. Respects `showAllWeeks` toggle.
    private func generatedRoadmapWeeks(from plan: GeneratedWorkoutPlan) -> [RoadmapWeek] {
        var all: [RoadmapWeek] = plan.weeks.enumerated().map { index, week in
            let status: RoadmapWeek.Status
            let detail: String
            switch index {
            case 0:
                status = .unlocked
                detail = "4 Days/Week"
            case 1:
                status = .locked
                detail = "Locked until completion of Week 1"
            default:
                status = .lockedDim
                detail = ""
            }
            return RoadmapWeek(
                title: "Week \(week.weekNumber): \(week.phaseTitle)",
                detail: detail,
                status: status
            )
        }

        if showAllWeeks {
            return all
        }

        // Collapsed view: first 2 real rows + 1 summary row for weeks 3–12
        let firstTwo = Array(all.prefix(2))
        let summaryRow = RoadmapWeek(
            title: "Weeks 3–12: Advanced Training",
            detail: "",
            status: .lockedDim
        )
        return firstTwo + [summaryRow]
    }

    /// Static fallback used before the AI plan arrives.
    private var staticRoadmapWeeks: [RoadmapWeek] {
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

    // MARK: - Features

    /// Feature rows for the "What's Included" section.
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

    // MARK: - Network

    /// POSTs to /api/workout-plan/generate, populates `generatedPlan` on success.
    /// Sets `generateError` on failure — never throws, never blocks the UI.
    func generatePlan() async {
        isGenerating = true
        generateError = nil
        defer { isGenerating = false }

        guard let token = UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken) else {
            generateError = "Could not generate your plan. Please try again."
            return
        }

        guard let url = URL(string: Config.apiBaseURL + "/api/workout-plan/generate") else {
            generateError = "Could not generate your plan. Please try again."
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            // Empty JSON body is acceptable — server derives goal from the user's profile.
            request.httpBody = "{}".data(using: .utf8)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                generateError = "Could not generate your plan. Please try again."
                return
            }

            let decoded = try JSONDecoder().decode(GeneratePlanResponse.self, from: data)
            generatedPlan = decoded.plan

        } catch {
            generateError = "Network error. Check your connection."
        }
    }

    /// POSTs the generated plan to /api/workout-plan/save after payment succeeds.
    /// Fire-and-forget: never surfaces errors to the user.
    func savePlan() async {
        guard let plan = generatedPlan else { return }

        guard let token = UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken) else {
            return
        }

        guard let url = URL(string: Config.apiBaseURL + "/api/workout-plan/save") else { return }

        do {
            let payload = SavePlanPayload(plan: plan)
            let body = try JSONEncoder().encode(payload)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = body

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("[BlueprintViewModel] Plan save failed: \(httpResponse.statusCode)")
            }
        } catch {
            // Non-fatal — plan is in-memory; silently swallow the error.
            print("[BlueprintViewModel] Plan save error: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Response/Payload Types

    private struct GeneratePlanResponse: Decodable {
        let success: Bool
        let plan: GeneratedWorkoutPlan
    }

    private struct SavePlanPayload: Encodable {
        let plan: GeneratedWorkoutPlan
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
