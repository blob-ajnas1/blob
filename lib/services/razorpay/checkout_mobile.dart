import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'checkout_types.dart';

RazorpayCheckout createRazorpayCheckout() => _MobileCheckout();

/// Native Razorpay Checkout (UPI apps, cards, netbanking, wallets).
class _MobileCheckout implements RazorpayCheckout {
  @override
  Future<CheckoutResult> open(CheckoutRequest request) {
    final completer = Completer<CheckoutResult>();
    // A fresh instance per payment so a late event from an earlier checkout
    // can never complete this one.
    final razorpay = Razorpay();

    void finish(CheckoutResult result) {
      if (completer.isCompleted) return;
      razorpay.clear();
      completer.complete(result);
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      final id = r.paymentId;
      finish(
        id == null || id.isEmpty
            ? const CheckoutResult.failed(
                'Payment could not be confirmed. If money was debited it '
                'will be refunded automatically.',
              )
            : CheckoutResult.success(id),
      );
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      if (r.code == Razorpay.PAYMENT_CANCELLED) {
        finish(const CheckoutResult.cancelled());
      } else if (r.code == Razorpay.NETWORK_ERROR) {
        finish(
          const CheckoutResult.failed(
            'Network problem during payment. Check your connection and '
            'try again.',
          ),
        );
      } else {
        finish(CheckoutResult.failed(_friendly(r.message)));
      }
    });

    // Paying through an external wallet hands off outside the SDK; we can't
    // confirm it here, so treat it as not paid rather than guess.
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      finish(
        CheckoutResult.failed(
          '${r.walletName ?? 'That wallet'} is not supported for this '
          'payment. Please choose UPI, card or netbanking.',
        ),
      );
    });

    try {
      razorpay.open(request.toOptions());
    } catch (e) {
      finish(const CheckoutResult.failed('Could not open the payment screen.'));
    }
    return completer.future;
  }

  static String _friendly(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.trim().startsWith('{')) {
      return 'Payment failed. No money was taken — please try again.';
    }
    return raw;
  }
}
