// Views/Blueprint/BlueprintViewModel.swift
// SkinIn-iOS
//
// ViewModel for the Blueprint screen.
// Derives all display content from the user's selected Goal.
//
// Plan preparation lifecycle:
//   1. generatePlan()  — POSTs /generate, populates generatedPlan
//   2. startPreparation() — POSTs /save (gets program_id), then polls /exercises-ready
//      isPreparingPlan = true the whole time; planReady flips true when exercises exist
//   3. After payment: activateSubscription(paymentIntentId:) — POSTs /activate
//      Creates the subscription row; webhook is observer/safety-net only.

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

    // MARK: - Plan Preparation State (pre-payment)

    /// True while /save is running + exercises are being polled.
    /// Drives the loading indicator shown below the Pay button.
    private(set) var isPreparingPlan: Bool = false

    /// True once week-1 exercises exist in the DB.
    /// Enables the Pay button.
    private(set) var planReady: Bool = false

    /// program_id returned by /save. Required by /activate after payment.
    private(set) var savedProgramId: String? = nil

    // MARK: - Post-Payment Activation State

    var isActivating: Bool = false
    var activationError: String? = nil

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

    // MARK: - Network: Generate Plan

    /// POSTs to /api/workout-plan/generate, populates `generatedPlan` on success.
    /// Immediately kicks off `startPreparation()` in the background once the plan arrives.
    func generatePlan() async {
        isGenerating = true
        generateError = nil
        // Reset preparation state in case this is a retry
        planReady = false
        savedProgramId = nil
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
            request.httpBody = "{}".data(using: .utf8)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                generateError = "Could not generate your plan. Please try again."
                return
            }

            let decoded = try JSONDecoder().decode(GeneratePlanResponse.self, from: data)
            generatedPlan = decoded.plan

            // Start saving the plan + polling for exercises in the background.
            // The Pay button is disabled until this completes.
            Task { await startPreparation() }

        } catch {
            generateError = "Network error. Check your connection."
        }
    }

    // MARK: - Network: Preparation (save plan + poll exercises)

    /// Saves the plan to /save, then polls /exercises-ready until week-1 exercises exist.
    /// Sets `planReady = true` when done (or after timeout).
    private func startPreparation() async {
        isPreparingPlan = true

        // 1. Save the plan — also sets savedProgramId on success
        guard await savePlan(), let programId = savedProgramId else {
            #if DEBUG
            print("[BlueprintViewModel] Plan save failed — Pay button will remain disabled")
            #endif
            isPreparingPlan = false
            return
        }

        // 2. Poll for exercises to be ready.
        //    Phase 1 is prioritised server-side, but strict validation can
        //    trigger retries. Allow up to 180s (60 × 3s) for slower runs.
        for attempt in 1...60 {
            #if DEBUG
            print("[BlueprintViewModel] Checking exercises ready (attempt \(attempt)/60)…")
            #endif

            if await checkExercisesReady(programId: programId) {
                #if DEBUG
                print("[BlueprintViewModel] Exercises ready after \(attempt) attempt(s)!")
                #endif
                planReady = true
                isPreparingPlan = false
                return
            }

            if attempt < 60 {
                try? await Task.sleep(for: .seconds(3))
            }
        }

        // Timed out after 180s — enable payment but log clearly so this is
        // easy to spot in debug output if exercises are genuinely missing.
        #if DEBUG
        print("[BlueprintViewModel] Exercise poll timed out after 180s — check server logs for generation errors")
        #endif
        planReady = true
        isPreparingPlan = false
    }

    /// POSTs the generated plan to /api/workout-plan/save.
    /// Captures `program_id` from the response into `savedProgramId`.
    /// Returns true on success, false on failure.
    private func savePlan() async -> Bool {
        guard let plan = generatedPlan else {
            #if DEBUG
            print("[BlueprintViewModel] Cannot save plan: no generated plan available")
            #endif
            return false
        }

        guard let token = UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken) else {
            #if DEBUG
            print("[BlueprintViewModel] Cannot save plan: no auth token")
            #endif
            return false
        }

        guard let url = URL(string: Config.apiBaseURL + "/api/workout-plan/save") else {
            #if DEBUG
            print("[BlueprintViewModel] Cannot save plan: invalid URL")
            #endif
            return false
        }

        do {
            let payload = SavePlanPayload(plan: plan)
            let body = try JSONEncoder().encode(payload)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = body

            #if DEBUG
            print("[BlueprintViewModel] Saving plan to backend…")
            #endif

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                #if DEBUG
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let responseBody = String(data: data, encoding: .utf8) ?? "no body"
                print("[BlueprintViewModel] Plan save failed: HTTP \(statusCode) — \(responseBody)")
                #endif
                return false
            }

            let decoded = try JSONDecoder().decode(SavePlanResponse.self, from: data)
            savedProgramId = decoded.programId

            #if DEBUG
            print("[BlueprintViewModel] Plan saved — programId: \(decoded.programId)")
            #endif
            return true

        } catch {
            #if DEBUG
            print("[BlueprintViewModel] Plan save error: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    /// GETs /api/workout-plan/exercises-ready?program_id=…
    /// Returns true once week-1 workout_exercises rows exist.
    private func checkExercisesReady(programId: String) async -> Bool {
        guard let token = UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken) else {
            return false
        }

        guard let url = URL(string: Config.apiBaseURL + "/api/workout-plan/exercises-ready?program_id=\(programId)") else {
            return false
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
            let decoded = try JSONDecoder().decode(ExercisesReadyResponse.self, from: data)
            return decoded.ready
        } catch {
            return false
        }
    }

    // MARK: - Network: Activate Subscription (post-payment)

    /// POSTs to /api/subscription/activate with the confirmed paymentIntentId and
    /// pre-saved programId. This is the authoritative subscription write path.
    func activateSubscription(paymentIntentId: String) async -> Bool {
        isActivating = true
        defer { isActivating = false }

        guard let programId = savedProgramId else {
            #if DEBUG
            print("[BlueprintViewModel] Cannot activate: no saved program ID")
            #endif
            return false
        }

        guard let token = UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken) else {
            return false
        }

        guard let url = URL(string: Config.apiBaseURL + "/api/subscription/activate") else {
            return false
        }

        do {
            let payload = ActivatePayload(paymentIntentId: paymentIntentId, programId: programId)
            let body = try JSONEncoder().encode(payload)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = body

            #if DEBUG
            print("[BlueprintViewModel] Activating subscription for programId: \(programId)…")
            #endif

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                #if DEBUG
                print("[BlueprintViewModel] Subscription activated successfully")
                #endif
                return true
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let responseBody = String(data: data, encoding: .utf8) ?? "no body"
                #if DEBUG
                print("[BlueprintViewModel] Activate failed: HTTP \(statusCode) — \(responseBody)")
                #endif
                return false
            }
        } catch {
            #if DEBUG
            print("[BlueprintViewModel] Activate error: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    // MARK: - Private Response / Payload Types

    private struct GeneratePlanResponse: Decodable {
        let success: Bool
        let plan: GeneratedWorkoutPlan
    }

    private struct SavePlanPayload: Encodable {
        let plan: GeneratedWorkoutPlan
    }

    private struct SavePlanResponse: Decodable {
        let success: Bool
        let programId: String
        enum CodingKeys: String, CodingKey {
            case success
            case programId = "program_id"
        }
    }

    private struct ExercisesReadyResponse: Decodable {
        let ready: Bool
    }

    private struct ActivatePayload: Encodable {
        let paymentIntentId: String
        let programId: String
        enum CodingKeys: String, CodingKey {
            case paymentIntentId = "payment_intent_id"
            case programId       = "program_id"
        }
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
