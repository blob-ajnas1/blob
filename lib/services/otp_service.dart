import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of an OTP send attempt.
class OtpSendResult {
  final bool success;
  final String message;
  final Duration? retryAfter;
  final String? devCode; // exposed only in dev provider

  const OtpSendResult({
    required this.success,
    required this.message,
    this.retryAfter,
    this.devCode,
  });
}

class OtpVerifyResult {
  final bool success;
  final String message;
  final int attemptsRemaining;

  const OtpVerifyResult({
    required this.success,
    required this.message,
    this.attemptsRemaining = 0,
  });
}

/// Pluggable OTP transport.
///
/// [DevOtpProvider] is used until Firebase config files are uploaded.
/// Swapping in Firebase Phone Auth later means implementing this interface
/// only — no screen or controller changes required.
abstract class OtpProvider {
  Future<OtpSendResult> send(String phoneE164, String code);
}

/// Development provider: prints the OTP instead of sending an SMS.
class DevOtpProvider implements OtpProvider {
  @override
  Future<OtpSendResult> send(String phoneE164, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (kDebugMode) {
      debugPrint('[BLOB DEV OTP] $phoneE164 -> $code');
    }
    return OtpSendResult(
      success: true,
      message: 'Verification code sent to $phoneE164',
      devCode: code,
    );
  }
}

