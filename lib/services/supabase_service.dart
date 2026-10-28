import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads only the public connection-test row. Tests can supply an in-memory
/// reader instead of creating a Supabase client or contacting a network.
typedef PingReader = Future<Map<String, dynamic>?> Function();

enum CloudStatusKind { notConfigured, connected, unreachable }

class CloudStatus {
  const CloudStatus.notConfigured()
    : kind = CloudStatusKind.notConfigured,
      message = null;

  const CloudStatus.connected() : kind = CloudStatusKind.connected, message = null;

  const CloudStatus.unreachable(String reason)
    : kind = CloudStatusKind.unreachable,
      message = reason;

  final CloudStatusKind kind;

  /// A generic, safe description, never an exception or server response.
  final String? message;
}

/// Optional cloud connectivity. Hive remains the source of all app data.
class SupabaseService {
  SupabaseService._({
    required String url,
    required String publishableKey,
    PingReader? pingReader,
    Duration checkTimeout = const Duration(seconds: 8),
  }) : _url = url,
       _publishableKey = publishableKey,
       _pingReader = pingReader,
       _checkTimeout = checkTimeout;

  /// Production configuration comes exclusively from compile-time defines.
  factory SupabaseService.fromEnvironment() => SupabaseService._(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  /// Supplies dummy configuration and an in-memory reader for offline tests.
  @visibleForTesting
  factory SupabaseService.forTesting({
    required String url,
    required String publishableKey,
    PingReader? pingReader,
    Duration checkTimeout = const Duration(seconds: 8),
  }) => SupabaseService._(
    url: url,
    publishableKey: publishableKey,
    pingReader: pingReader,
    checkTimeout: checkTimeout,
  );

  static final SupabaseService instance = SupabaseService.fromEnvironment();

  final String _url;
  final String _publishableKey;
  final PingReader? _pingReader;
  final Duration _checkTimeout;
  Future<void>? _initialization;
  bool _initialized = false;

  bool get isConfigured =>
      _url.trim().isNotEmpty && _publishableKey.trim().isNotEmpty;

  /// Best-effort initialization. A timeout does not cancel the SDK's future;
  /// retaining it prevents overlapping initializations and allows a late
  /// completion to be used by a subsequent check.
  Future<void> init() async {
    if (!isConfigured || _pingReader != null || _initialized) return;
    final pending = _initialization ??= _initialize();
    try {
      await pending.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      debugPrint('Cloud initialization timed out; the app remains offline.');
    }
  }

  Future<void> _initialize() async {
    try {
      await Supabase.initialize(
        url: _url,
        publishableKey: _publishableKey,
        // A null access token uses the public key for the anonymous read and
        // skips Supabase session recovery, deep links and authentication.
        accessToken: () async => null,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false,
          detectSessionInUri: false,
        ),
        // SDK debug logs can contain request or error details; keep them off.
        debug: false,
      );
      _initialized = true;
    } catch (_) {
      _initialization = null;
      debugPrint('Cloud initialization failed; the app remains offline.');
    }
  }

  /// Checks only `app_ping` id 1 and does not expose backend error text.
  Future<CloudStatus> checkConnection() async {
    if (!isConfigured) return const CloudStatus.notConfigured();

    try {
      final row = await _readPing().timeout(_checkTimeout);
      if (row == null || row['message'] is! String) {
        return const CloudStatus.unreachable('The connection test row is missing.');
      }
      return const CloudStatus.connected();
    } on TimeoutException {
      return const CloudStatus.unreachable('The connection check timed out.');
    } catch (_) {
      // Do not return exception text: an SDK or proxy error can contain keys.
      return const CloudStatus.unreachable('The cloud connection is unavailable.');
    }
  }

  Future<Map<String, dynamic>?> _readPing() async {
    final reader = _pingReader;
    if (reader != null) return reader();

    await init();
    if (!_initialized) throw StateError('Cloud initialization unavailable.');
    return Supabase.instance.client
        .from('app_ping')
        .select('message')
        .eq('id', 1)
        .maybeSingle();
  }
}
