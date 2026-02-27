// Views/Main/MainTabViewModel.swift
// SkinIn-iOS
//
// Owns the selected tab state for the custom tab bar shell.
// Child feature views may receive a binding to selectedTab
// if they need to trigger tab switches.

import Foundation
import Observation

// MARK: - AppTab

enum AppTab: Int, CaseIterable {
    case home
    case progress
    case workouts
    case nutrition
    case profile
}

// MARK: - MainTabViewModel

@Observable
final class MainTabViewModel {
    var selectedTab: AppTab = .home
}