/// Sends the OTP as a real SMS through an HTTP SMS gateway.
///
/// Works with any gateway that accepts a POST with `to` / `message` fields —
/// Twilio, MSG91, Fast2SMS, Gupshup, Kaleyra etc. Supply the endpoint, the
/// auth header and (for DLT-regulated Indian routes) the template/sender id.
///
/// Credentials are injected at build time so nothing secret is committed:
///   flutter build apk --release \
///     --dart-define=SMS_ENDPOINT=https://api.msg91.com/api/v5/flow/ \
///     --dart-define=SMS_AUTH_KEY=xxxxx \
///     --dart-define=SMS_SENDER_ID=BLOBAG
class SmsGatewayOtpProvider implements OtpProvider {
  SmsGatewayOtpProvider({
    this.endpoint = const String.fromEnvironment('SMS_ENDPOINT'),
    this.authKey = const String.fromEnvironment('SMS_AUTH_KEY'),
    this.senderId = const String.fromEnvironment('SMS_SENDER_ID'),
    this.templateId = const String.fromEnvironment('SMS_TEMPLATE_ID'),
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String endpoint;
  final String authKey;
  final String senderId;
  final String templateId;
  final http.Client _client;

  /// True when build-time credentials are present.
  bool get isConfigured => endpoint.isNotEmpty && authKey.isNotEmpty;

  String messageFor(String code) =>
      '$code is your BLOB verification code. Valid for 10 minutes. '
      'Do not share it with anyone.';

  @override
  Future<OtpSendResult> send(String phoneE164, String code) async {
    try {
      final response = await _client
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'authkey': authKey,
              'Authorization': 'Bearer $authKey',
            },
            body: jsonEncode({
              'to': phoneE164,
              'sender': senderId,
              'template_id': templateId,
              'message': messageFor(code),
              'otp': code,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return OtpSendResult(
          success: true,
          message: 'Verification code sent by SMS to $phoneE164',
        );
      }
      return const OtpSendResult(
        success: false,
        message: 'Could not send the SMS. Please try again in a moment.',
      );
    } catch (_) {
      return const OtpSendResult(
        success: false,
        message: 'Network problem while sending the SMS. Check your '
            'connection and try again.',
      );
    }
  }
}

class _OtpRecord {
  final String code;
  final DateTime expiresAt;
  int attempts = 0;

  _OtpRecord({required this.code, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Handles OTP lifecycle: generation, expiry, rate limiting, lockout.
class OtpService {
  OtpService({OtpProvider? provider})
      : _provider = provider ?? _defaultProvider();

  /// Uses the real SMS gateway when build-time credentials were supplied,
  /// otherwise falls back to the dev provider so the app stays testable.
  static OtpProvider _defaultProvider() {
    final gateway = SmsGatewayOtpProvider();
    if (gateway.isConfigured) return gateway;
    return DevOtpProvider();
  }

  final OtpProvider _provider;

  /// True when OTPs are delivered as real SMS rather than shown on screen.
  bool get usesRealSms => _provider is SmsGatewayOtpProvider;
  final Random _random = Random.secure();

  final Map<String, _OtpRecord> _active = {};
  final Map<String, List<DateTime>> _sendHistory = {};
  final Map<String, DateTime> _lockouts = {};

  /// OTP validity window.
  static const Duration validity = Duration(minutes: 10);

  /// Minimum gap between two OTP requests for the same number.
  static const Duration resendCooldown = Duration(seconds: 45);

  /// Max sends allowed inside [rateWindow].
  static const int maxSendsPerWindow = 5;
  static const Duration rateWindow = Duration(minutes: 15);

  /// Wrong-code attempts before the number is locked.
  static const int maxVerifyAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  String _generate() => (_random.nextInt(900000) + 100000).toString();

  Duration? lockoutRemaining(String phone) {
    final until = _lockouts[phone];
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    if (remaining.isNegative) {
      _lockouts.remove(phone);
      return null;
    }
    return remaining;
  }

  Duration? cooldownRemaining(String phone) {
    final history = _sendHistory[phone];
    if (history == null || history.isEmpty) return null;
    final elapsed = DateTime.now().difference(history.last);
    if (elapsed >= resendCooldown) return null;
    return resendCooldown - elapsed;
  }

  Future<OtpSendResult> requestOtp(String phoneE164) async {
    final lock = lockoutRemaining(phoneE164);
    if (lock != null) {
      return OtpSendResult(
        success: false,
        message:
            'Too many failed attempts. Try again in ${lock.inMinutes + 1} minute(s).',
        retryAfter: lock,
      );
    }

    final cooldown = cooldownRemaining(phoneE164);
    if (cooldown != null) {
      return OtpSendResult(
        success: false,
        message: 'Please wait ${cooldown.inSeconds}s before requesting again.',
        retryAfter: cooldown,
      );
    }

    final history = _sendHistory.putIfAbsent(phoneE164, () => []);
    history.removeWhere(
      (t) => DateTime.now().difference(t) > rateWindow,
    );
    if (history.length >= maxSendsPerWindow) {
      _lockouts[phoneE164] = DateTime.now().add(lockoutDuration);
      return const OtpSendResult(
        success: false,
        message: 'Request limit reached. Please try again after 15 minutes.',
      );
    }

    final code = _generate();
    _active[phoneE164] = _OtpRecord(
      code: code,
      expiresAt: DateTime.now().add(validity),
    );
    history.add(DateTime.now());

    return _provider.send(phoneE164, code);
  }

  OtpVerifyResult verify(String phoneE164, String input) {
    final lock = lockoutRemaining(phoneE164);
    if (lock != null) {
      return OtpVerifyResult(
        success: false,
        message:
            'Number locked. Try again in ${lock.inMinutes + 1} minute(s).',
      );
    }

    final record = _active[phoneE164];
    if (record == null) {
      return const OtpVerifyResult(
        success: false,
        message: 'No active code. Please request a new one.',
      );
    }
    if (record.isExpired) {
      _active.remove(phoneE164);
      return const OtpVerifyResult(
        success: false,
        message: 'This code has expired. Please request a new one.',
      );
    }

    record.attempts++;
    if (record.code != input.trim()) {
      final remaining = maxVerifyAttempts - record.attempts;
      if (remaining <= 0) {
        _active.remove(phoneE164);
        _lockouts[phoneE164] = DateTime.now().add(lockoutDuration);
        return const OtpVerifyResult(
          success: false,
          message: 'Too many wrong attempts. Number locked for 15 minutes.',
        );
      }
      return OtpVerifyResult(
        success: false,
        message: 'Incorrect code. $remaining attempt(s) remaining.',
        attemptsRemaining: remaining,
      );
    }

    _active.remove(phoneE164);
    _sendHistory.remove(phoneE164);
    return const OtpVerifyResult(success: true, message: 'Phone verified');
  }

  void clear(String phone) {
    _active.remove(phone);
    _sendHistory.remove(phone);
    _lockouts.remove(phone);
  }
}
