// Views/Payment/PaymentView.swift
// SkinIn-iOS
//
// Custom payment sheet presented as a .sheet from BlueprintView.
// Layout (top to bottom):
//   - Drag handle pill
//   - Order summary card (dark bg, price in brand green)
//   - "Pay with" section: Apple Pay placeholder button, divider, card field, name field
//   - Inline error message
//   - Primary "Pay $80.00" CTA (green, full-width)
//   - TEST MODE badge

import SwiftUI
import Stripe

// MARK: - PaymentState

private enum PaymentState: Equatable {
    case idle
    case processing
    case success
    case failed(String)
}

// MARK: - PaymentView

struct PaymentView: View {

    // MARK: Parameters

    /// Called on successful payment confirmation with the confirmed payment intent ID.
    /// The parent uses this ID to call /activate and create the subscription row.
    let onSuccess: (String) -> Void

    // MARK: ViewModel

    @State private var vm = PaymentViewModel()

    // MARK: Local state

    @State private var showApplePayToast = false
    @State private var paymentState: PaymentState = .idle

    // MARK: Computed helpers

    private var isPayButtonDisabled: Bool {
        vm.cardParams == nil
            || vm.cardHolderName.trimmingCharacters(in: .whitespaces).isEmpty
            || paymentState == .processing
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Sheet background
            Color(red: 0.96, green: 0.96, blue: 0.96)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // MARK: Drag Handle
                    dragHandle
                        .padding(.top, Spacing.md)

                    // MARK: Order Summary
                    orderSummaryCard
                        .padding(.top, Spacing.md)
                        .padding(.horizontal, Spacing.md)

                    // MARK: Payment Methods Section
                    paymentSection
                        .padding(.top, Spacing.lg)
                        .padding(.horizontal, Spacing.md)

                    // MARK: Error Message
                    if let errorMessage = vm.errorMessage {
                        errorBanner(errorMessage)
                            .padding(.top, Spacing.sm)
                            .padding(.horizontal, Spacing.md)
                    }

                    // MARK: Pay CTA
                    payButton
                        .padding(.top, Spacing.md)
                        .padding(.horizontal, Spacing.md)

                    // MARK: Stripe Security Badge
                    stripeBadge
                        .padding(.top, Spacing.sm)

                    // MARK: TEST MODE Badge
                    testModeBadge
                        .padding(.top, Spacing.xs)
                        .padding(.bottom, Spacing.xl)
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            // MARK: Apple Pay Toast
            if showApplePayToast {
                applePayToast
                    .padding(.bottom, Spacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
            // MARK: Full-screen overlays
            switch paymentState {
            case .processing:
                ProcessingOverlay()
                    .transition(.opacity)
                    .zIndex(10)
            case .success:
                SuccessOverlay()
                    .transition(.opacity)
                    .zIndex(10)
            case .failed(let message):
                FailedOverlay(message: message) {
                    withAnimation { paymentState = .idle }
                }
                .transition(.opacity)
                .zIndex(10)
            case .idle:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: paymentState)
        .animation(.easeInOut(duration: 0.22), value: showApplePayToast)
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        Capsule()
            .fill(Color(white: 0.78))
            .frame(width: 36, height: 4)
            .accessibilityHidden(true)
    }

    // MARK: - Order Summary Card

    private var orderSummaryCard: some View {
        VStack(spacing: Spacing.xs) {
            Text("12-Week Accountability Program")
                .font(.sectionHeadline)
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("$80.00")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.brandGreen)

            Text("Fully refunded if you complete the program")
                .font(.bodyRegular)
                .foregroundStyle(Color(white: 0.60))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, Spacing.lg)
        .background(Color(red: 0.10, green: 0.10, blue: 0.10))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    // MARK: - Payment Section

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {

            Text("PAY WITH")
                .font(.badgeLabel)
                .foregroundStyle(Color(white: 0.50))
                .kerning(1.0)

            // Apple Pay placeholder button
            applePayButton

            // Divider with "or"
            orDivider

            // Card entry field
            VStack(spacing: Spacing.sm) {
                CardFieldRepresentable(
                    cardParams: Binding(
                        get: { vm.cardParams },
                        set: { vm.cardParams = $0 }
                    )
                )
                // Fixed height prevents the UIViewRepresentable from collapsing
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .accessibilityLabel("Card number, expiry date, and CVC")

                // Cardholder name field — same visual style as the card field
                TextField("Cardholder Name", text: Binding(
                    get: { vm.cardHolderName },
                    set: { vm.cardHolderName = $0 }
                ))
                .font(.bodyRegular)
                .foregroundStyle(Color.black)
                .autocorrectionDisabled()
                .textContentType(.name)
                .frame(height: 50)
                .padding(.horizontal, Spacing.md)
                .background(Color(white: 0.97))
                .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .accessibilityLabel("Cardholder name")
            }
        }
    }

    // MARK: - Apple Pay Placeholder Button

    private var applePayButton: some View {
        Button {
            triggerApplePayComingSoon()
        } label: {
            HStack(spacing: Spacing.sm) {
                // Apple Pay logo approximation using SF Symbols
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .accessibilityHidden(true)

                Text("Pay")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        }
        .accessibilityLabel("Apple Pay — coming soon")
    }

    // MARK: - "or" Divider

    private var orDivider: some View {
        HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(Color(white: 0.80))
                .frame(height: 1)

            Text("or")
                .font(.badgeLabel)
                .foregroundStyle(Color(white: 0.55))

            Rectangle()
                .fill(Color(white: 0.80))
                .frame(height: 1)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.textError)
                .accessibilityHidden(true)

            Text(message)
                .font(.badgeLabel)
                .foregroundStyle(Color.textError)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.textError.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .accessibilityLabel("Error: \(message)")
    }

    // MARK: - Pay CTA Button

    private var payButton: some View {
        Button {
            Task { await handlePayTapped() }
        } label: {
            ZStack {
                Text("Pay $80.00")
                    .font(.buttonLabel)
                    .foregroundStyle(Color.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isPayButtonDisabled ? Color.brandGreen.opacity(0.40) : Color.brandGreen)
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        }
        .disabled(isPayButtonDisabled)
        .accessibilityLabel("Pay 80 dollars")
        .accessibilityHint(isPayButtonDisabled ? "Enter valid card details and cardholder name to continue" : "")
    }

    // MARK: - Stripe Security Badge

    private var stripeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color(white: 0.55))
            Text("Secured by")
                .font(.system(size: 12))
                .foregroundStyle(Color(white: 0.55))
            Image("stripe")
                .resizable()
                .scaledToFit()
                .frame(height: 22)
        }
        .accessibilityLabel("Payment secured by Stripe")
    }

    // MARK: - TEST MODE Badge

    private var testModeBadge: some View {
        Text("TEST MODE")
            .font(.badgeLabel)
            .foregroundStyle(Color.white)
            .kerning(0.5)
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.sm + 4)
            .background(Color.orange)
            .clipShape(Capsule())
            .accessibilityLabel("Test mode — no real charges will be made")
    }

    // MARK: - Apple Pay Toast

    private var applePayToast: some View {
        Text("Apple Pay coming soon")
            .font(.badgeLabel)
            .foregroundStyle(Color.white)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(Color(white: 0.20))
            .clipShape(Capsule())
    }

    // MARK: - Actions

    /// Full payment flow: create intent → confirm → show result overlay.
    @MainActor
    private func handlePayTapped() async {
        withAnimation { paymentState = .processing }

        do {
            let clientSecret = try await vm.createPaymentIntent()
            let succeeded = try await vm.confirmPayment(clientSecret: clientSecret)

            if succeeded {
                withAnimation { paymentState = .success }
                // Auto-advance after 2 seconds
                try? await Task.sleep(for: .seconds(2))
                // Extract payment intent ID from "pi_XXXX_secret_XXXX" format
                let paymentIntentId = clientSecret.components(separatedBy: "_secret_").first ?? ""
                onSuccess(paymentIntentId)
            }
        } catch {
            withAnimation { paymentState = .failed(error.localizedDescription) }
        }
    }

    private func triggerApplePayComingSoon() {
        showApplePayToast = true
        // Auto-dismiss after 2 seconds
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { showApplePayToast = false }
        }
    }
}

