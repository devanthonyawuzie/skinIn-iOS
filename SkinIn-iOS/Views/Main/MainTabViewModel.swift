// Views/Main/MainTabViewModel.swift
// SkinIn-iOS
//
// Owns the selected tab state for the custom tab bar shell.
// Child feature views may receive a binding to selectedTab
// if they need to trigger tab switches (e.g., AI nudge → SkinIn AI tab).

import Foundation
import Observation

// MARK: - AppTab

enum AppTab: Int, CaseIterable {
    case home
    case progress
    case workouts
    case skinInAI
    case profile
}

// MARK: - MainTabViewModel

@Observable
final class MainTabViewModel {
    var selectedTab: AppTab = .home
}
