// Views/Blueprint/BlueprintView.swift
// SkinIn-iOS
//
// Blueprint screen — shown after the setup loading step completes.
// Presents the user's goal-specific training roadmap and collects
// commitment (payment intent) via the Pay CTA.
// White background, scrollable body, pinned dark commit card at bottom.

import SwiftUI

// MARK: - BlueprintView

struct BlueprintView: View {

    // MARK: Parameters

    let goal: Goal
    /// Called when the user taps "Pay & Start Training Now" — sets hasCompletedSetup = true.
    let onComplete: () -> Void
    /// Called when the user taps the X dismiss button — same effect as onComplete for now.
    let onDismiss: () -> Void

    // MARK: ViewModel

    @State private var vm: BlueprintViewModel

    // MARK: Sheet State

    /// Controls presentation of the custom Stripe payment sheet.
    @State private var showPaymentSheet = false

    // MARK: Init

    init(goal: Goal, onComplete: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.goal = goal
        self.onComplete = onComplete
        self.onDismiss = onDismiss
        // Initialise ViewModel here so goal is available immediately.
        self._vm = State(initialValue: BlueprintViewModel(goal: goal))
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen white background
            Color.white.ignoresSafeArea()

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Navigation Bar
                    navigationBar
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)

                    // MARK: Badge
                    premiumBadge
                        .padding(.top, Spacing.lg)
                        .padding(.horizontal, Spacing.lg)

                    // MARK: Title + Subtitle
                    titleBlock
                        .padding(.top, Spacing.md)
                        .padding(.horizontal, Spacing.lg)

                    // MARK: Roadmap Section
                    sectionHeader("The Roadmap")
                        .padding(.top, Spacing.xl)
                        .padding(.horizontal, Spacing.lg)

                    roadmapSection
                        .padding(.top, Spacing.sm)
                        .padding(.horizontal, Spacing.lg)

                    // MARK: What's Included Section
                    sectionHeader("What's Included")
                        .padding(.top, Spacing.xl)
                        .padding(.horizontal, Spacing.lg)

                    featuresSection
                        .padding(.top, Spacing.sm)
                        .padding(.horizontal, Spacing.lg)

                    // MARK: Commit Card (inline, last item in scroll)
                    commitCard
                        .padding(.top, Spacing.xl)
                        .padding(.horizontal, Spacing.lg)

