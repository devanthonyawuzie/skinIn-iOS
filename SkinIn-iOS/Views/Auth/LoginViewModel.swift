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
    var didLoginSuccessfully: Bool = false

    // MARK: - Validation

    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    // MARK: - Actions

    func signIn() async {
        guard canSubmit else { return }
        errorMessage = nil
        isLoading = true

        do {
            try await SupabaseManager.shared.signIn(email: email, password: password)
            // Navigate on the main actor after successful auth.
            await MainActor.run {
                isLoading = false
                didLoginSuccessfully = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
