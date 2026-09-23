import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'checkout_types.dart';

RazorpayCheckout createRazorpayCheckout() => _WebCheckout();

@JS('Razorpay')
extension type _RazorpayJs._(JSObject _) implements JSObject {
  external factory _RazorpayJs(JSObject options);
  external void open();
  external void on(String event, JSFunction handler);
}

/// Razorpay checkout.js (loaded from web/index.html).
class _WebCheckout implements RazorpayCheckout {
  @override
  Future<CheckoutResult> open(CheckoutRequest request) {
    if (!globalContext.has('Razorpay')) {
      return Future.value(
        const CheckoutResult.failed(
          'Payment service could not load. Check your connection and '
          'reload the page.',
        ),
      );
    }

    final completer = Completer<CheckoutResult>();
    String? lastFailure;

    void finish(CheckoutResult result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    final options = request.toOptions().jsify() as JSObject;

    options['handler'] = ((JSObject response) {
      final id = response['razorpay_payment_id']?.dartify() as String?;
      finish(
        id == null || id.isEmpty
            ? const CheckoutResult.failed('Payment could not be confirmed.')
            : CheckoutResult.success(id),
      );
    }).toJS;

    final modal = JSObject();
    modal['ondismiss'] = (() {
      // checkout.js keeps the modal open after a failed attempt so the user
      // can retry; closing it afterwards is where we report that failure.
      finish(
        lastFailure == null
            ? const CheckoutResult.cancelled()
            : CheckoutResult.failed(lastFailure!),
      );
    }).toJS;
    options['modal'] = modal;

    try {
      final rzp = _RazorpayJs(options);
      rzp.on(
        'payment.failed',
        ((JSObject response) {
          final error = response['error'] as JSObject?;
          final desc = error?['description']?.dartify() as String?;
          lastFailure = (desc == null || desc.isEmpty)
              ? 'Payment failed. No money was taken — please try again.'
              : desc;
        }).toJS,
      );
      rzp.open();
    } catch (_) {
      finish(const CheckoutResult.failed('Could not open the payment screen.'));
    }
    return completer.future;
  }
}
