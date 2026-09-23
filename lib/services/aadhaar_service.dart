import 'dart:math';
import 'package:flutter/foundation.dart';

/// Aadhaar-linked OTP verification.
///
/// IMPORTANT — regulatory note:
/// Real Aadhaar OTP authentication runs through UIDAI and is only available
/// to a licensed AUA/KUA (Authentication User Agency) or via an authorised
/// aggregator. An app cannot call UIDAI directly. This service therefore
/// isolates the entire Aadhaar contract behind [AadhaarProvider] so that
/// swapping [DemoAadhaarProvider] for a real AUA client is a one-line change
/// with no screen or controller edits.
///
/// The demo provider never stores a full Aadhaar number — only the last four
/// digits are retained, matching UIDAI's data-minimisation guidance.
class AadhaarSendResult {
  final bool success;
  final String message;
  final String? txnId;
  final String? devCode;

  const AadhaarSendResult({
    required this.success,
    required this.message,
    this.txnId,
    this.devCode,
  });
}

class AadhaarVerifyResult {
  final bool success;
  final String message;

  /// Name as held against the Aadhaar record. Real providers return this
  /// from the e-KYC payload; we use it to pre-fill the profile.
  final String? verifiedName;

  const AadhaarVerifyResult({
    required this.success,
    required this.message,
    this.verifiedName,
  });
}

abstract class AadhaarProvider {
  Future<AadhaarSendResult> sendOtp(String aadhaarNumber, String code);
}

/// Development provider — logs the OTP instead of contacting UIDAI.
class DemoAadhaarProvider implements AadhaarProvider {
  @override
  Future<AadhaarSendResult> sendOtp(String aadhaarNumber, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (kDebugMode) {
      final masked = AadhaarService.mask(aadhaarNumber);
      debugPrint('[BLOB DEMO AADHAAR] $masked -> $code');
    }
    return AadhaarSendResult(
      success: true,
      message: 'OTP sent to the mobile number registered with Aadhaar',
      txnId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      devCode: code,
    );
  }
}

class _Pending {
  final String code;
  final String aadhaarLast4;
  final DateTime expiresAt;
  int attempts = 0;

  _Pending({
    required this.code,
    required this.aadhaarLast4,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AadhaarService {
  AadhaarService({AadhaarProvider? provider})
    : _provider = provider ?? DemoAadhaarProvider();

  final AadhaarProvider _provider;
  final Random _random = Random.secure();
  final Map<String, _Pending> _pending = {};

  static const Duration validity = Duration(minutes: 10);
  static const int maxAttempts = 5;

  /// Verhoeff checksum — the algorithm UIDAI uses for Aadhaar numbers.
  /// Catches mistyped digits and transpositions before we waste an OTP.
  static const List<List<int>> _d = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];

  static const List<List<int>> _p = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];

  /// Strips spaces and validates shape + checksum.
  static bool isValidNumber(String input) {
    final digits = normalise(input);
    if (digits.length != 12) return false;
    // UIDAI never issues a number starting with 0 or 1.
    if (digits.startsWith('0') || digits.startsWith('1')) return false;
    int c = 0;
    final reversed = digits.split('').reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      final digit = int.tryParse(reversed[i]);
      if (digit == null) return false;
      c = _d[c][_p[i % 8][digit]];
    }
    return c == 0;
  }

  static String normalise(String input) =>
      input.replaceAll(RegExp(r'[\s-]'), '');

  /// Renders as XXXX XXXX 1234 — the only form safe to display or log.
  static String mask(String input) {
    final digits = normalise(input);
    if (digits.length < 4) return 'XXXX XXXX XXXX';
    return 'XXXX XXXX ${digits.substring(digits.length - 4)}';
  }

  static String last4(String input) {
    final digits = normalise(input);
    return digits.length < 4 ? '' : digits.substring(digits.length - 4);
  }

  String _generate() => (_random.nextInt(900000) + 100000).toString();

  Future<AadhaarSendResult> requestOtp(String aadhaarNumber) async {
    final digits = normalise(aadhaarNumber);
    if (!isValidNumber(digits)) {
      return const AadhaarSendResult(
        success: false,
        message: 'That is not a valid Aadhaar number. Please check the digits.',
      );
    }
    final code = _generate();
    _pending[digits] = _Pending(
      code: code,
      aadhaarLast4: last4(digits),
      expiresAt: DateTime.now().add(validity),
    );
    return _provider.sendOtp(digits, code);
  }

  AadhaarVerifyResult verify(String aadhaarNumber, String input) {
    final digits = normalise(aadhaarNumber);
    final record = _pending[digits];
    if (record == null) {
      return const AadhaarVerifyResult(
        success: false,
        message: 'No active Aadhaar OTP. Please request a new one.',
      );
    }
    if (record.isExpired) {
      _pending.remove(digits);
      return const AadhaarVerifyResult(
        success: false,
        message: 'This OTP has expired. Please request a new one.',
      );
    }
    record.attempts++;
    if (record.code != input.trim()) {
      final remaining = maxAttempts - record.attempts;
      if (remaining <= 0) {
        _pending.remove(digits);
        return const AadhaarVerifyResult(
          success: false,
          message: 'Too many wrong attempts. Please request a new OTP.',
        );
      }
      return AadhaarVerifyResult(
        success: false,
        message: 'Incorrect OTP. $remaining attempt(s) remaining.',
      );
    }
    _pending.remove(digits);
    return const AadhaarVerifyResult(
      success: true,
      message: 'Aadhaar verified successfully',
    );
  }

  void clear(String aadhaarNumber) => _pending.remove(normalise(aadhaarNumber));
}
