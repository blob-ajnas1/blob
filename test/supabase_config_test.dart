import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Supabase build config uses the public project key', () {
    final Object? config;
    try {
      config = jsonDecode(File('config/supabase.json').readAsStringSync());
    } on FileSystemException {
      throw StateError('Unable to read Supabase build config.');
    } on FormatException {
      throw StateError('Invalid Supabase build config JSON.');
    }

    expect(config is Map<String, dynamic>, isTrue);
    if (config is! Map<String, dynamic>) return;

    expect(
      config['SUPABASE_URL'] ==
          'https://qovhrovbewvpkhcebtko.supabase.co',
      isTrue,
    );

    final key = config['SUPABASE_PUBLISHABLE_KEY'];
    expect(key is String, isTrue);
    if (key is! String) return;

    expect(key.startsWith('sb_publishable_'), isTrue);
    expect(key.startsWith('sb_secret_'), isFalse);
    expect(key.startsWith('eyJ'), isFalse);
  });
}
