// Views/SkinInAI/SkinInAIView.swift
// SkinIn-iOS

import SwiftUI

// MARK: - SkinInAIView

struct SkinInAIView: View {

    @State private var vm = SkinInAIViewModel()

    private let pageBackground = Color(red: 0.96, green: 0.96, blue: 0.96)

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                SkinInAINavBar()

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: Spacing.md) {
                            // Date separator uses the timestamp of the first message
                            DateSeparator(
                                label: vm.messages.first.map { vm.timestampLabel(for: $0.timestamp) }
                                    ?? vm.timestampLabel(for: Date())
                            )

                            ForEach(vm.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.sm)
                    }
                    .onChange(of: vm.messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(vm.messages.last?.id, anchor: .bottom)
                        }
                    }
                }

                QuickPromptsRow(prompts: vm.quickPrompts) { prompt in
                    vm.sendQuickPrompt(prompt)
                }

                InputBar(
                    inputText: Binding(
                        get: { vm.inputText },
                        set: { vm.inputText = $0 }
                    ),
                    onSend: { vm.sendMessage() }
                )
            }
        }
    }
}

// MARK: - SkinInAINavBar

private struct SkinInAINavBar: View {
    var body: some View {
        HStack(spacing: 0) {

            Spacer()

            // Center: title + online indicator
            VStack(spacing: 3) {
                Text("SkinIn AI")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.black)

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.brandGreen)
                        .frame(width: 7, height: 7)
                    Text("Online")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(white: 0.55))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("SkinIn AI, Online")

            Spacer()

            // Trailing: overflow menu (no-op)
            Button {
                // No-op
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("More options")
        }
        .frame(height: 56)
        .padding(.horizontal, Spacing.sm)
        .background(Color.white)
    }
}

// MARK: - DateSeparator

private struct DateSeparator: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color(white: 0.55))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(white: 0.88))
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityLabel(label)
    }
}

// MARK: - ChatBubble

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        switch message.sender {
        case .user:
            UserBubble(text: message.text)
        case .ai:
            AIBubble(text: message.text, highlights: message.highlights)
        }
    }
}

// MARK: - UserBubble

private struct UserBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer()

            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.black)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 10)
                .background(Color.brandGreen)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: 280, alignment: .trailing)
                .accessibilityLabel(text)

            // User avatar
            Circle()
                .fill(Color(red: 0.95, green: 0.70, blue: 0.55))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white)
                )
                .accessibilityHidden(true)
        }
    }
}

// MARK: - AIBubble

private struct AIBubble: View {
    let text: String
    let highlights: [String]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Momentum avatar
            ZStack {
                Circle()
                    .fill(Color(red: 0.08, green: 0.20, blue: 0.08))
                    .frame(width: 32, height: 32)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.brandGreen)
            }
            .accessibilityHidden(true)

            AttributedAIBubble(text: text, highlights: highlights)
                .frame(maxWidth: 280, alignment: .leading)
                .accessibilityLabel(text)

            Spacer()
        }
    }
}

// MARK: - AttributedAIBubble

// Internal visibility so the outer struct can reference it if needed,
// but housed here since it is only used by AIBubble.
struct AttributedAIBubble: View {
    let text: String
    let highlights: [String]

    var body: some View {
        buildText()
            .font(.system(size: 15, weight: .regular))
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
    }

    // Builds a SwiftUI Text by walking through the string and replacing
    // highlight tokens with bold green spans via Text concatenation.
    // Note: foregroundColor (not foregroundStyle) is required here because
    // SwiftUI's Text concatenation operator (+) only accepts Text modifiers
    // that use the deprecated foregroundColor API for inline attributed spans.
    private func buildText() -> Text {
        var result = Text("")
        var remaining = text

        while !remaining.isEmpty {
            // Find the earliest occurring highlight in the remaining string
            var earliestRange: Range<String.Index>? = nil
            var earliestHighlight = ""

            for highlight in highlights {
                if let range = remaining.range(of: highlight) {
                    if earliestRange == nil || range.lowerBound < earliestRange!.lowerBound {
                        earliestRange = range
                        earliestHighlight = highlight
                    }
                }
            }

            if let range = earliestRange {
                // Append plain text that precedes the highlight
                let before = String(remaining[remaining.startIndex ..< range.lowerBound])
                if !before.isEmpty {
                    result = result + Text(before)
                }

                // Append the highlighted span — bold + brand green
                // foregroundColor is intentional here (Text concatenation requirement)
                result = result + Text(earliestHighlight)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.brandGreen) // swiftlint:disable:this foreground_color

                remaining = String(remaining[range.upperBound...])
            } else {
                // No more highlights — append the rest as plain text
                result = result + Text(remaining)
                remaining = ""
            }
        }

        return result
    }
}

// MARK: - QuickPromptsRow

private struct QuickPromptsRow: View {
    let prompts: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        onSelect(prompt)
                    } label: {
                        Text(prompt)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(prompt)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
    }
}

// MARK: - InputBar

private struct InputBar: View {
    @Binding var inputText: String
    let onSend: () -> Void

    private var isSendDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: Spacing.sm) {
                // Attachment / profile button (no-op)
                Button {
                    // No-op
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(white: 0.55))
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Attach profile")

                // Text field pill
                HStack(spacing: Spacing.xs) {
                    TextField("Ask about your progress...", text: $inputText, axis: .vertical)
                        .font(.system(size: 15))
                        .lineLimit(1 ... 4)
                        .foregroundStyle(Color.black)
                        .accessibilityLabel("Message input")

                    // Mic icon (no-op, visual only)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(white: 0.65))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 10)
                .background(Color(white: 0.94))
                .clipShape(Capsule())

                // Send button — green circle
                Button {
                    onSend()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.brandGreen)
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                }
                .disabled(isSendDisabled)
                .opacity(isSendDisabled ? 0.5 : 1.0)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color.white)
    }
}

// MARK: - Preview

#Preview {
    SkinInAIView()
}
