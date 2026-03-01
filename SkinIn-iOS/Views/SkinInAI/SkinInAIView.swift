// Views/SkinInAI/SkinInAIView.swift
// SkinIn-iOS

import SwiftUI
internal import Combine

// MARK: - SkinInAIView

struct SkinInAIView: View {

    @State private var vm = SkinInAIViewModel()

    private let pageBackground = Color(red: 0.96, green: 0.96, blue: 0.96)

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                SkinInAINavBar()

                // MARK: Message list
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: Spacing.md) {
                            DateSeparator(
                                label: vm.messages.first.map { vm.timestampLabel(for: $0.timestamp) }
                                    ?? vm.timestampLabel(for: Date())
                            )

                            ForEach(vm.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            // Typing indicator — shown while a request is in-flight
                            if vm.isLoading {
                                TypingIndicatorBubble()
                                    .id("typing")
                                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottomLeading)))
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.sm)
                    }
                    .onChange(of: vm.messages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(vm.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: vm.isLoading) { _, loading in
                        if loading {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                // MARK: Preset chips
                PresetChipsRow(presets: vm.presets, activeType: vm.activeChipType) { chip in
                    Task { vm.sendPreset(chip) }
                }

                // MARK: Text input bar
                InputBar(
                    inputText: Binding(get: { vm.inputText }, set: { vm.inputText = $0 }),
                    isLoading: vm.isLoading,
                    onSend: { vm.sendMessage() }
                )
            }
        }
        .animation(.spring(response: 0.30, dampingFraction: 0.82), value: vm.isLoading)
    }
}

// MARK: - SkinInAINavBar

private struct SkinInAINavBar: View {
    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            VStack(spacing: 3) {
                Text("SkinIn AI")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.black)

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.brandGreen)
                        .frame(width: 7, height: 7)
                    Text("Online")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(white: 0.55))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("SkinIn AI, Online")

            Spacer()

            Button {} label: {
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
            .font(.system(size: 12))
            .foregroundStyle(Color(white: 0.55))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color(white: 0.88)))
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityLabel(label)
    }
}

// MARK: - ChatBubble

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        switch message.sender {
        case .user: UserBubble(text: message.text)
        case .ai:   AIBubble(text: message.text, highlights: message.highlights)
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
                .font(.system(size: 15))
                .foregroundStyle(Color.black)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 10)
                .background(Color.brandGreen)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: 280, alignment: .trailing)
                .accessibilityLabel(text)

            Circle()
                .fill(Color(red: 0.95, green: 0.70, blue: 0.55))
                .frame(width: 28, height: 28)
                .overlay(Image(systemName: "person.fill").font(.system(size: 13)).foregroundStyle(Color.white))
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
            ZStack {
                Circle().fill(Color(red: 0.08, green: 0.20, blue: 0.08)).frame(width: 32, height: 32)
                Image(systemName: "bolt.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.brandGreen)
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

struct AttributedAIBubble: View {
    let text: String
    let highlights: [String]

    var body: some View {
        buildText()
            .font(.system(size: 15))
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
    }

    private func buildText() -> Text {
        var result    = Text("")
        var remaining = text

        while !remaining.isEmpty {
            var earliestRange: Range<String.Index>? = nil
            var earliestHighlight = ""

            for h in highlights {
                if let range = remaining.range(of: h),
                   earliestRange == nil || range.lowerBound < earliestRange!.lowerBound {
                    earliestRange     = range
                    earliestHighlight = h
                }
            }

            if let range = earliestRange {
                let before = String(remaining[remaining.startIndex ..< range.lowerBound])
                if !before.isEmpty { result = result + Text(before) }
                result    = result + Text(earliestHighlight)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.brandGreen) // swiftlint:disable:this foreground_color
                remaining = String(remaining[range.upperBound...])
            } else {
                result    = result + Text(remaining)
                remaining = ""
            }
        }
        return result
    }
}

// MARK: - TypingIndicatorBubble

/// Three animated dots shown while an AI response is in-flight.
private struct TypingIndicatorBubble: View {

    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.38, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(Color(red: 0.08, green: 0.20, blue: 0.08)).frame(width: 32, height: 32)
                Image(systemName: "bolt.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.brandGreen)
            }
            .accessibilityHidden(true)

            HStack(spacing: 5) {
                ForEach(0 ..< 3, id: \.self) { i in
                    Circle()
                        .fill(Color(white: 0.55))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.35 : 1.0)
                        .animation(.easeInOut(duration: 0.38), value: phase)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
            .onReceive(timer) { _ in
                phase = (phase + 1) % 3
            }
            .accessibilityLabel("SkinIn AI is typing")

            Spacer()
        }
    }
}

// MARK: - PresetChipsRow

/// Horizontally scrolling preset chips — Devin Chai style.
/// Active chip (currently loading) gets a brandGreen tint + spinner.
private struct PresetChipsRow: View {

    let presets:    [PresetChip]
    let activeType: String?
    let onTap:      (PresetChip) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(presets) { chip in
                    PresetChipButton(
                        chip:     chip,
                        isActive: activeType == chip.type,
                        disabled: activeType != nil
                    ) {
                        onTap(chip)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
        .overlay(Divider(), alignment: .top)
    }
}

// MARK: - PresetChipButton

private struct PresetChipButton: View {

    let chip:     PresetChip
    let isActive: Bool
    let disabled: Bool
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isActive {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.70)
                        .tint(Color.brandGreen)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: chip.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isActive ? Color.brandGreen : Color(white: 0.45))
                }

                Text(chip.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isActive ? Color.brandGreen : Color.black)
                    .lineLimit(1)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                isActive
                    ? Color.brandGreen.opacity(0.12)
                    : Color.white
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? Color.brandGreen : Color.black.opacity(0.10),
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled && !isActive ? 0.45 : 1.0)
        .accessibilityLabel(chip.label)
        .animation(.easeInOut(duration: 0.18), value: isActive)
    }
}

// MARK: - InputBar

private struct InputBar: View {
    @Binding var inputText: String
    let isLoading: Bool
    let onSend: () -> Void

    private var isSendDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: Spacing.sm) {
                Button {} label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(white: 0.55))
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Attach profile")

                HStack(spacing: Spacing.xs) {
                    TextField("Ask about your progress...", text: $inputText, axis: .vertical)
                        .font(.system(size: 15))
                        .lineLimit(1 ... 4)
                        .foregroundStyle(Color.black)
                        .accessibilityLabel("Message input")
                        .onSubmit { if !isSendDisabled { onSend() } }

                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(white: 0.65))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 10)
                .background(Color(white: 0.94))
                .clipShape(Capsule())

                Button(action: onSend) {
                    ZStack {
                        Circle()
                            .fill(isSendDisabled ? Color(white: 0.88) : Color.brandGreen)
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isSendDisabled ? Color(white: 0.55) : Color.black)
                    }
                }
                .disabled(isSendDisabled)
                .animation(.easeInOut(duration: 0.15), value: isSendDisabled)
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
