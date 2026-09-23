import 'package:blob/core/utils/money.dart';
import 'package:blob/services/payment_gateway.dart';
import 'package:blob/services/razorpay/checkout_types.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCheckout implements RazorpayCheckout {
  _FakeCheckout(this.result);
  final CheckoutResult result;
  CheckoutRequest? lastRequest;

  @override
  Future<CheckoutResult> open(CheckoutRequest request) async {
    lastRequest = request;
    return result;
  }
}

const _payer = Payer(id: 'u1', name: 'Ravi', phoneE164: '+919876543210');

Future<PaymentResult> _charge(PaymentGateway g) => g.charge(
  amountPaise: Money.jobPostingFeePaise,
  description: 'Job posting fee',
  payer: _payer,
  reference: 'job-1',
);

void main() {
  group('Razorpay gateway', () {
    test('charges exactly fifty rupees, in INR, prefilled', () async {
      final checkout = _FakeCheckout(const CheckoutResult.success('pay_123'));
      final gateway = RazorpayPaymentGateway(
        keyId: 'rzp_test_abc',
        checkout: checkout,
      );
      final result = await _charge(gateway);
      final options = checkout.lastRequest!.toOptions();

      expect(result.success, isTrue);
      expect(result.gatewayRef, 'pay_123');
      expect(options['amount'], 5000);
      expect(options['currency'], 'INR');
      expect(options['key'], 'rzp_test_abc');
      expect((options['prefill'] as Map)['contact'], '+919876543210');
      expect((options['notes'] as Map)['reference'], 'job-1');
    });

    test('cancel is reported as cancelled, not success', () async {
      final gateway = RazorpayPaymentGateway(
        keyId: 'rzp_live_abc',
        checkout: _FakeCheckout(const CheckoutResult.cancelled()),
      );
      final result = await _charge(gateway);
      expect(result.success, isFalse);
      expect(result.cancelled, isTrue);
    });

    test('failure is not success', () async {
      final gateway = RazorpayPaymentGateway(
        keyId: 'rzp_live_abc',
        checkout: _FakeCheckout(const CheckoutResult.failed('Declined')),
      );
      final result = await _charge(gateway);
      expect(result.success, isFalse);
      expect(result.cancelled, isFalse);
      expect(result.message, 'Declined');
    });

    test('mode follows the key prefix', () {
      expect(
        RazorpayPaymentGateway(
          keyId: 'rzp_test_x',
          checkout: _FakeCheckout(const CheckoutResult.cancelled()),
        ).mode,
        PaymentMode.test,
      );
      expect(
        RazorpayPaymentGateway(
          keyId: 'rzp_live_x',
          checkout: _FakeCheckout(const CheckoutResult.cancelled()),
        ).mode,
        PaymentMode.live,
      );
    });
  });

  test('an unconfigured release build refuses the fee', () async {
    final result = await _charge(UnconfiguredPaymentGateway());
    expect(result.success, isFalse);
  });
}
