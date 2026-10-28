import 'dart:io';

import 'package:blob/data/local_db.dart';
import 'package:blob/data/models/app_user.dart';
import 'package:blob/data/models/enums.dart';
import 'package:blob/services/supabase_service.dart';
import 'package:blob/state/marketplace_controller.dart';
import 'package:blob/state/session_controller.dart';
import 'package:blob/ui/dashboards/role_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

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
    await pumpHome(tester, UserRole.admin, service);
    expect(find.byKey(const Key('cloud-connection-card')), findsOneWidget);
    expect(find.text('Cloud connection'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(reads, 1);

    final retry = find.text('Check again');
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(find.text("Can't reach cloud"), findsOneWidget);
    expect(find.textContaining('private-exception-content'), findsNothing);
  });

  testWidgets('an unconfigured admin can retry without making a request', (tester) async {
    var reads = 0;
    final service = SupabaseService.forTesting(
      url: '',
      publishableKey: 'configured',
      pingReader: () async {
        reads++;
        return {'message': 'ok'};
      },
    );
    await pumpHome(tester, UserRole.admin, service);
    expect(find.text('Not configured'), findsOneWidget);
    await tester.ensureVisible(find.text('Check again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(find.text('Not configured'), findsOneWidget);
    expect(reads, 0);
  });

  for (final role in [UserRole.landowner, UserRole.buyer, UserRole.student]) {
    testWidgets('${role.name} does not see or trigger the admin cloud card', (tester) async {
      var reads = 0;
      final service = SupabaseService.forTesting(
        url: 'configured',
        publishableKey: 'configured',
        pingReader: () async {
          reads++;
          return {'message': 'ok'};
        },
      );
      await pumpHome(tester, role, service);
      expect(find.byKey(const Key('cloud-connection-card')), findsNothing);
      expect(find.text('Cloud connection'), findsNothing);
      expect(reads, 0);
    });
  }
}
