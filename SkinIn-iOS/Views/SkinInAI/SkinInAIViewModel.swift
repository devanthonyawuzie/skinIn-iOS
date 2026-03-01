// Views/SkinInAI/SkinInAIViewModel.swift
// SkinIn-iOS

import Foundation
import Observation

// MARK: - ChatSender

enum ChatSender {
    case user
    case ai
}

// MARK: - ChatMessage

struct ChatMessage: Identifiable {
    let id: UUID
    let sender: ChatSender
    /// Plain text content.
    let text: String
    /// Substrings to render bold + brand green (e.g. "10%", "Week 3").
    let highlights: [String]
    let timestamp: Date

    init(
        id: UUID = UUID(),
        sender: ChatSender,
        text: String,
        highlights: [String] = [],
        timestamp: Date = Date()
    ) {
        self.id         = id
        self.sender     = sender
        self.text       = text
        self.highlights = highlights
        self.timestamp  = timestamp
    }
}

// MARK: - PresetChip

struct PresetChip: Identifiable {
    let id   = UUID()
    /// Text shown on the chip button.
    let label: String
    /// The `type` value sent to POST /api/ai-tip.
    let type: String
    /// SF Symbol name shown as a leading icon on the chip.
    let icon: String
}

// MARK: - SkinInAIViewModel

@Observable
final class SkinInAIViewModel {

    // MARK: Chat history

    /// Seeded with a single greeting — subsequent messages are appended live.
    var messages: [ChatMessage] = [
        ChatMessage(
            sender: .ai,
            text: "Hey! I'm SkinIn AI. Tap a chip below or ask me anything about your training.",
            highlights: ["SkinIn AI"]
        ),
    ]

    // MARK: Input state

    var inputText: String = ""

    // MARK: Loading state

    /// True while a request is in-flight — drives the typing indicator bubble.
    var isLoading: Bool = false

    /// The chip type currently being fetched (highlights the active chip).
    var activeChipType: String? = nil

    // MARK: - Fitness keyword guardrail

    /// Substrings that indicate a fitness-related message.
    /// Checked before any API call — off-topic messages are redirected locally.
    private static let fitnessKeywords: [String] = [
        "workout", "exercise", "progress", "swap", "log",
        "nutrition", "food", "diet", "pain", "injur", "weight",
        "cardio", "muscle", "strength", "train", "recover",
        "sleep", "sets", "reps", "form", "plateau", "routine",
        "program", "protein", "calori", "squat", "bench",
        "deadlift", "gym", "fit", "goal", "chest", "shoulder",
        "core", "abs", "glute", "hip", "knee", "sprint",
        "hiit", "stretch", "body", "week", "health", "stall",
        "lifting", "running", "macro", "water", "back",
    ]

    private func isFitnessMessage(_ text: String) -> Bool {
        let lower = text.lowercased()
        return Self.fitnessKeywords.contains { lower.contains($0) }
    }

    // MARK: Preset chips

    let presets: [PresetChip] = [
        PresetChip(label: "How was my week?",   type: "weekly_summary",   icon: "calendar"),
        PresetChip(label: "Swap exercise?",      type: "exercise_swap",    icon: "arrow.2.squarepath"),
        PresetChip(label: "Progress stalled?",   type: "progress_stalled", icon: "chart.line.downtrend.xyaxis"),
        PresetChip(label: "Knee pain?",          type: "knee_pain",        icon: "bandage"),
        PresetChip(label: "Nutrition?",          type: "nutrition",        icon: "fork.knife"),
    ]

    // MARK: - Send free-text

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(sender: .user, text: trimmed))
        inputText = ""

        // Guardrail layer 1 (iOS-side): block clearly off-topic messages before
        // they reach the network. GPT carries a second guardrail in its system prompt.
        guard isFitnessMessage(trimmed) else {
            messages.append(ChatMessage(
                sender: .ai,
                text: "Fitness only! Try the preset chips above.",
                highlights: []
            ))
            return
        }

        Task {
            await fetchTip(type: "general", userMessage: trimmed)
        }
    }

    // MARK: - Send preset chip

    func sendPreset(_ chip: PresetChip) {
        guard activeChipType == nil else { return }   // debounce while loading

        messages.append(ChatMessage(sender: .user, text: chip.label))
        activeChipType = chip.type

        Task {
            await fetchTip(type: chip.type, userMessage: nil)
            await MainActor.run { activeChipType = nil }
        }
    }

    // MARK: - Core fetch

    private func fetchTip(type: String, userMessage: String?) async {
        guard let token = UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken),
              let url   = URL(string: Config.apiBaseURL + "/api/ai-insight")
        else {
            await appendError()
            return
        }

        await MainActor.run { isLoading = true }

        var bodyDict: [String: String] = ["type": type]
        if let msg = userMessage { bodyDict["message"] = msg }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict)

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reply = json["tip"] as? String
        else {
            await appendError()
            await MainActor.run { isLoading = false }
            return
        }

        await MainActor.run {
            messages.append(ChatMessage(sender: .ai, text: reply))
            isLoading = false
        }
    }

    private func appendError() async {
        await MainActor.run {
            messages.append(ChatMessage(
                sender: .ai,
                text: "Couldn't reach the server. Check your connection and try again.",
                highlights: []
            ))
            isLoading = false
        }
    }

    // MARK: - Timestamp formatting

    func timestampLabel(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return "Today, " + fmt.string(from: date)
    }
}