// MARK: - ProcessingOverlay

private struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.6)
                    .tint(Color.brandGreen)

                Text("Processing payment...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.black)

                Text("Please don't close this screen")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.55))
            }
        }
        .accessibilityLabel("Processing payment, please wait")
    }
}

// MARK: - SuccessOverlay

private struct SuccessOverlay: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.brandGreen.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color.brandGreen)
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color.black)
                }

                VStack(spacing: Spacing.xs) {
                    Text("Payment Successful!")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.black)

                    Text("Starting your 12-week program...")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(white: 0.55))
                }
            }
        }
        .accessibilityLabel("Payment successful. Starting your program.")
    }
}

// MARK: - FailedOverlay

private struct FailedOverlay: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color(red: 0.92, green: 0.20, blue: 0.20))
                        .frame(width: 80, height: 80)
                    Image(systemName: "xmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color.white)
                }

                VStack(spacing: Spacing.xs) {
                    Text("Payment Failed")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.black)

                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(white: 0.50))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.buttonLabel)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                }
                .padding(.horizontal, Spacing.xl)
                .accessibilityLabel("Try again")
            }
        }
        .accessibilityLabel("Payment failed. \(message)")
    }
}

// MARK: - Preview

#Preview("Payment Sheet") {
    // Wrap in a sheet container to match real presentation context
    Color.white
        .sheet(isPresented: .constant(true)) {
            PaymentView(onSuccess: { _ in })
        }
}
