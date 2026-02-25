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
    /// Ranges within `text` to highlight bold green (e.g. "10%", "5lbs").
    let highlights: [String]
    let timestamp: Date

    init(
        id: UUID = UUID(),
        sender: ChatSender,
        text: String,
        highlights: [String] = [],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.highlights = highlights
        self.timestamp = timestamp
    }
}

// MARK: - SkinInAIViewModel

@Observable
final class SkinInAIViewModel {

    // MARK: Chat history (mock seed)

    var messages: [ChatMessage] = [
        ChatMessage(
            sender: .user,
            text: "Just finished leg day. It was brutal.",
            timestamp: Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date()
        ),
        ChatMessage(
            sender: .ai,
            text: "Great work staying consistent. Based on your last log, your squat is up 10%.\n\nAdd 5lbs to bench next time to maintain progressive overload.",
            highlights: ["10%", "5lbs"],
            timestamp: Calendar.current.date(byAdding: .minute, value: -4, to: Date()) ?? Date()
        ),
        ChatMessage(
            sender: .user,
            text: "Got it, logging a run now.",
            timestamp: Date()
        ),
    ]

    // MARK: Input state

    var inputText: String = ""

    // MARK: Quick prompts

    let quickPrompts: [String] = [
        "Analyze my week",
        "Suggest a recipe",
        "Why am I stalling?",
        "How's my form?",
    ]

    // MARK: - Send

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let userMsg = ChatMessage(sender: .user, text: trimmed)
        messages.append(userMsg)
        inputText = ""

        // Mock AI echo response after a short delay
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            let reply = ChatMessage(
                sender: .ai,
                text: "Got it — I'll update your plan based on that. Keep it up!",
                highlights: []
            )
            await MainActor.run { self.messages.append(reply) }
        }
    }

    func sendQuickPrompt(_ prompt: String) {
        inputText = prompt
        sendMessage()
    }

    // MARK: - Timestamp formatting

    func timestampLabel(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return "Today, " + fmt.string(from: date)
    }
}
