/// Platform-neutral request/response types for Razorpay Checkout.
///
/// The Android SDK and the web checkout.js expose different APIs; both are
/// wrapped behind [RazorpayCheckout] so the gateway above them is identical
/// on every platform.
class CheckoutRequest {
  final String keyId;
  final int amountPaise;
  final String merchantName;
  final String description;
  final String? prefillName;
  final String? prefillContact;
  final Map<String, String> notes;
  final String themeColor;

  const CheckoutRequest({
    required this.keyId,
    required this.amountPaise,
    required this.merchantName,
    required this.description,
    this.prefillName,
    this.prefillContact,
    this.notes = const {},
    this.themeColor = '#1B5E20',
  });

  /// Options map in the shape both Razorpay SDKs accept.
  /// Currency is fixed to INR — BLOB's single-currency rule.
  Map<String, dynamic> toOptions() => {
    'key': keyId,
    'amount': amountPaise,
    'currency': 'INR',
    'name': merchantName,
    'description': description,
    'prefill': {
      if (prefillName != null && prefillName!.isNotEmpty) 'name': prefillName,
      if (prefillContact != null && prefillContact!.isNotEmpty)
        'contact': prefillContact,
    },
    'notes': notes,
    'theme': {'color': themeColor},
    'retry': {'enabled': true, 'max_count': 3},
  };
}

enum CheckoutStatus { success, cancelled, failed }

class CheckoutResult {
  final CheckoutStatus status;
  final String? paymentId;
  final String? message;

  const CheckoutResult._(this.status, {this.paymentId, this.message});

  const CheckoutResult.success(String paymentId)
    : this._(CheckoutStatus.success, paymentId: paymentId);

  const CheckoutResult.cancelled([String? message])
    : this._(CheckoutStatus.cancelled, message: message);

  const CheckoutResult.failed(String message)
    : this._(CheckoutStatus.failed, message: message);
}

abstract class RazorpayCheckout {
  Future<CheckoutResult> open(CheckoutRequest request);
}
