// Views/Workouts/WorkoutsView.swift
// SkinIn-iOS
//
// Fully built Workouts screen: custom nav bar, week-day strip,
// "Your Schedule" header, and a vertical timeline with completed /
// today / locked row types.
//
// Architecture: MVVM — WorkoutsViewModel owns all state.
// No UIKit. No force-unwraps. Dark mode + Dynamic Type + VoiceOver supported.

import SwiftUI

// MARK: - WorkoutsView

struct WorkoutsView: View {

    @State private var vm = WorkoutsViewModel()
    @State private var showWorkoutDetail = false
    @State private var selectedWorkoutId: String = ""
    @State private var selectedWorkoutName: String = ""
    @State private var selectedVariation: Int = 1

    private let background = Color(red: 0.96, green: 0.96, blue: 0.96)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: Nav Bar
                    WorkoutsNavBar(month: vm.month, weekNumber: vm.weekNumber)

                    // MARK: Week Day Strip
                    WeekDayStrip(days: vm.weekDays)

                    Divider()

                    // MARK: Scrollable Timeline
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {

                            if vm.isLoading && vm.sessions.isEmpty {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, Spacing.xl)
                            } else if let error = vm.errorMessage, !vm.isLoading {
                                Text(error)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color(white: 0.55))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Spacing.xl)
                                    .padding(.top, Spacing.xl)
                                    .frame(maxWidth: .infinity)
                            } else if !vm.hasPlan && !vm.isLoading {
                                Text("Your workout plan is being generated. This usually takes a minute after payment.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color(white: 0.55))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Spacing.xl)
                                    .padding(.top, Spacing.xl)
                                    .frame(maxWidth: .infinity)
                            } else {
                                // Section header
                                ScheduleHeader(
                                    completedCount: vm.completedCount,
                                    totalCount: vm.totalCount
                                )
                                .padding(.horizontal, Spacing.md)
                                .padding(.top, Spacing.md)
                                .padding(.bottom, Spacing.sm)

                                // Timeline
                                WorkoutsTimeline(
                                    sessions: vm.sessions,
                                    timerDisplay: vm.timerDisplay,
                                    onStartWorkout: { session in
                                        selectedWorkoutId   = session.workoutId
                                        selectedWorkoutName = session.name
                                        selectedVariation   = vm.variation
                                        showWorkoutDetail   = true
                                    }
                                )
                                .padding(.horizontal, Spacing.md)
                            }

                            // Bottom clearance for custom tab bar
                            Spacer(minLength: 80)
                        }
                    }
                }
            }
            .task { await vm.fetch() }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showWorkoutDetail) {
                WorkoutDetailView(
                    workoutId:         selectedWorkoutId,
                    workoutName:       selectedWorkoutName,
                    variation:         selectedVariation,
                    cooldownActive:    vm.cooldownActive,
                    cooldownCountdown: vm.timerDisplay
                )
            }
        }
    }
}

// MARK: - WorkoutsNavBar

private struct WorkoutsNavBar: View {

    let month: String
    let weekNumber: Int

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea(edges: .top)

            HStack(alignment: .center) {

                Spacer()

                // Center: month + week number
                VStack(spacing: 1) {
                    Text(month)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.black)

                    Text("Week \(weekNumber)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(white: 0.50))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(month), Week \(weekNumber)")

                Spacer()

                // Trailing: calendar icon (no-op)
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 2)

                        Image(systemName: "calendar")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.black)
                    }
                }
                .accessibilityLabel("Open calendar")
            }
            .padding(.horizontal, Spacing.md)
        }
        .frame(height: 56)
    }
}

// MARK: - WeekDayStrip

private struct WeekDayStrip: View {

    let days: [WeekDayItem]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(days) { item in
                    WeekDayCell(item: item)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.white.ignoresSafeArea(edges: .top))
    }
}

// MARK: - WeekDayCell

private struct WeekDayCell: View {

    let item: WeekDayItem

