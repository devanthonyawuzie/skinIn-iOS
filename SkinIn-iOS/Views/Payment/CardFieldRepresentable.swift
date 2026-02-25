// Views/Payment/CardFieldRepresentable.swift
// SkinIn-iOS
//
// UIViewRepresentable wrapping Stripe's STPPaymentCardTextField.
// The binding is set to a non-nil STPPaymentMethodCardParams when
// card entry is valid, and nil when incomplete/invalid.

import SwiftUI
import Stripe

// MARK: - CardFieldRepresentable

struct CardFieldRepresentable: UIViewRepresentable {

    // MARK: Binding

    /// Non-nil when the card number, expiry, and CVC are all valid.
    @Binding var cardParams: STPPaymentMethodCardParams?

    // MARK: UIViewRepresentable

    func makeUIView(context: Context) -> STPPaymentCardTextField {
        let cardField = STPPaymentCardTextField()
        cardField.delegate = context.coordinator

        // MARK: Styling — matches the light-gray input theme used across the app
        cardField.textColor = UIColor.black
        cardField.backgroundColor = UIColor(white: 0.97, alpha: 1)
        cardField.placeholderColor = UIColor(white: 0.55, alpha: 1)
        cardField.borderColor = UIColor.clear
        cardField.borderWidth = 0
        cardField.cornerRadius = 12

        return cardField
    }

    func updateUIView(_ uiView: STPPaymentCardTextField, context: Context) {
        // No update needed — the card field manages its own state internally.
        // We only read out via the delegate callback.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(cardParams: $cardParams)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, STPPaymentCardTextFieldDelegate {

        private var cardParams: Binding<STPPaymentMethodCardParams?>

        init(cardParams: Binding<STPPaymentMethodCardParams?>) {
            self.cardParams = cardParams
        }

        /// Called on every keystroke. Update the binding based on validity.
        func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
            if textField.isValid {
                cardParams.wrappedValue = textField.paymentMethodParams.card
            } else {
                cardParams.wrappedValue = nil
            }
        }
    }
}
