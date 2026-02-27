// Views/WorkoutDetail/WorkoutDetailView.swift
// SkinIn-iOS
//
// WorkoutDetail screen — shown when a user taps "START WORKOUT" from the
// Workouts schedule view. Pushed via NavigationStack from WorkoutsView.
//
// Architecture: MVVM — WorkoutDetailViewModel owns all state.
// Custom nav bar replaces the system bar (.navigationBarHidden(true) set on
// WorkoutsView, so we manage our own back button via @Environment dismiss).
// No UIKit. No force-unwraps. Dark mode + Dynamic Type + VoiceOver supported.

import SwiftUI

// MARK: - WorkoutDetailView

struct WorkoutDetailView: View {

    let workoutId: String
    let workoutName: String
    let variation: Int

    @State private var vm: WorkoutDetailViewModel
    @State private var showActiveWorkout = false
    @Environment(\.dismiss) private var dismiss

    init(workoutId: String, workoutName: String, variation: Int = 1) {
        self.workoutId   = workoutId
        self.workoutName = workoutName
        self.variation   = variation
        _vm = State(initialValue: WorkoutDetailViewModel(workoutId: workoutId, workoutName: workoutName, variation: variation))
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            // Light gray page background — matches setup/home screens
            Color(red: 0.96, green: 0.96, blue: 0.96)
                .ignoresSafeArea()

            // MARK: Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // Custom nav bar sits at the very top
                    WorkoutDetailNavBar(title: vm.workoutName) {
                        dismiss()
                    }

                    // Progress track
                    WorkoutProgressSection(
                        progress: vm.progress,
                        progressPercent: vm.progressPercent
                    )

                    // Duration / Difficulty / Burn stats row
                    StatsRow(
                        durationMinutes: vm.durationMinutes,
                        difficulty: vm.difficulty,
                        calories: vm.calories
                    )

                    // Exercise list
                    if vm.isLoading && vm.exercises.isEmpty {
                        ProgressView()
                            .padding(.top, Spacing.xl)
                            .frame(maxWidth: .infinity)
                    } else {
                        ExercisesSection(
                            exercises: vm.exercises,
                            movementsLabel: vm.movementsLabel
                        ) { exercise in
                            // Thumbnail tap → open video preview sheet
                            vm.selectedExercise = exercise
                            vm.showVideoPreview = true
                        }
                    }

                    // Bottom clearance so sticky footer never overlaps content
                    Spacer(minLength: 100)
                }
            }

            // MARK: Sticky bottom bar (pinned outside scroll)
            StickyBottomBar(onStart: { showActiveWorkout = true })
        }
        // Hide the system NavigationStack bar — we use our own
        .navigationBarHidden(true)
        .task { await vm.fetch() }
        .navigationDestination(isPresented: $showActiveWorkout) {
            ActiveWorkoutView(workoutId: vm.workoutId)
        }
        // Video preview sheet — presented from the vm flag
        .sheet(isPresented: Binding(
            get: { vm.showVideoPreview },
            set: { vm.showVideoPreview = $0 }
        )) {
            if let exercise = vm.selectedExercise {
                ExerciseVideoPreviewSheet(exercise: exercise) {
                    vm.showVideoPreview = false
                }
                .presentationDetents([.fraction(0.65)])
            }
        }
    }
}

// MARK: - WorkoutDetailNavBar

private struct WorkoutDetailNavBar: View {

    let title: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.white

            HStack(alignment: .center) {

                // Leading: back button
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
                .accessibilityHint("Returns to the workouts schedule")

                Spacer()

                // Center: workout name
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                // Trailing: overflow menu (no-op)
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)

                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.black)
                    }
                }
                .accessibilityLabel("More options")
            }
            .padding(.horizontal, Spacing.md)
        }
        .frame(height: 56)
        .background(Color.white.ignoresSafeArea(edges: .top))
    }
}

// MARK: - WorkoutProgressSection

private struct WorkoutProgressSection: View {

    let progress: Double
    let progressPercent: String

    var body: some View {
        VStack(spacing: Spacing.sm) {

            // Header row: label left, percent right
            HStack {
                Text("Workout Progress")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.black)

                Spacer()

                Text(progressPercent)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.brandGreen)
            }

            // Progress bar — GeometryReader drives the green fill width
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Gray track
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(white: 0.88))
                        .frame(height: 8)

                    // Green fill
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.brandGreen)
                        .frame(
                            width: max(0, geo.size.width * CGFloat(progress)),
                            height: 8
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: progress)
                }
            }
            // Fixed height so GeometryReader doesn't collapse
            .frame(height: 8)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Workout progress: \(progressPercent)")
    }
}

// MARK: - StatsRow

private struct StatsRow: View {

    let durationMinutes: Int
    let difficulty: String
    let calories: Int

