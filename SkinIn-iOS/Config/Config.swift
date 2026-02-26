// Config/Config.swift
// SkinIn-iOS
//
// !! IMPORTANT: Fill in your project credentials before running.
// Retrieve these from your Supabase project dashboard:
//   https://supabase.com/dashboard/project/<your-project>/settings/api

import Foundation

enum Config {
    // MARK: - Supabase

    /// Your Supabase project URL, e.g. "https://xyzcompany.supabase.co"
    static let supabaseURL = "https://usbepysnmigthrovklfj.supabase.co"

    /// Your Supabase anon/public key (safe to ship in client bundles)
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzYmVweXNubWlndGhyb3ZrbGZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3OTE4MzUsImV4cCI6MjA4NzM2NzgzNX0.sjTK46zKRm0qjzibMExo5ze3pMfqwpmhoon0elPbJ90"

    // MARK: - Stripe

    /// Stripe publishable key (test mode). Safe to ship in client bundles.
    /// Replace with live key (pk_live_...) before App Store submission.
    static let stripePublishableKey = "pk_test_51T4Vm7JzfzCQp1ECfUP6ZrSbLq2z3ka76XBC3jTIjN187jYLXak54JguEnMS3jJY9DF3umwooMD4AzHzqbWDakx4003025f33j"

    // MARK: - API

    /// Base URL for the SkinIn backend REST API.
    /// TODO: Replace with production URL before App Store submission.
    static let apiBaseURL = "http://localhost:3000"

    // MARK: - UserDefaults Keys

    enum UserDefaultsKey {
        static let supabaseSessionToken = "sb_publishable_T1AIhl6CebUpXLIugZLQ0g_mOlOR18t"
        static let hasSeenOnboarding = "has_seen_onboarding"
        static let hasCompletedSetup = "has_completed_setup"
    }
}
