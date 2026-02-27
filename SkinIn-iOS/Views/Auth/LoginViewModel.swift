// ViewModels/LoginViewModel.swift
// SkinIn-iOS
//
// All auth logic for LoginView. Views bind to published state and call
// signIn() — they never touch SupabaseManager directly.

import Foundation
import Observation

// MARK: - LoginViewModel

@Observable
final class LoginViewModel {

    // MARK: State

    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Validation

    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    // MARK: - Actions

    func signIn() async {
        guard canSubmit else {
            #if DEBUG
            print("[LoginViewModel] Cannot submit - canSubmit=false")
            #endif
            return
        }
        
        #if DEBUG
        print("[LoginViewModel] Starting sign in for email: \(email)")
        #endif
        
        errorMessage = nil
        isLoading = true

        do {
            #if DEBUG
            print("[LoginViewModel] Calling SupabaseManager.signIn()...")
            #endif
            
            try await SupabaseManager.shared.signIn(email: email, password: password)
            
            #if DEBUG
            print("[LoginViewModel] Sign in succeeded, updating UI state")
            #endif
            
            // App-level routing in SkinIn_iOSApp reacts to auth state changes.
            await MainActor.run {
                isLoading = false
                #if DEBUG
                print("[LoginViewModel] UI state updated - isLoading=false")
                #endif
            }
        } catch {
            #if DEBUG
            print("[LoginViewModel] Sign in failed with error: \(error.localizedDescription)")
            #endif
            
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                #if DEBUG
                print("[LoginViewModel] Error state set - isLoading=false, errorMessage=\(error.localizedDescription)")
                #endif
            }
        }
    }
}
