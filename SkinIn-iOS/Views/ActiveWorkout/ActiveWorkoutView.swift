// Views/ActiveWorkout/ActiveWorkoutView.swift
// SkinIn-iOS
//
// Image 19 — Live workout logging screen.
// Pushed via NavigationStack from WorkoutDetailView when the user taps
// "START WORKOUT". Displays session progress, a scrollable list of
// exercise cards (completed / active / collapsed states), and a sticky
// Submit Log bar pinned to the bottom.
//
// Architecture: MVVM — ActiveWorkoutViewModel owns all mutable state.
// @Observable (iOS 17+). No UIKit. No force-unwraps.
// Dark mode, Dynamic Type, and VoiceOver supported.

import SwiftUI

// MARK: - ActiveWorkoutView

struct ActiveWorkoutView: View {

    @State private var vm: ActiveWorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    /// workoutId is passed in from WorkoutDetailView.
    /// Defaults to a mock ID so previews and existing call sites still compile.
    init(workoutId: String = "20000000-0003-0003-0000-000000000000") {
        _vm = State(initialValue: ActiveWorkoutViewModel(workoutId: workoutId))
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            // White page background — active logging uses white, not gray
            Color.white
                .ignoresSafeArea()

            // MARK: Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // Custom nav bar
                    ActiveWorkoutNavBar(
                        workoutName: vm.workoutName,
                        weekNumber: vm.weekNumber,
                        onBack: { dismiss() }
                    )

                    // Session progress (percent, timer, bar, summary)
                    SessionProgressSection(
                        progressFraction: vm.progressFraction,
                        progressPercent: vm.progressPercent,
                        completedCount: vm.completedCount,
                        totalCount: vm.totalCount,
                        targetMinutes: vm.targetMinutes,
                        timerDisplay: vm.timerDisplay
                    )

                    // Exercise cards list
                    VStack(spacing: Spacing.md) {
                        ForEach(vm.exercises) { exercise in
                            exerciseCard(exercise)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                    // Clear the sticky bottom bar + home indicator
                    Spacer(minLength: 120)
                }
            }

            // MARK: Sticky bottom bar (pinned outside scroll)
            ActiveStickyBottomBar(vm: vm, onSubmit: {
                Task { await vm.submitLog() }
            })
        }
        // Hide system nav bar — we draw our own
        .navigationBarHidden(true)
        .task { await vm.fetchExercises() }
        // Dismiss the screen when the server confirms the log was saved
        .onChange(of: vm.submittedSuccessfully) { _, success in
            if success { dismiss() }
        }
        // Cooldown or server error alert
        .alert("Can't Submit Workout", isPresented: $vm.showSubmitError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.submitError ?? "An unexpected error occurred.")
        }
    }

    // MARK: - Exercise Card Router

    /// Selects the correct card variant based on exercise state.
    @ViewBuilder
    private func exerciseCard(_ exercise: ActiveExercise) -> some View {
        if exercise.isCompleted {
            CompletedExerciseCard(exercise: exercise)
        } else if exercise.isExpanded {
            ActiveExerciseCard(exercise: exercise, vm: vm)
        } else {
            CollapsedExerciseRow(exercise: exercise) {
                vm.toggleExpand(exerciseId: exercise.id)
            }
        }
    }
}

// MARK: - ActiveWorkoutNavBar

private struct ActiveWorkoutNavBar: View {

    let workoutName: String
    let weekNumber: Int
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.white

            HStack(alignment: .center) {

                // Leading: back button — circle with chevron
                Button(action: onBack) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)

                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.black)
                    }
                }
                .accessibilityLabel("Back")
                .accessibilityHint("Returns to workout detail")

                Spacer()

                // Center: workout name + week
                Text("\(workoutName) · Week \(weekNumber)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                // Trailing: END text button (red, no-op)
                Button(action: {}) {
                    Text("END")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(red: 1, green: 0.23, blue: 0.19))
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("End workout")
                .accessibilityHint("Ends the current workout session")
            }
            .padding(.horizontal, Spacing.md)
        }
        .frame(height: 56)
    }
}

// MARK: - SessionProgressSection

private struct SessionProgressSection: View {

    let progressFraction: Double
    let progressPercent: Int
    let completedCount: Int
    let totalCount: Int
    let targetMinutes: Int
    let timerDisplay: String

    // Red → yellow → green as the workout progresses.
    private var progressBarColor: Color {
        if progressFraction < 0.5 { return Color(red: 1.0, green: 0.23, blue: 0.19) }
        if progressFraction < 0.8 { return Color(red: 1.0, green: 0.75, blue: 0.0) }
        return Color.brandGreen
    }

