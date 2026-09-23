import 'package:flutter/foundation.dart';

import 'razorpay/checkout.dart';

enum PaymentOutcome { success, cancelled, failed }

class PaymentResult {
  final PaymentOutcome outcome;
  final String message;
  final String? gatewayRef;

  const PaymentResult({
    required this.outcome,
    required this.message,
    this.gatewayRef,
  });

  bool get success => outcome == PaymentOutcome.success;
  bool get cancelled => outcome == PaymentOutcome.cancelled;
}

/// Who is paying — used to prefill checkout so the payer only confirms.
class Payer {
  final String id;
  final String name;
  final String phoneE164;

  const Payer({required this.id, required this.name, required this.phoneE164});
}

/// INR-only payment gateway abstraction.
///
/// Note there is no currency argument — the single currency rule is
/// enforced at the interface level.
abstract class PaymentGateway {
  /// Human-readable mode shown to users where it matters (e.g. "Demo").
  PaymentMode get mode;

  Future<PaymentResult> charge({
    required int amountPaise,
    required String description,
    required Payer payer,
    required String reference,
  });

  Future<PaymentResult> payout({
    required int amountPaise,
    required String payeeId,
    required String description,
  });

  /// Chooses the gateway from build-time configuration:
  ///
  ///   --dart-define=RAZORPAY_KEY_ID=rzp_live_xxx   -> real Razorpay checkout
  ///   (no key, debug build or ALLOW_DEMO_PAYMENTS)  -> demo, no money moves
  ///   (no key, release build)                       -> payments refused
  ///
  /// A release build without a key refuses fees rather than waving them
  /// through: silently granting free posts in production would be a
  /// revenue leak nobody notices.
  factory PaymentGateway.fromEnvironment() {
    const keyId = String.fromEnvironment('RAZORPAY_KEY_ID');
    const allowDemo = bool.fromEnvironment('ALLOW_DEMO_PAYMENTS');
    if (keyId.isNotEmpty) return RazorpayPaymentGateway(keyId: keyId);
    if (kDebugMode || allowDemo) return DemoPaymentGateway();
    return UnconfiguredPaymentGateway();
  }
}

enum PaymentMode { live, test, demo, unavailable }

/// Real payments through Razorpay Checkout — UPI (GPay, PhonePe, Paytm,
/// BHIM), cards, netbanking and wallets. Native SDK on Android, checkout.js
/// on the web.
///
/// Only the public Key ID lives in the app. The Key Secret must never be
/// shipped; enable **auto-capture** in the Razorpay dashboard
/// (Settings → Payment Capture) so payments are captured without a server,
/// otherwise Razorpay refunds uncaptured payments after a few days.
class RazorpayPaymentGateway implements PaymentGateway {
  RazorpayPaymentGateway({required this.keyId, RazorpayCheckout? checkout})
    : _checkout = checkout ?? createRazorpayCheckout();

  final String keyId;
  final RazorpayCheckout _checkout;

  @override
  PaymentMode get mode =>
      keyId.startsWith('rzp_test_') ? PaymentMode.test : PaymentMode.live;

  @override
  Future<PaymentResult> charge({
    required int amountPaise,
    required String description,
    required Payer payer,
    required String reference,
  }) async {
    final result = await _checkout.open(
      CheckoutRequest(
        keyId: keyId,
        amountPaise: amountPaise,
        merchantName: 'BLOB',
        description: description,
        prefillName: payer.name,
        prefillContact: payer.phoneE164,
        notes: {'payer_id': payer.id, 'reference': reference},
      ),
    );
    return switch (result.status) {
      CheckoutStatus.success => PaymentResult(
        outcome: PaymentOutcome.success,
        message: 'Payment successful',
        gatewayRef: result.paymentId,
      ),
      CheckoutStatus.cancelled => const PaymentResult(
        outcome: PaymentOutcome.cancelled,
        message: 'Payment cancelled. No money was taken.',
      ),
      CheckoutStatus.failed => PaymentResult(
        outcome: PaymentOutcome.failed,
        message: result.message ?? 'Payment failed. Please try again.',
      ),
    };
  }

  /// Payouts to other users (wages, commissions) need RazorpayX and a
  /// server holding the secret key. Until then settling a payout records it
  /// in the ledger — the parties settle between themselves.
  @override
  Future<PaymentResult> payout({
    required int amountPaise,
    required String payeeId,
    required String description,
  }) async => const PaymentResult(
    outcome: PaymentOutcome.success,
    message: 'Marked as paid',
  );
}

/// Development/preview gateway: pretends to charge. Never compiled into a
/// release build unless ALLOW_DEMO_PAYMENTS is set explicitly.
class DemoPaymentGateway implements PaymentGateway {
  @override
  PaymentMode get mode => PaymentMode.demo;

  @override
  Future<PaymentResult> charge({
    required int amountPaise,
    required String description,
    required Payer payer,
    required String reference,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (kDebugMode) {
      debugPrint('[BLOB DEMO PAY] charge $amountPaise paise ($description)');
    }
    return PaymentResult(
      outcome: PaymentOutcome.success,
      message: 'Demo payment — no money was taken',
      gatewayRef: 'demo_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<PaymentResult> payout({
    required int amountPaise,
    required String payeeId,
    required String description,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const PaymentResult(
      outcome: PaymentOutcome.success,
      message: 'Marked as paid',
    );
  }
}

/// Release build shipped without a Razorpay key: refuse fees clearly.
class UnconfiguredPaymentGateway implements PaymentGateway {
  @override
  PaymentMode get mode => PaymentMode.unavailable;

  @override
  Future<PaymentResult> charge({
    required int amountPaise,
    required String description,
    required Payer payer,
    required String reference,
  }) async => const PaymentResult(
    outcome: PaymentOutcome.failed,
    message: 'Online payments are not available yet. Please try again later.',
  );

  @override
  Future<PaymentResult> payout({
    required int amountPaise,
    required String payeeId,
    required String description,
  }) async => const PaymentResult(
    outcome: PaymentOutcome.success,
    message: 'Marked as paid',
  );
}
