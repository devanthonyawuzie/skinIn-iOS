// ViewModels/OnboardingViewModel.swift
// SkinIn-iOS
//
// Drives the 3-page onboarding TabView. Views read currentPage and call
// goToNextPage() / finish(). No UI layout decisions live here.

import Foundation
import Observation

// MARK: - OnboardingViewModel

@Observable
final class OnboardingViewModel {

    // MARK: State

    var currentPage: Int = 0
    let totalPages: Int = 3

    // MARK: - Navigation

    func goToNextPage() {
        guard currentPage < totalPages - 1 else { return }
        currentPage += 1
    }

    /// Calls the provided completion closure so the app root can update its
    /// navigation state (e.g. set hasSeenOnboarding = true).
    func finish(completion: () -> Void) {
        completion()
    }
}
