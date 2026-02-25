// Views/Payment/PaymentViewModel.swift
// SkinIn-iOS
//
// Handles the full payment lifecycle:
//   1. Create a PaymentIntent via the SkinIn API (returns clientSecret)
//   2. Confirm the payment using STPPaymentHandler with the card params
//
// Uses @Observable (iOS 17+) — no @Published wrappers.

import SwiftUI
import Stripe

// MARK: - PaymentViewModel

@Observable final class PaymentViewModel {

    // MARK: State

    var isLoading = false
    var errorMessage: String? = nil
    var cardHolderName = ""

    /// Set by CardFieldRepresentable via its delegate when card details are valid;
    /// nil when the card entry is incomplete or invalid.
    var cardParams: STPPaymentMethodCardParams? = nil

    // MARK: - Create Payment Intent

    /// Calls POST /api/payment/create-intent with the user's Supabase JWT.
    /// Returns the Stripe clientSecret string on success.
    func createPaymentIntent() async throws -> String {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/payment/create-intent") else {
            throw PaymentError.invalidURL
        }

        // Retrieve the JWT stored by SupabaseManager after sign-in
        guard let token = UserDefaults.standard.string(forKey: Config.UserDefaultsKey.supabaseSessionToken),
              !token.isEmpty else {
            throw PaymentError.missingAuthToken
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Surface server error message if the API returns one
            if let body = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw PaymentError.serverError(body.message)
            }
            throw PaymentError.serverError("HTTP \(httpResponse.statusCode)")
        }

        let intentResponse = try JSONDecoder().decode(PaymentIntentResponse.self, from: data)
        return intentResponse.clientSecret
    }

    // MARK: - Confirm Payment

    /// Confirms the Stripe PaymentIntent using STPPaymentHandler.
    /// Wraps the callback-based Stripe API in a Swift Concurrency continuation.
    /// Returns true on success; throws on failure or cancellation.
    func confirmPayment(clientSecret: String) async throws -> Bool {
        guard let params = cardParams else {
            throw PaymentError.noCardParams
        }

        // Build the payment method params (card + billing details)
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = cardHolderName.trimmingCharacters(in: .whitespaces)

        let paymentMethodParams = STPPaymentMethodParams(
            card: params,
            billingDetails: billingDetails,
            metadata: nil
        )

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams

        // STPPaymentHandler requires an STPAuthenticationContext to present 3DS UI
        let authContext = PaymentAuthContext()

        return try await withCheckedThrowingContinuation { continuation in
            STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: authContext) { status, _, error in
                switch status {
                case .succeeded:
                    continuation.resume(returning: true)
                case .canceled:
                    continuation.resume(throwing: PaymentError.canceled)
                case .failed:
                    let message = error?.localizedDescription ?? "Payment failed. Please try again."
                    continuation.resume(throwing: PaymentError.paymentFailed(message))
                @unknown default:
                    continuation.resume(throwing: PaymentError.paymentFailed("Unknown payment status."))
                }
            }
        }
    }
}

// MARK: - PaymentAuthContext

/// Provides the UIViewController context required by Stripe's 3DS authentication flow.
/// Retrieves the app's current root view controller from the connected scene.
private final class PaymentAuthContext: NSObject, STPAuthenticationContext {

    func authenticationPresentingViewController() -> UIViewController {
        // Walk up from the key window's root to find the topmost presented controller
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            // Fallback — should not happen in normal app lifecycle
            return UIViewController()
        }

        var topController = root
        while let presented = topController.presentedViewController {
            topController = presented
        }
        return topController
    }
}

// MARK: - Decodable Response Types

private struct PaymentIntentResponse: Decodable {
    let clientSecret: String
}

private struct APIErrorResponse: Decodable {
    let message: String
}

// MARK: - PaymentError

enum PaymentError: LocalizedError {
    case invalidURL
    case missingAuthToken
    case invalidResponse
    case serverError(String)
    case noCardParams
    case canceled
    case paymentFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Internal configuration error. Please contact support."
        case .missingAuthToken:
            return "You must be signed in to complete payment."
        case .invalidResponse:
            return "Received an unexpected response from the server."
        case .serverError(let detail):
            return "Server error: \(detail)"
        case .noCardParams:
            return "Please enter valid card details before continuing."
        case .canceled:
            return "Payment was canceled."
        case .paymentFailed(let detail):
            return detail
        }
    }
}
