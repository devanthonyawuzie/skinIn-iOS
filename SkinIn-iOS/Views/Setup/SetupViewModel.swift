// ViewModels/Setup/SetupViewModel.swift
// SkinIn-iOS
//
// Single ViewModel that owns all state and side-effect logic for the
// post-login setup flow (steps 1, 2, and 3).
// Views in Views/Setup/ are pure renderers — they bind here and call
// the methods below; they import no system permission frameworks.

import Foundation
import Observation
import CoreLocation
import UserNotifications
import HealthKit

// MARK: - SetupViewModel

@Observable
final class SetupViewModel {

    // MARK: Navigation

    /// Current active step. 1 = About You, 2 = Goals, 3 = Loading.
    var currentStep: Int = 1

    // MARK: Step 1 — About You

    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: Date = Calendar.current.date(
        byAdding: .year, value: -25, to: Date()
    ) ?? Date()

    /// "Male", "Female", or "Other"
    var sex: String = "Male"

    // MARK: Step 2 — Goals

    var goal: Goal? = nil
    var experienceLevel: ExperienceLevel = .beginner
    var currentWeight: String = ""
    var goalWeight: String = ""

    // MARK: Step 2 — Optional Permissions

    var gymGeofencingEnabled: Bool = false
    var pushNotificationsEnabled: Bool = false
    var healthKitEnabled: Bool = false

    // MARK: Loading / Error State

    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: Alert State

    /// True when the user taps Next on step 2 with some permissions disabled.
    var showPermissionAlert: Bool = false

    // MARK: CLLocationManager
    // Must be a retained stored property — a local `let` in the permission
    // handler would be deallocated by ARC before the system dialog appears.
    private var locationManager = CLLocationManager()

    // MARK: - Validation

    var canProceedStep1: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canProceedStep2: Bool {
        goal != nil &&
        !currentWeight.trimmingCharacters(in: .whitespaces).isEmpty &&
        !goalWeight.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var allPermissionsEnabled: Bool {
        gymGeofencingEnabled && pushNotificationsEnabled && healthKitEnabled
    }

    /// Users must be at least 13 years old.
    var maximumDOB: Date {
        Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
    }

    // MARK: - Step Navigation

    func nextStep() {
        currentStep += 1
    }

    func previousStep() {
        currentStep = max(1, currentStep - 1)
    }

    // MARK: - Step 2 Next Tap

    func handleStep2NextTap() {
        if allPermissionsEnabled {
            advanceToLoadingStep()
        } else {
            showPermissionAlert = true
        }
    }

    func continueAnywayFromPermissionAlert() {
        advanceToLoadingStep()
    }

    private func advanceToLoadingStep() {
        currentStep = 3
    }

    // MARK: - Permission Requests

    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    func requestNotificationPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    if !granted { pushNotificationsEnabled = false }
                }
            } catch {
                await MainActor.run { pushNotificationsEnabled = false }
            }
        }
    }

    func requestHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitEnabled = false
            return
        }

        let store = HKHealthStore()
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType()
        ]

        Task {
            do {
                try await store.requestAuthorization(toShare: [], read: readTypes)
            } catch {
                await MainActor.run { healthKitEnabled = false }
            }
        }
    }

    // MARK: - Profile Save

    func saveProfile(onSuccess: @escaping () -> Void) {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await SupabaseManager.shared.saveUserProfile(self)
                await MainActor.run {
                    isLoading = false
                    // hasCompletedSetup is NOT set here — the user must confirm
                    // via BlueprintView.onComplete (Pay button) before setup is
                    // considered complete and the app root navigates to HomeView.
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