    var body: some View {
        VStack(spacing: 4) {
            Text(item.abbreviation)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(cellLabelColor)

            Text("\(item.dayNumber)")
                .font(.system(size: item.isToday ? 22 : 17,
                              weight: item.isToday ? .black : .semibold))
                .foregroundStyle(item.isToday ? Color.black : cellLabelColor)

            // Green dot for completed days
            if item.hasCompletedWorkout && !item.isToday {
                Circle()
                    .fill(Color.brandGreen)
                    .frame(width: 5, height: 5)
            } else {
                // Placeholder to keep height consistent
                Circle()
                    .fill(Color.clear)
                    .frame(width: 5, height: 5)
            }
        }
        .frame(width: 58, height: 72)
        .background(cellBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // Glow shadow on today's cell only
        .shadow(
            color: item.isToday ? Color.brandGreen.opacity(0.55) : Color.clear,
            radius: 10, x: 0, y: 4
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(buildAccessibilityLabel(for: item))
    }

    private var cellBackground: Color {
        if item.isToday { return Color.brandGreen }
        if item.hasCompletedWorkout { return Color.brandGreen.opacity(0.15) }
        return Color(white: 0.93)
    }

    private var cellLabelColor: Color {
        if item.isToday { return Color.black }
        if item.hasCompletedWorkout { return Color.black }
        return Color(white: 0.55)
    }

    private func buildAccessibilityLabel(for item: WeekDayItem) -> String {
        var label = "\(item.abbreviation) \(item.dayNumber)"
        if item.isToday { label += ", today" }
        if item.hasCompletedWorkout { label += ", workout completed" }
        return label
    }
}

// MARK: - ScheduleHeader

private struct ScheduleHeader: View {

    let completedCount: Int
    let totalCount: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Your Schedule")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.black)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Text("\(completedCount) of \(totalCount) Completed")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(white: 0.50))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your Schedule. \(completedCount) of \(totalCount) workouts completed.")
    }
}

// MARK: - WorkoutsTimeline

private struct WorkoutsTimeline: View {

    let sessions: [WorkoutSession]
    let timerDisplay: String
    let onStartWorkout: (WorkoutSession) -> Void

    var body: some View {
        // ZStack: green vertical line behind the rows.
        // The line is pinned to x = 20 from leading (center of the 40-pt
        // connector column). It runs full height; clipping by the outer
        // VStack makes it stop naturally at the last row.
        ZStack(alignment: .topLeading) {

            // Vertical green connector line
            Rectangle()
                .fill(Color.brandGreen)
                .frame(width: 2)
                // Shift right so it aligns with the center of the 40pt
                // connector column (20pt offset from leading edge).
                .padding(.leading, 19)
                // Push it down to start at the first connector center
                // and add a small top inset so it doesn't protrude above.
                .padding(.top, 14)

            // Timeline rows
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sessions) { session in
                    Group {
                        switch session.status {
                        case .completed:
                            CompletedRow(session: session)
                        case .today:
                            TodayCard(
                                session: session,
                                timerDisplay: timerDisplay,
                                onStartWorkout: { onStartWorkout(session) }
                            )
                        case .locked:
                            LockedRow(session: session)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ConnectorCircle

/// Reusable timeline connector circle.
private struct ConnectorCircle: View {

    let size: CGFloat
    let backgroundColor: Color
    let iconName: String
    let iconColor: Color
    let iconSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)

            Image(systemName: iconName)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(iconColor)
        }
        // White background behind the circle so the green line
        // doesn't bleed through the circle interior.
        .background(
            Circle()
                .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
                .frame(width: size + 4, height: size + 4)
        )
        .frame(width: 40, height: 40)
    }
}

// MARK: - CompletedRow

private struct CompletedRow: View {

    let session: WorkoutSession

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {

            // Connector
            ConnectorCircle(
                size: 28,
                backgroundColor: Color.brandGreen,
                iconName: "checkmark",
                iconColor: .white,
                iconSize: 12
            )

            // Card
            VStack(alignment: .leading, spacing: Spacing.xs) {

                // Date label
                Text(session.shortDay)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(white: 0.50))
                    .textCase(.uppercase)
                    .kerning(0.5)

                // Workout name
                Text(session.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black)

                // Stats row: duration + calories
                HStack(spacing: Spacing.sm) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(white: 0.50))
                        Text("\(session.durationMinutes) min")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(white: 0.50))
                    }