                    // MARK: Disclaimer
                    disclaimerText
                        .padding(.top, Spacing.md)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.xxl)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showPaymentSheet) {
            PaymentView(onSuccess: {
                showPaymentSheet = false
                onComplete()
            })
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            // Back chevron — matches setup screen circle button style
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .accessibilityLabel("Go back")

            Spacer()

            Text("SkinIn Blueprint")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            // X dismiss button — same circle style
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .accessibilityLabel("Dismiss Blueprint")
        }
    }

    // MARK: - Premium Badge

    private var premiumBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.black)
                .accessibilityHidden(true)

            Text("PREMIUM PROGRAM")
                .font(.badgeLabel)
                .foregroundStyle(Color.black)
                .kerning(0.5)
        }
        .padding(.vertical, Spacing.xs + 2)
        .padding(.horizontal, Spacing.sm + 4)
        .background(Color.brandGreen)
        .clipShape(Capsule())
        .accessibilityLabel("Premium program badge")
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(vm.blueprintTitle)
                .font(.displayHeadline)
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(vm.blueprintSubtitle)
                .font(.bodyRegular)
                .foregroundStyle(Color(white: 0.45))
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.badgeLabel)
            .foregroundStyle(Color.brandGreen)
            .kerning(1.0)
    }

    // MARK: - Roadmap Section

    private var roadmapSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(vm.roadmapWeeks.enumerated()), id: \.offset) { index, week in
                HStack(alignment: .top, spacing: Spacing.md) {

                    // Indicator column: circle + connector line
                    VStack(spacing: 0) {
                        roadmapIndicator(for: week.status)

                        // Connector line between rows (not after last row)
                        if index < vm.roadmapWeeks.count - 1 {
                            Rectangle()
                                .fill(Color(white: 0.88))
                                .frame(width: 1)
                                .frame(minHeight: 36)
                        }
                    }

                    // Row content
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        roadmapRowContent(for: week)
                    }
                    // Push down to vertically align with the circle centre
                    .padding(.top, 4)
                    .padding(.bottom, index < vm.roadmapWeeks.count - 1 ? Spacing.md : 0)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Training roadmap")
    }

    @ViewBuilder
    private func roadmapIndicator(for status: RoadmapWeek.Status) -> some View {
        switch status {
        case .unlocked:
            ZStack {
                Circle()
                    .fill(Color.brandGreen)
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.black)
                    .accessibilityHidden(true)
            }
        case .locked:
            ZStack {
                Circle()
                    .fill(Color(white: 0.90))
                    .frame(width: 28, height: 28)
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(white: 0.70))
                    .accessibilityHidden(true)
            }
        case .lockedDim:
            ZStack {
                Circle()
                    .fill(Color(white: 0.93))
                    .frame(width: 28, height: 28)
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(white: 0.80))
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder
    private func roadmapRowContent(for week: RoadmapWeek) -> some View {
        switch week.status {
        case .unlocked:
            // Bold black title
            Text(week.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.black)
                .fixedSize(horizontal: false, vertical: true)

            // Detail: "4 Days/Week · UNLOCKED" — all in brandGreen
            if !week.detail.isEmpty {
                HStack(spacing: 4) {
                    Text(week.detail)
                    Text("·")
                    Text("UNLOCKED")
                }
                .font(.badgeLabel)
                .foregroundStyle(Color.brandGreen)
                .accessibilityLabel("\(week.detail). Unlocked.")
            }

        case .locked:
            Text(week.title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(white: 0.40))
                .fixedSize(horizontal: false, vertical: true)

            if !week.detail.isEmpty {
                Text(week.detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(white: 0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .lockedDim:
            Text(week.title)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(white: 0.60))
                .fixedSize(horizontal: false, vertical: true)
            // No detail row for lockedDim per spec
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(vm.features, id: \.title) { feature in
                BlueprintFeatureRow(feature: feature)
            }
        }
    }

    // MARK: - Commit Card

    private var commitCard: some View {
        VStack(spacing: Spacing.md) {

            // Title
            Text("Commit to the Program")
                .font(.sectionHeadline)
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            // Price
            Text("$80.00")
                .font(.system(size: 42, weight: .bold, design: .default))
                .foregroundStyle(Color.brandGreen)
                .multilineTextAlignment(.center)

            // Body copy
            Text("Put your skin in the game. Complete the program to get your money back. It\u{2019}s free if you do the work.")
                .font(.bodyRegular)
                .foregroundStyle(Color(white: 0.75))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // CTA button — opens the payment sheet; onComplete is called only after successful payment
            Button(action: { showPaymentSheet = true }) {
                Text("Pay & Start Training Now\u{2192}")
                    .font(.buttonLabel)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            }
            .padding(.top, Spacing.xs)
            .accessibilityLabel("Pay and start training now")

            // Stripe security badge
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.45))
                Text("Secured by")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.45))
                Image("stripe")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 22)
                    .colorMultiply(Color(white: 0.55))
            }
            .accessibilityLabel("Payment secured by Stripe")

            // Missed workout text link
            Button(action: {
                // TODO: Present missed workout policy sheet
            }) {
                Text("What if I miss a workout?")
                    .font(.linkLabel)
                    .foregroundStyle(Color(white: 0.55))
                    .underline(false)
            }
            .accessibilityLabel("What if I miss a workout? Tap to learn more.")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xl)
        .background(Color(red: 0.10, green: 0.10, blue: 0.10))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    // MARK: - Disclaimer

    private var disclaimerText: some View {
        Text("By continuing, you agree to our Terms of Service and Refund Policy. Results may vary.")
            .font(.caption)
            .foregroundStyle(Color(white: 0.55))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - BlueprintFeatureRow

private struct BlueprintFeatureRow: View {

    let feature: BlueprintFeature

    var body: some View {
        HStack(spacing: Spacing.md) {

            // Icon in soft tinted rounded-rect background
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: feature.sfSymbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(feature.color)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.black)

                Text(feature.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(white: 0.45))
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(feature.title): \(feature.subtitle)")
    }
}

// MARK: - Previews

#Preview("Muscle Gain") {
    NavigationStack {
        BlueprintView(
            goal: .muscleGain,
            onComplete: { },
            onDismiss: { }
        )
    }
}

#Preview("Fat Loss") {
    NavigationStack {
        BlueprintView(
            goal: .fatLoss,
            onComplete: { },
            onDismiss: { }
        )
    }
}
