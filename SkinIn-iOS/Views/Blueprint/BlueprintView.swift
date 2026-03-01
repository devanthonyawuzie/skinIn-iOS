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

                    // MARK: Nutrition Targets Card
                    if let targets = vm.nutritionTargets {
                        NutritionTargetCard(targets: targets)
                            .padding(.top, Spacing.lg)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // MARK: Generate Error Banner
                    if let err = vm.generateError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.orange)
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.orange)
                            Spacer()
                            Button("Retry") { Task { await vm.generatePlan() } }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.brandGreen)
                        }
                        .padding(Spacing.sm)
                        .background(Color.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.sm)
                    }

                    // MARK: Roadmap Section
                    HStack(alignment: .bottom) {
                        sectionHeader("The Roadmap")
                        Spacer()
                        if vm.generatedPlan != nil {
                            Button(action: { vm.showAllWeeks.toggle() }) {
                                Text(vm.showAllWeeks ? "View Less" : "View All")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.brandGreen)
                            }
                            .accessibilityLabel(vm.showAllWeeks ? "Collapse roadmap" : "Expand to show all 12 weeks")
                        }
                    }
                    .padding(.top, Spacing.xl)
                    .padding(.horizontal, Spacing.lg)
                    .animation(.easeInOut(duration: 0.2), value: vm.showAllWeeks)

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

            // MARK: Generating Overlay
            // Covers the screen while SkinIn builds the AI plan.
            if vm.isGenerating {
                ZStack {
                    Color.white.ignoresSafeArea()
                    VStack(spacing: 24) {
                        // Pulsing brain icon container
                        ZStack {
                            Circle()
                                .fill(Color.brandGreen.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(Color.brandGreen)
                                .accessibilityHidden(true)
                        }
                        VStack(spacing: 8) {
                            Text("SkinIn is crafting\nyour plan...")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.black)
                                .multilineTextAlignment(.center)
                            Text("Analysing your goals and training science")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(white: 0.55))
                        }
                        ProgressView()
                            .tint(Color.brandGreen)
                            .scaleEffect(1.3)
                    }
                }
                .transition(.opacity)
            }
            
            // MARK: Activating Subscription Overlay
            // Brief overlay shown after payment while /activate completes (~200ms).
            if vm.isActivating {
                ZStack {
                    Color.white.ignoresSafeArea()
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.brandGreen.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(Color.brandGreen)
                                .accessibilityHidden(true)
                        }
                        VStack(spacing: 8) {
                            Text("Starting your\nprogram...")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.black)
                                .multilineTextAlignment(.center)
                            Text("Almost there")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(white: 0.55))
                        }
                        ProgressView()
                            .tint(Color.brandGreen)
                            .scaleEffect(1.3)
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Activation Failed", isPresented: Binding(
            get: { vm.activationError != nil },
            set: { if !$0 { vm.activationError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.activationError ?? "")
        }
        .sheet(isPresented: $showPaymentSheet) {
            PaymentView(onSuccess: { paymentIntentId in
                // Dismiss payment sheet immediately
                showPaymentSheet = false

                // Activate the subscription (fast — just creates subscription row)
                Task {
                    #if DEBUG
                    print("[BlueprintView] Payment successful, activating subscription…")
                    #endif

                    let activated = await vm.activateSubscription(paymentIntentId: paymentIntentId)

                    await MainActor.run {
                        if activated {
                            #if DEBUG
                            print("[BlueprintView] Subscription activated, navigating to home")
                            #endif
                            onComplete()
                        } else {
                            #if DEBUG
                            print("[BlueprintView] Subscription activation failed after payment")
                            #endif
                            vm.activationError = "Payment succeeded but your subscription couldn't be activated. Please contact support."
                        }
                    }
                }
            })
        }
        .task { await vm.generatePlan() }
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

            // CTA button — disabled until plan + exercises are ready
            Button(action: { showPaymentSheet = true }) {
                Text("Pay & Start Training Now\u{2192}")
                    .font(.buttonLabel)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(vm.planReady ? Color.brandGreen : Color.brandGreen.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            }
            .disabled(!vm.planReady)
            .padding(.top, Spacing.xs)
            .accessibilityLabel("Pay and start training now")
            .accessibilityHint(vm.planReady ? "" : "Your plan is being personalised, please wait")

            // Loading indicator shown while plan is being saved + exercises generated
            if vm.isPreparingPlan {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .tint(Color(white: 0.65))
                        .scaleEffect(0.75)
                    Text("Personalising your plan\u{2026}")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.65))
                }
                .accessibilityLabel("Personalising your plan, please wait")
            }

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

// MARK: - NutritionTargetCard

private struct NutritionTargetCard: View {

    let targets: NutritionTargets

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top row: label + calorie count
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {

                    // Section label
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.brandGreen)
                            .accessibilityHidden(true)
                        Text("DAILY TARGETS")
                            .font(.badgeLabel)
                            .foregroundStyle(Color.brandGreen)
                            .kerning(0.6)
                    }

                    // Calorie number
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(targets.calories.formatted())
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black)
                        Text("kcal / day")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(white: 0.55))
                            .padding(.bottom, 3)
                    }
                }

                Spacer()

                // Circular calorie ring — decorative accent
                ZStack {
                    Circle()
                        .stroke(Color.brandGreen.opacity(0.12), lineWidth: 5)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(Color.brandGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 52, height: 52)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.brandGreen)
                        .accessibilityHidden(true)
                }
                .padding(.top, 2)
            }

            // Divider
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
                .padding(.vertical, Spacing.md)

            // Macro pills row
            HStack(spacing: Spacing.sm) {
                MacroPill(item: targets.protein, accentColor: Color.brandGreen)
                MacroPill(item: targets.fat,     accentColor: Color.orange)
                MacroPill(item: targets.carbs,   accentColor: Color(red: 0.38, green: 0.55, blue: 1.0))
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Color.brandGreen.opacity(0.18), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily targets: \(targets.calories) kilocalories. Protein \(targets.protein.grams) grams. Fat \(targets.fat.grams) grams. Carbs \(targets.carbs.grams) grams.")
    }
}

// MARK: - MacroPill

private struct MacroPill: View {

    let item: MacroItem
    let accentColor: Color

    var body: some View {
        VStack(spacing: 3) {
            // Colored dot + label
            HStack(spacing: 4) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 7, height: 7)
                Text(item.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(white: 0.50))
            }
            // Grams (bold)
            Text("\(item.grams)g")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black)
            // Percentage
            Text("\(item.pct)%")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color(white: 0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm + 2)
        .background(accentColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