    var body: some View {
        HStack(spacing: 0) {

            StatsColumn(
                icon: "clock",
                value: "\(durationMinutes) Min",
                label: "Duration"
            )

            // Vertical divider
            Rectangle()
                .fill(Color(white: 0.90))
                .frame(width: 1, height: 44)

            StatsColumn(
                icon: "figure.run",
                value: difficulty,
                label: "Difficulty"
            )

            // Vertical divider
            Rectangle()
                .fill(Color(white: 0.90))
                .frame(width: 1, height: 44)

            StatsColumn(
                icon: "flame.fill",
                value: "\(calories) Cal",
                label: "Burn"
            )
        }
        .padding(.vertical, Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 3)
        .padding(.horizontal, Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Duration: \(durationMinutes) minutes. Difficulty: \(difficulty). Burn: \(calories) calories."
        )
    }
}

// MARK: - StatsColumn

private struct StatsColumn: View {

    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.brandGreen)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.black)

            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color(white: 0.55))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ExercisesSection

private struct ExercisesSection: View {

    let exercises: [Exercise]
    let movementsLabel: String
    let onThumbnailTap: (Exercise) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Section header
            HStack {
                Text("Exercises")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.black)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Text(movementsLabel)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(white: 0.55))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)

            // Exercise rows
            VStack(spacing: Spacing.sm) {
                ForEach(exercises) { exercise in
                    ExerciseRow(exercise: exercise, onThumbnailTap: onThumbnailTap)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
        }
    }
}

// MARK: - ExerciseRow

private struct ExerciseRow: View {

    let exercise: Exercise
    let onThumbnailTap: (Exercise) -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {

            // MARK: Thumbnail — tap opens video preview
            ExerciseThumbnail(
                imageName: exercise.imageName,
                sfSymbol: exercise.sfSymbol
            )
            .onTapGesture {
                onThumbnailTap(exercise)
            }
            .accessibilityLabel("Watch \(exercise.name) demo video")
            .accessibilityAddTraits(.isButton)

            // MARK: Name + stats (flexible)
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.black)

                Text("\(exercise.sets) SETS  ·  \(exercise.reps) \(exercise.repUnit)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(white: 0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: Info button (trailing, no-op)
            Button(action: {}) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(white: 0.75))
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel("More info about \(exercise.name)")
        }
        .padding(Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - ExerciseThumbnail

/// Renders the 56x56 exercise image. Tries UIImage(named:) first;
/// falls back to the SF Symbol on a dark gray background.
private struct ExerciseThumbnail: View {

    let imageName: String
    let sfSymbol: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(white: 0.20))
                .frame(width: 56, height: 56)

            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Image(systemName: sfSymbol)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Color(white: 0.70))
            }
        }
        .frame(width: 56, height: 56)
    }
}

// MARK: - StickyBottomBar

private struct StickyBottomBar: View {

    let onStart: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {

            // START WORKOUT CTA button — navigates to ActiveWorkoutView
            Button(action: onStart) {
                Text("▶  START WORKOUT")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            }
            .padding(.horizontal, Spacing.lg)
            .accessibilityLabel("Start workout")
        }
        .padding(.bottom, Spacing.lg)
        .background(Color.white)
    }
}

// MARK: - ExerciseVideoPreviewSheet

struct ExerciseVideoPreviewSheet: View {

    let exercise: Exercise
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            // Dark sheet background
            Color(white: 0.08)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {

                // Drag handle
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(white: 0.40))
                    .frame(width: 36, height: 4)
                    .padding(.top, Spacing.sm)
                    .accessibilityHidden(true)

                // 16:9 video placeholder
                GeometryReader { geo in
                    ZStack {
                        // Background — custom image if available, else dark fill
                        if let uiImage = UIImage(named: exercise.imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.width * (9.0 / 16.0))
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                                .fill(Color(white: 0.15))
                                .frame(width: geo.size.width, height: geo.size.width * (9.0 / 16.0))
                        }

                        // Play icon — centered, tappable (no-op)
                        Button(action: {}) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Color.white)
                        }
                        .accessibilityLabel("Play \(exercise.name) demo video")
                    }
                    // Fix the GeometryReader frame to its 16:9 height
                    .frame(width: geo.size.width, height: geo.size.width * (9.0 / 16.0))
                }
                // Explicit height so the GeometryReader has room to measure
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .padding(.horizontal, Spacing.lg)

                // Exercise metadata
                VStack(spacing: Spacing.xs) {
                    Text(exercise.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)

                    Text("\(exercise.sets) Sets · \(exercise.reps) \(exercise.repUnit)")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(white: 0.60))
                }
                .multilineTextAlignment(.center)

                // Short description
                Text("Watch the movement demo to perfect your form before starting.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(white: 0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                Spacer()

                // CLOSE button
                Button(action: onClose) {
                    Text("CLOSE")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.lg)
                .accessibilityLabel("Close video preview")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutDetailView(workoutId: "preview-id", workoutName: "Preview Workout")
    }
}
