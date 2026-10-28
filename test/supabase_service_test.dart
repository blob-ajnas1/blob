import 'dart:async';

import 'package:blob/core/i18n/strings.dart';
import 'package:blob/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Optional Supabase connection', () {
    test('both non-empty settings are required and no reader runs without them', () async {
      var reads = 0;
      for (final (url, key) in [('', ''), ('configured', ''), ('', 'configured'), (' ', 'configured')]) {
        final service = SupabaseService.forTesting(
          url: url,
          publishableKey: key,
          pingReader: () async {
            reads++;
            return {'message': 'ok'};
          },
        );
        expect(service.isConfigured, isFalse);
        await service.init();
        expect((await service.checkConnection()).kind, CloudStatusKind.notConfigured);
      }
      expect(reads, 0);
    });

    test('a returned ping row reports connected', () async {
      var reads = 0;
      final service = SupabaseService.forTesting(
        url: 'configured',
        publishableKey: 'configured',
        pingReader: () async {
          reads++;
          return {'message': 'ok'};
        },
      );
      expect(service.isConfigured, isTrue);
      await service.init();
      final status = await service.checkConnection();
      expect(status.kind, CloudStatusKind.connected);
      expect(status.message, isNull);
      expect(reads, 1);
    });

    test('a missing or malformed ping row is not a successful connection', () async {
      for (final row in <Map<String, dynamic>?>[null, {}, {'message': null}]) {
        final service = SupabaseService.forTesting(
          url: 'configured',
          publishableKey: 'configured',
          pingReader: () async => row,
        );
        final status = await service.checkConnection();
        expect(status.kind, CloudStatusKind.unreachable);
        expect(status.message, isNotEmpty);
      }
    });

    test('reader exceptions are reported without their potentially sensitive text', () async {
      const sensitiveText = 'private-exception-content';
      final service = SupabaseService.forTesting(
        url: 'configured',
        publishableKey: 'configured',
        pingReader: () async => throw StateError(sensitiveText),
      );
      final status = await service.checkConnection();
      expect(status.kind, CloudStatusKind.unreachable);
      expect(status.message, isNotEmpty);
      expect(status.message, isNot(contains(sensitiveText)));
    });

    test('a reader which never completes times out without throwing', () async {
      final pending = Completer<Map<String, dynamic>?>();
      final service = SupabaseService.forTesting(
        url: 'configured',
        publishableKey: 'configured',
        pingReader: () => pending.future,
        checkTimeout: const Duration(milliseconds: 10),
      );
      final status = await service.checkConnection();
      expect(status.kind, CloudStatusKind.unreachable);
      expect(status.message, contains('timed out'));
      pending.complete(null);
    });
  });

  test('cloud labels have translated values and English fallback', () {
    expect(S.t(AppLanguage.english, 'cloud_connection'), 'Cloud connection');
    expect(S.t(AppLanguage.kannada, 'cloud_connection'), 'ಕ್ಲೌಡ್ ಸಂಪರ್ಕ');
    expect(S.t(AppLanguage.hindi, 'cloud_check_again'), 'फिर से जाँचें');
    expect(S.t(AppLanguage.assamese, 'cloud_connection'), 'Cloud connection');
  });
}
