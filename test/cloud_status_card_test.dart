import 'dart:io';

import 'package:blob/data/local_db.dart';
import 'package:blob/data/models/app_user.dart';
import 'package:blob/data/models/enums.dart';
import 'package:blob/services/supabase_service.dart';
import 'package:blob/state/marketplace_controller.dart';
import 'package:blob/state/session_controller.dart';
import 'package:blob/ui/dashboards/role_home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

// Temporary CI diagnostics report a known phase and error category only.
// Never forward arbitrary exception text or credentials to annotations.
Future<void> diagnoseWidget(
  String name,
  WidgetTester tester,
  Future<void> Function(void Function(String)) body,
) async {
  var phase = 'before test';
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString().toLowerCase();
    final category = text.contains('overflowed')
        ? 'layout overflow'
        : text.contains('unable to load asset')
        ? 'asset load'
        : text.contains('multiple exceptions')
        ? 'multiple exceptions'
        : 'other framework error';
    final chain = <String>[];
    final information = details.informationCollector?.call();
    if (information != null) {
      for (final node in information.whereType<DiagnosticsDebugCreator>()) {
        final creator = node.value;
        if (creator is DebugCreator) {
          chain.add(creator.element.widget.runtimeType.toString());
          creator.element.visitAncestorElements((element) {
            chain.add(element.widget.runtimeType.toString());
            return chain.length < 18;
          });
        }
      }
    }
    final overflow = RegExp(r'overflowed by ([0-9.]+) pixels on the ([a-z]+)')
        .firstMatch(text);
    final size = overflow == null ? '' : ' ${overflow[1]}px ${overflow[2]}';
    debugPrintSynchronously(
      '::error title=Cloud widget test::$name: $phase ($category$size) ${chain.join(" > ")}',
      wrapWidth: 10000,
    );
    previous?.call(details);
  };
  try {
    await body((value) => phase = value);
    final exception = tester.takeException();
    if (exception != null) throw exception;
  } catch (error) {
    debugPrintSynchronously('::error title=Cloud widget test::$name: $phase (${error.runtimeType})');
    rethrow;
  } finally {
    FlutterError.onError = previous;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('blob_cloud_card_');
    await LocalDb.instance.initAt(directory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> pumpHome(
    WidgetTester tester,
    UserRole role,
    SupabaseService service,
  ) async {
    final user = AppUser(
      id: 'test_${role.name}',
      phone: '+910000000000',
      countryCode: '+91',
      name: 'Test User',
      role: role,
      district: 'Mandya',
      createdAt: DateTime(2025),
    );
    final session = SessionController()..load();
    await tester.runAsync(() async {
      await LocalDb.instance.put(LocalDb.users, user.id, user.toMap());
      await session.switchTo(user);
    });
    addTearDown(session.dispose);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider(create: (_) => MarketplaceController()),
        ],
        child: MaterialApp(home: RoleHome(cloudService: service)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('admin can see the connection status and check again', (tester) async {
    await diagnoseWidget('admin connected/retry', tester, (stage) async {
      var reads = 0;
      final service = SupabaseService.forTesting(
        url: 'configured',
        publishableKey: 'configured',
        pingReader: () async {
          reads++;
          if (reads == 1) return {'message': 'ok'};
          throw StateError('private-exception-content');
        },
      );
      stage('pump admin home');
      await pumpHome(tester, UserRole.admin, service);
      stage('check card');
      expect(find.byKey(const Key('cloud-connection-card')), findsOneWidget);
      stage('check title');
      expect(find.text('Cloud connection'), findsOneWidget);
      stage('check connected');
      expect(find.text('Connected'), findsOneWidget);
      stage('check first read count');
      expect(reads, 1);

      final retry = find.text('Check again');
      stage('make retry visible');
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      stage('tap retry');
      await tester.tap(retry);
      await tester.pumpAndSettle();
      stage('check second read count');
      expect(reads, 2);
      stage('check unreachable status');
      expect(find.text("Can't reach cloud"), findsOneWidget);
      stage('check no exception text');
      expect(find.textContaining('private-exception-content'), findsNothing);
    });
  });

  testWidgets('an unconfigured admin can retry without making a request', (tester) async {
    await diagnoseWidget('admin unconfigured/retry', tester, (stage) async {
      var reads = 0;
      final service = SupabaseService.forTesting(
        url: '',
        publishableKey: 'configured',
        pingReader: () async {
          reads++;
          return {'message': 'ok'};
        },
      );
      stage('pump admin home');
      await pumpHome(tester, UserRole.admin, service);
      stage('check unconfigured status');
      expect(find.text('Not configured'), findsOneWidget);
      stage('make retry visible');
      await tester.ensureVisible(find.text('Check again'));
      await tester.pumpAndSettle();
      stage('tap retry');
      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();
      stage('check unconfigured after retry');
      expect(find.text('Not configured'), findsOneWidget);
      stage('check no reads');
      expect(reads, 0);
    });
  });

  for (final role in [UserRole.landowner, UserRole.buyer, UserRole.student]) {
    testWidgets('${role.name} does not see or trigger the admin cloud card', (tester) async {
      await diagnoseWidget('${role.name} non-admin', tester, (stage) async {
        var reads = 0;
        final service = SupabaseService.forTesting(
          url: 'configured',
          publishableKey: 'configured',
          pingReader: () async {
            reads++;
            return {'message': 'ok'};
          },
        );
        stage('pump non-admin home');
        await pumpHome(tester, role, service);
        stage('check card absent');
        expect(find.byKey(const Key('cloud-connection-card')), findsNothing);
        stage('check title absent');
        expect(find.text('Cloud connection'), findsNothing);
        stage('check no reads');
        expect(reads, 0);
      });
    });
  }
}
