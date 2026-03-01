// Views/Main/MainTabView.swift
// SkinIn-iOS
//
// Root shell view shown after the user completes setup. Renders a custom tab bar
// with a raised center Workouts button that cannot be achieved via native TabView
// tabItem styling. The content area above the bar swaps views based on selectedTab.
//
// Layout:
//   ZStack(alignment: .bottom)
//     └── Content fill (selected feature view)
//     └── Custom tab bar (pinned bottom, 60pt tall + safe area)

import SwiftUI

// MARK: - MainTabView

struct MainTabView: View {

    @State private var vm = MainTabViewModel()

    var body: some View {
        contentView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // safeAreaInset pins the tab bar flush to the real screen bottom,
            // and automatically pushes scrollable content up by the bar's height.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CustomTabBar(selectedTab: Binding(
                    get: { vm.selectedTab },
                    set: { vm.selectedTab = $0 }
                ))
            }
            .ignoresSafeArea(.keyboard)
            .onReceive(NotificationCenter.default.publisher(for: .skinInSwitchToWorkouts)) { _ in
                vm.selectedTab = .workouts
            }
    }

    // MARK: - Content Router

    @ViewBuilder
    private var contentView: some View {
        switch vm.selectedTab {
        case .home:
            HomeView()
        case .progress:
            ProgressView_()
        case .workouts:
            WorkoutsView()
        case .nutrition:
            NutritionView()
        case .profile:
            ProfileView()
        }
    }
}

// MARK: - CustomTabBar

private struct CustomTabBar: View {

    @Binding var selectedTab: AppTab

    private let raisedOffset: CGFloat = 12
    private let barHeight: CGFloat = 60

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {

            TabBarItem(icon: "house.fill", label: "Home", isSelected: selectedTab == .home)
                .onTapGesture { selectedTab = .home }

            TabBarItem(icon: "chart.line.uptrend.xyaxis", label: "Progress", isSelected: selectedTab == .progress)
                .onTapGesture { selectedTab = .progress }

            RaisedWorkoutsButton(isSelected: selectedTab == .workouts, raisedOffset: raisedOffset)
                .onTapGesture { selectedTab = .workouts }

            TabBarItem(icon: "fork.knife", label: "Nutrition", isSelected: selectedTab == .nutrition)
                .onTapGesture { selectedTab = .nutrition }

            TabBarItem(icon: "person.fill", label: "Profile", isSelected: selectedTab == .profile)
                .onTapGesture { selectedTab = .profile }
        }
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        .background(Color.white)
        .overlay(Divider(), alignment: .top)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -4)
    }
}

// MARK: - TabBarItem

private struct TabBarItem: View {

    let icon: String
    let label: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? Color.brandGreen : Color(white: 0.55))

            Text(label)
                .font(.badgeLabel)
                .foregroundStyle(isSelected ? Color.brandGreen : Color(white: 0.55))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Switches to \(label) tab")
    }
}

// MARK: - RaisedWorkoutsButton

/// The center tab item — a green circle that floats above the tab bar baseline.
private struct RaisedWorkoutsButton: View {

    let isSelected: Bool
    let raisedOffset: CGFloat

    private let circleSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.brandGreen)
                    .frame(width: circleSize, height: circleSize)
                    .shadow(
                        color: Color.brandGreen.opacity(isSelected ? 0.45 : 0.25),
                        radius: isSelected ? 10 : 6,
                        x: 0, y: 4
                    )

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            // Push label below the circle; offset moves the whole stack upward.
            Text("Workouts")
                .font(.badgeLabel)
                .foregroundStyle(isSelected ? Color.brandGreen : Color(white: 0.55))
        }
        .frame(maxWidth: .infinity)
        // Lift the button above the bar — negative offset raises it upward.
        .offset(y: -raisedOffset)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Workouts")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Switches to Workouts tab")
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