    var body: some View {
        VStack(spacing: 8) {

            // Row 1: section label
            HStack {
                Text("SESSION PROGRESS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(white: 0.55))
                    .kerning(0.5)
                Spacer()
            }

            // Row 2: percent + timer
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                // "\(progressPercent)% Complete" — two different weights inline
                Text("\(progressPercent)%")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(Color.black)
                + Text(" Complete")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.black)

                Spacer()

                // Live timer with pulsing green dot
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.brandGreen)
                        .frame(width: 8, height: 8)
                        // Subtle opacity pulse — mock; a real timer would drive this
                        .accessibilityHidden(true)

                    Text(timerDisplay)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.brandGreen)
                }
                .accessibilityLabel("Elapsed time: \(timerDisplay)")
            }

            // Row 3: progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Gray track
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(white: 0.88))
                        .frame(height: 8)

                    // Coloured fill — red → yellow → green as progress increases
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(progressBarColor)
                        .frame(
                            width: max(0, geo.size.width * CGFloat(progressFraction)),
                            height: 8
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: progressFraction)
                }
            }
            // Fixed height prevents GeometryReader from collapsing
            .frame(height: 8)

            // Row 4: exercise count summary + target
            HStack {
                Text("\(completedCount) of \(totalCount) Exercises Completed")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(white: 0.55))

                Spacer()

                Text("Target: \(targetMinutes) min")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(white: 0.55))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Session progress: \(progressPercent) percent complete. \(completedCount) of \(totalCount) exercises done. Elapsed time: \(timerDisplay)."
        )
    }
}

// MARK: - CompletedExerciseCard

/// Card shown for exercises where all sets are marked done.
/// Plain white card — no green border.
private struct CompletedExerciseCard: View {

    let exercise: ActiveExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.brandGreen)
                    .accessibilityHidden(true)

                Text(exercise.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.brandGreen)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)

            // Category label
            Text(exercise.category)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(white: 0.55))
                .kerning(0.3)
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, 4)

            Divider()
                .padding(.horizontal, Spacing.md)

            // Completed set rows
            ForEach(exercise.sets) { set in
                CompletedSetRow(set: set)
                if set.id != exercise.sets.last?.id {
                    Divider()
                        .padding(.horizontal, Spacing.md)
                }
            }

            Spacer(minLength: Spacing.sm)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(exercise.name), completed")
    }
}

// MARK: - CompletedSetRow

private struct CompletedSetRow: View {

    let set: SetEntry

    var body: some View {
        HStack(spacing: 0) {
            // Set number — fixed width, zero-padded
            Text(String(format: "%02d", set.setNumber))
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(white: 0.55))
                .frame(width: 28, alignment: .leading)

            // Weight
            Text("\(set.weightLbs) lbs")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(white: 0.55))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Separator
            Text("x")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(white: 0.55))
                .padding(.horizontal, 4)

            // Reps
            Text("\(set.reps) reps")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(white: 0.55))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Done checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.brandGreen)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Set \(set.setNumber): \(set.weightLbs) pounds, \(set.reps) reps, completed"
        )
    }
}

// MARK: - ActiveExerciseCard

/// Card shown for the currently active exercise (green border).
/// Includes editable TextFields for undone sets and a "+ Add Set" footer.
private struct ActiveExerciseCard: View {

    let exercise: ActiveExercise
    // Pass the full VM so mutations can be routed through its methods.
    // Using 'let' is safe here — @Observable propagates changes through
    // the reference type without needing Binding<ActiveWorkoutViewModel>.
    let vm: ActiveWorkoutViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Overflow menu (no-op)
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(white: 0.55))
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("More options for \(exercise.name)")
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)

            // Target sets × reps — green
            Text("Target: \(exercise.targetSets) sets x \(exercise.targetRepsRange)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.brandGreen)
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, 4)

            Divider()
                .padding(.horizontal, Spacing.md)

            // Column headers
            HStack(spacing: 0) {
                Text("SET")
                    .frame(width: 36, alignment: .leading)

                Text("LBS")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("REPS")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("DONE")
                    .frame(width: 44, alignment: .center)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color(white: 0.55))
            .kerning(0.3)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 6)

            // Set rows
            ForEach(exercise.sets) { set in
                if set.isDone {
                    DoneSetRow(set: set, exerciseId: exercise.id, vm: vm)
                } else {
                    EditableSetRow(set: set, exerciseId: exercise.id, vm: vm)
                }

                if set.id != exercise.sets.last?.id {
                    Divider()
                        .padding(.horizontal, Spacing.md)
                }
            }

            // "+ Add Set" footer
            Divider()
                .padding(.horizontal, Spacing.md)

            Button {
                vm.addSet(exerciseId: exercise.id)
            } label: {
                Text("+ Add Set")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.brandGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .accessibilityLabel("Add another set to \(exercise.name)")

            Spacer(minLength: Spacing.sm)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        // Green border — 2pt stroke overlay on the same rounded shape
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.brandGreen, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(exercise.name), active")
    }
}

