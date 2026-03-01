// SkinIn_iOSApp.swift
// SkinIn-iOS
//
// Launch routing (evaluated in priority order):
//   fresh install (onboarding unseen) → OnboardingView  (shown once, ever)
//   authenticated + setup complete    → MainTabView  (full app shell)
//   authenticated + setup incomplete  → check backend → MainTabView or SetupContainerView
//   seen onboarding (not authed)      → LoginView
//
// TODO: When signup flow is implemented, restore the original auth-first
//       routing so a newly-signed-up user is taken straight to setup
//       without re-running the onboarding pages.

import SwiftUI
import Stripe

@main
struct SkinIn_iOSApp: App {

    @State private var supabase = SupabaseManager.shared
    @AppStorage(Config.UserDefaultsKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(Config.UserDefaultsKey.hasCompletedSetup) private var hasCompletedSetup = false
    @Environment(\.scenePhase) private var scenePhase

    // True once we've checked the backend for an existing plan.
    // Reset to false on sign-out so the check reruns on the next login.
    @State private var didCheckRemoteSetup = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if !hasSeenOnboarding {
                        // Always show onboarding on a fresh install, even if a Supabase
                        // session was restored from the Keychain (which survives deletion).
                        // TODO: When signup flow is ready, remove this top-level check and
                        //       restore the original auth-first routing below so newly
                        //       signed-up users land directly in setup after email verify.
                        OnboardingView(onFinished: {
                            hasSeenOnboarding = true
                        })
                    } else if supabase.isAuthenticated {
                        if hasCompletedSetup {
                            // Returning user with a saved plan — go straight home.
                            MainTabView()
                        } else if didCheckRemoteSetup {
                            // Backend confirmed no plan exists — run setup.
                            SetupContainerView(onSetupComplete: {
                                hasCompletedSetup = true
                            })
                        } else {
                            // Authenticated but hasCompletedSetup is false (e.g. new
                            // device, cleared UserDefaults). Check the backend once before
                            // deciding whether to show setup or go home.
                            ProgressView("Loading...")
                                .task {
                                    if await supabase.hasSavedWorkoutPlan() {
                                        hasCompletedSetup = true
                                    }
                                    didCheckRemoteSetup = true
                                }
                        }
                    } else {
                        // TODO: When signup flow is ready, add a "Don't have an account?"
                        //       link here that navigates to the signup screen.
                        LoginView()
                    }
                }
            }
            .task {
                StripeAPI.defaultPublishableKey = Config.stripePublishableKey
                await supabase.restoreSession()
            }
            // Reset the remote check whenever the user signs out so it reruns
            // on the next successful login.
            .onChange(of: supabase.isAuthenticated) { _, isAuthenticated in
                if !isAuthenticated {
                    didCheckRemoteSetup = false
                }
            }
            // Refresh the Supabase session whenever the app returns to the foreground.
            // This keeps the UserDefaults access token fresh so that ViewModels
            // (WorkoutsViewModel, HomeViewModel, ProgressViewModel) can make
            // authenticated API calls without hitting 401 after the 1-hour token expiry.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await supabase.restoreSession() }
                }
            }
        }
    }
}
