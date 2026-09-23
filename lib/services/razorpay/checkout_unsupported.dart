import 'checkout_types.dart';

RazorpayCheckout createRazorpayCheckout() => _UnsupportedCheckout();

class _UnsupportedCheckout implements RazorpayCheckout {
  @override
  Future<CheckoutResult> open(CheckoutRequest request) async =>
      const CheckoutResult.failed(
        'Online payment is not available on this device.',
      );
}