// MARK: - DoneSetRow

/// A set row inside the active card where isDone == true.
/// Shows read-only values with a tappable checkmark to reset.
private struct DoneSetRow: View {

    let set: SetEntry
    let exerciseId: UUID
    let vm: ActiveWorkoutViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Set number + reset icon
            HStack(spacing: 4) {
                Text("\(set.setNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.black)

                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(white: 0.55))
                    .accessibilityHidden(true)
            }
            .frame(width: 36, alignment: .leading)

            // Weight — read-only bold
            Text(set.weightLbs)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Reps — read-only bold
            Text(set.reps)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Done checkmark — tapping resets the set to undone
            Button {
                vm.toggleSetDone(exerciseId: exerciseId, setId: set.id)
            } label: {
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.brandGreen)
                    .frame(width: 44, alignment: .center)
            }
            .accessibilityLabel("Mark set \(set.setNumber) as not done")
        }
        .frame(height: 52)
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - EditableSetRow

/// A set row inside the active card where isDone == false.
/// Weight and reps are editable via TextField; a checkbox marks the set done.
private struct EditableSetRow: View {

    let set: SetEntry
    let exerciseId: UUID
    let vm: ActiveWorkoutViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Set number
            Text("\(set.setNumber)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(width: 36, alignment: .leading)

            // Weight TextField
            TextField(set.weightLbs, text: Binding(
                get: { set.weightLbs },
                set: { vm.updateWeight(exerciseId: exerciseId, setId: set.id, value: $0) }
            ))
            .keyboardType(.numberPad)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.black)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color(white: 0.80), lineWidth: 1)
            )
            .padding(.trailing, 8)
            .accessibilityLabel("Weight for set \(set.setNumber)")

            // Reps TextField
            TextField(set.reps, text: Binding(
                get: { set.reps },
                set: { vm.updateReps(exerciseId: exerciseId, setId: set.id, value: $0) }
            ))
            .keyboardType(.numberPad)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.black)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color(white: 0.80), lineWidth: 1)
            )
            .padding(.trailing, 8)
            .accessibilityLabel("Reps for set \(set.setNumber)")

            // Empty checkbox — tapping marks set done
            Button {
                vm.toggleSetDone(exerciseId: exerciseId, setId: set.id)
            } label: {
                Image(systemName: "square")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(white: 0.55))
                    .frame(width: 44, alignment: .center)
            }
            .accessibilityLabel("Mark set \(set.setNumber) as done")
        }
        .frame(height: 52)
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - CollapsedExerciseRow

/// Single-row card for upcoming exercises that are not yet expanded.
private struct CollapsedExerciseRow: View {

    let exercise: ActiveExercise
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(white: 0.55))
                    .accessibilityHidden(true)

                Text(exercise.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(exercise.targetSets) SETS · \(exercise.targetRepsRange)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(white: 0.55))
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(exercise.name), \(exercise.targetSets) sets, \(exercise.targetRepsRange). Tap to expand.")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - ActiveStickyBottomBar

/// Pinned bottom bar: server sync indicator + Submit Log button.
private struct ActiveStickyBottomBar: View {

    let vm: ActiveWorkoutViewModel
    let onSubmit: () -> Void

    /// UTC clock string for the sync indicator — refreshes each time body re-renders.
    private var utcTimeString: String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "HH:mm"
        return f.string(from: Date()) + " UTC"
    }

    var body: some View {
        VStack(spacing: 0) {

            Divider()

            // Server sync status pill
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.brandGreen)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)

                Text("SERVER SYNCED · \(utcTimeString)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(white: 0.55))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Submit Log CTA
            Button(action: onSubmit) {
                HStack(spacing: 8) {
                    if vm.isSubmitting {
                        ProgressView()
                            .tint(Color.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Submit Log")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(vm.isSubmitting ? Color(white: 0.45) : Color(white: 0.12))
                .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                .animation(.easeInOut(duration: 0.15), value: vm.isSubmitting)
            }
            .disabled(vm.isSubmitting)
            .padding(.horizontal, Spacing.lg)
            .accessibilityLabel(vm.isSubmitting ? "Submitting workout log" : "Submit workout log")

            Spacer(minLength: 0)
                .frame(height: Spacing.lg)
        }
        .background(Color.white)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActiveWorkoutView()
    }
}
