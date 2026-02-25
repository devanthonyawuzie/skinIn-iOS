// SkinIn_iOSApp.swift
// SkinIn-iOS
//
// Launch routing (evaluated in priority order):
//   authenticated + setup complete   → MainTabView  (full app shell)
//   authenticated + setup incomplete → SetupContainerView
//   seen onboarding (not authed)     → LoginView
//   fresh install                    → OnboardingView  (shown once, ever)

import SwiftUI
import Stripe

@main
struct SkinIn_iOSApp: App {

    @State private var supabase = SupabaseManager.shared
    @AppStorage(Config.UserDefaultsKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(Config.UserDefaultsKey.hasCompletedSetup) private var hasCompletedSetup = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if supabase.isAuthenticated {
                        if hasCompletedSetup {
                            // Full app shell — NavigationStack not needed at this level;
                            // each tab manages its own navigation internally.
                            MainTabView()
                        } else {
                            SetupContainerView(onSetupComplete: {
                                // @AppStorage write triggers a re-render automatically.
                                hasCompletedSetup = true
                            })
                        }
                    } else if hasSeenOnboarding {
                        LoginView()
                    } else {
                        OnboardingView(onFinished: {
                            hasSeenOnboarding = true
                        })
                    }
                }
            }
            .task {
                StripeAPI.defaultPublishableKey = Config.stripePublishableKey
                await supabase.restoreSession()
            }
        }
    }
}