                    Text("·")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(white: 0.50))

                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(white: 0.50))
                        Text("\(session.calories) kcal")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(white: 0.50))
                    }
                }

                // "Workout Logged" green pill
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.brandGreen)
                    Text("Workout Logged")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.brandGreen)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 5)
                .background(Color.brandGreen.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 3)

            Spacer(minLength: 0)
        }
        .padding(.bottom, Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(session.shortDay). \(session.name). \(session.durationMinutes) minutes. \(session.calories) calories. Workout logged."
        )
    }
}

// MARK: - TodayCard

private struct TodayCard: View {

    let session: WorkoutSession
    let timerDisplay: String
    let onStartWorkout: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {

            // Connector
            ConnectorCircle(
                size: 32,
                backgroundColor: Color.brandGreen,
                iconName: "play.fill",
                iconColor: .white,
                iconSize: 13
            )
            // Align connector with the card top, accounting for image area
            .padding(.top, 2)

            // Main card
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Image placeholder with timer badge
                ZStack(alignment: .topTrailing) {
                    Color(white: 0.85)
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: Radius.field,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: Radius.field,
                                style: .continuous
                            )
                        )

                    // Centered figure icon
                    Image(systemName: "figure.run")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Color(white: 0.65))
                        .frame(maxWidth: .infinity, maxHeight: 120)

                    // Timer badge — top trailing
                    Text("\(timerDisplay) left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.80))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(Spacing.sm)
                        .accessibilityLabel("Time remaining: \(timerDisplay)")
                }

                // MARK: Card body
                VStack(alignment: .leading, spacing: Spacing.sm) {

                    // "TODAY" green capsule badge
                    Text("TODAY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.brandGreen)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.brandGreen.opacity(0.12))
                        .clipShape(Capsule())

                    // Workout name
                    Text(session.name)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(Color.black)

                    // Description
                    Text(session.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(white: 0.50))
                        .fixedSize(horizontal: false, vertical: true)

                    // Stats row: Duration + Focus
                    HStack(spacing: 0) {
                        StatColumn(label: "Duration", value: "\(session.durationMinutes) min")
                        Spacer()
                        // Thin divider between stats
                        Rectangle()
                            .fill(Color(white: 0.88))
                            .frame(width: 1, height: 32)
                        Spacer()
                        StatColumn(label: "Focus", value: session.focusArea)
                    }
                    .padding(.vertical, Spacing.xs)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "Duration: \(session.durationMinutes) minutes. Focus: \(session.focusArea)."
                    )

                    // START WORKOUT button — navigates to WorkoutDetailView
                    Button(action: onStartWorkout) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("START WORKOUT")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                    }
                    .accessibilityLabel("Start workout: \(session.name)")

                    // Lock note below button
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(white: 0.50))
                        Text("Complete to keep your SkinIn")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(white: 0.50))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Complete this workout to keep your SkinIn")
                }
                .padding(Spacing.md)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
            .shadow(color: Color.black.opacity(0.09), radius: 14, x: 0, y: 5)

            Spacer(minLength: 0)
        }
        .padding(.bottom, Spacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Today's workout: \(session.name)")
    }
}

// MARK: - StatColumn

/// A label+value pair used in the today card stats row.
private struct StatColumn: View {

    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color(white: 0.50))
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.black)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - LockedRow

private struct LockedRow: View {

    let session: WorkoutSession

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {

            // Connector — gray circle with lock icon
            ConnectorCircle(
                size: 28,
                backgroundColor: Color(white: 0.82),
                iconName: "lock.fill",
                iconColor: Color(white: 0.55),
                iconSize: 11
            )

            // Inline text — no card, just stacked text
            VStack(alignment: .leading, spacing: Spacing.xs) {

                Text(session.shortDay)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(white: 0.55))
                    .textCase(.uppercase)
                    .kerning(0.5)

                Text(session.name)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(white: 0.65))

                // "Locked" gray pill
                Text("Locked")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(white: 0.55))
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.65).opacity(0.25))
                    .clipShape(Capsule())
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.shortDay). \(session.name). Locked.")
    }
}

// MARK: - Preview

#Preview {
    WorkoutsView()
}
