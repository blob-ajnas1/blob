import 'package:intl/intl.dart';

/// SINGLE CURRENCY RULE — INR only, enforced app-wide.
/// There is deliberately no currency parameter anywhere in this class.
/// All monetary values in BLOB are stored as integer paise to avoid
/// floating-point rounding errors in the payment ledger.
class Money {
  Money._();

  static const String symbol = '\u20B9'; // ₹
  static const String code = 'INR';

  static final NumberFormat _lakh = NumberFormat.decimalPattern('en_IN');

  /// 250000 paise -> "₹2,500"
  static String format(int paise) {
    final rupees = paise / 100;
    if (rupees == rupees.roundToDouble()) {
      return '$symbol${_lakh.format(rupees.round())}';
    }
    return '$symbol${_lakh.format(double.parse(rupees.toStringAsFixed(2)))}';
  }

  /// Compact Indian format for dashboard tiles: ₹1.2L, ₹4.5Cr
  static String compact(int paise) {
    final rupees = paise / 100;
    if (rupees >= 10000000) {
      return '$symbol${(rupees / 10000000).toStringAsFixed(2)}Cr';
    }
    if (rupees >= 100000) {
      return '$symbol${(rupees / 100000).toStringAsFixed(2)}L';
    }
    return format(paise);
  }

  static int rupeesToPaise(num rupees) => (rupees * 100).round();

  static double paiseToRupees(int paise) => paise / 100;

  /// Launch period: BLOB is free to use for the first few months, so no job
  /// posting fee is charged and no fee wording is shown anywhere.
  ///
  /// Flip to `true` to reinstate "2 free posts, then ₹50 each". The Razorpay
  /// checkout, ledger rows and fee dialog all come back with it unchanged —
  /// nothing else needs editing.
  static const bool jobPostingFeesEnabled = false;

  /// ₹50 fee charged from the 3rd job posting onward.
  static const int jobPostingFeePaise = 5000;

  /// Number of free job posts each user receives.
  static const int freeJobPostLimit = 2;

  /// Platform broker commission rate (2.5% of transaction value).
  static const double brokerCommissionRate = 0.025;

  static int brokerCommissionOn(int amountPaise) =>
      (amountPaise * brokerCommissionRate).round();
}
