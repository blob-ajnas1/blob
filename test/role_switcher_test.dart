import 'dart:io';

import 'package:blob/core/rbac/permissions.dart';
import 'package:blob/core/utils/route_planner.dart';
import 'package:blob/data/local_db.dart';
import 'package:blob/data/models/app_user.dart';
import 'package:blob/data/models/enums.dart';
import 'package:blob/data/models/farm.dart';
import 'package:blob/data/models/shop.dart';
import 'package:blob/data/seed.dart';
import 'package:blob/state/marketplace_controller.dart';
import 'package:blob/state/session_controller.dart';
import 'package:blob/ui/dashboards/role_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

AppUser _user({required UserRole role, List<UserRole>? roles}) => AppUser(
  id: 'u1',
  phone: '+919800000000',
  countryCode: '+91',
  name: 'Test User',
  role: role,
  roles: roles,
  district: 'Mandya',
  city: 'Maddur',
  createdAt: DateTime(2025),
);

void main() {
  group('Multi-role accounts', () {
    test('an account always holds its active role', () {
      expect(_user(role: UserRole.landowner).roles, [UserRole.landowner]);
      // Active role missing from the list is put back in front, never lost.
      expect(
        _user(role: UserRole.shopkeeper, roles: [UserRole.landowner]).roles,
        [UserRole.shopkeeper, UserRole.landowner],
      );
    });

    test('roles survive a save/load round trip', () {
      final u = _user(
        role: UserRole.transport,
        roles: [UserRole.landowner, UserRole.transport, UserRole.shopkeeper],
      );
      final back = AppUser.fromMap(u.toMap());
      expect(back.role, UserRole.transport);
      expect(back.roles, u.roles);
    });

    test('accounts saved before multi-role load with their one role', () {
      final legacy = _user(role: UserRole.landowner).toMap()..remove('roles');
      expect(AppUser.fromMap(legacy).roles, [UserRole.landowner]);
    });

    test('the three home roles have labels and emoji', () {
      expect(UserRole.landowner.label, 'Landowner');
      expect(UserRole.transport.label, 'Driver');
      expect(UserRole.shopkeeper.label, 'Shopkeeper');
      for (final r in UserRole.values) {
        expect(r.emoji, isNotEmpty, reason: r.name);
        expect(r.switcherHint, isNotEmpty, reason: r.name);
      }
    });

    test('roles that need a review cannot be self-added', () {
      for (final r in UserRole.values) {
        if (r.requiresApproval) {
          expect(r.selfAssignable, isFalse, reason: r.name);
        }
      }
      expect(UserRole.admin.selfAssignable, isFalse);
      expect(UserRole.student.selfAssignable, isFalse);
    });

    test('shopkeepers can stock up and book delivery', () {
      expect(Rbac.can(UserRole.shopkeeper, Permission.buyProducts), isTrue);
      expect(
        Rbac.can(UserRole.shopkeeper, Permission.bookGoodsVehicle),
        isTrue,
      );
      expect(Rbac.can(UserRole.shopkeeper, Permission.listCrops), isFalse);
    });
  });

  group('Route planner', () {
    test('never delivers a load before picking it up', () {
      // Drop (Maddur) is nearer the start than the pickup (Mysuru); a naive
      // nearest-first would go to Maddur first and deliver nothing.
      final r = RoutePlanner.plan('Mandya', const [
        RouteJob(id: 'a', pickup: 'Mysuru', drop: 'Maddur', who: 'A'),
      ]);
      expect(r.stops.map((s) => s.place), ['Mysuru', 'Maddur']);
      expect(r.totalKm, greaterThan(0));
    });

    test('visits the nearer pickup first', () {
      final r = RoutePlanner.plan('Maddur', const [
        RouteJob(id: 'far', pickup: 'Hassan', drop: 'Mandya', who: 'F'),
        RouteJob(id: 'near', pickup: 'Mandya', drop: 'Mysuru', who: 'N'),
      ]);
      expect(r.stops.first.place, 'Mandya');
      expect(r.stops.length, 4);
    });

    test('unknown places are reported, not silently dropped', () {
      final r = RoutePlanner.plan('Mandya', const [
        RouteJob(id: 'x', pickup: 'Nowhereville', drop: 'Mandya', who: 'X'),
      ]);
      expect(r.isEmpty, isTrue);
      expect(r.unplaced.single.id, 'x');
    });

    test('maps link carries coordinates for every stop', () {
      final r = RoutePlanner.plan('Maddur', const [
        RouteJob(id: 'a', pickup: 'Mandya', drop: 'Mysuru', who: 'A'),
      ]);
      final uri = RoutePlanner.directionsUri(r)!;
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['destination'], contains(','));
      expect(uri.queryParameters['waypoints'], isNotNull);
    });
  });

  group('Plots and stock', () {
    test('a plot reports its stage and harvest countdown', () {
      final now = DateTime(2025, 6, 1);
      final p = FarmPlot(
        id: 'p',
        ownerId: 'u1',
        name: 'Field',
        acres: 2,
        village: 'Maddur',
        district: 'Mandya',
        soil: 'Red loam',
        irrigation: 'Canal',
        crop: 'Paddy',
        sownOn: DateTime(2025, 3, 3),
        cropDays: 120,
        createdAt: now,
      );
      expect(p.isFallow, isFalse);
      expect(p.progressAt(now), closeTo(0.75, 0.01));
      expect(p.daysToHarvest(now), 30);
      expect(p.copyWith(clearCrop: true).isFallow, isTrue);
    });

    test('stock flags out and low correctly', () {
      ShopItem item(double q) => ShopItem(
        id: 'i',
        shopId: 's',
        name: 'Rice',
        unit: 'kg',
        quantity: q,
        reorderLevel: 20,
        pricePaise: 5800,
        supplier: 'X',
        updatedAt: DateTime(2025),
      );
      expect(item(0).isOut, isTrue);
      expect(item(15).isLow, isTrue);
      expect(item(15).isOut, isFalse);
      expect(item(50).isLow, isFalse);
      expect(item(12.5).quantityLabel, '12.5 kg');
      expect(item(40).quantityLabel, '40 kg');
    });

    test('orders move received → packed → delivered, then stop', () {
      expect(ShopOrderStatus.received.next, ShopOrderStatus.packed);
      expect(ShopOrderStatus.packed.next, ShopOrderStatus.delivered);
      expect(ShopOrderStatus.delivered.next, isNull);
    });
  });

  group('Header role switcher (on the seeded demo account)', () {
    late Directory dir;

    setUpAll(() async {
      dir = await Directory.systemTemp.createTemp('blob_roles_');
      await LocalDb.instance.initAt(dir.path);
      await Seed.ensure();
      await LocalDb.instance.setSetting('session_user_id', 'u_landowner_1');
    });

    tearDownAll(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    Future<SessionController> pumpHome(WidgetTester tester) async {
      final session = SessionController()..load();
      // Every test starts on Landowner, whatever the last one switched to.
      // Hive does real file IO, which never completes inside the test's fake
      // clock, so anything that writes runs under runAsync.
      await tester.runAsync(() => session.switchRole(UserRole.landowner));
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: session),
            ChangeNotifierProvider(create: (_) => MarketplaceController()),
          ],
          child: const MaterialApp(home: RoleHome()),
        ),
      );
      await tester.pumpAndSettle();
      return session;
    }

    testWidgets('demo account holds Landowner, Driver and Shopkeeper', (
      tester,
    ) async {
      final session = await pumpHome(tester);
      expect(session.user!.roles, [
        UserRole.landowner,
        UserRole.transport,
        UserRole.shopkeeper,
      ]);
    });

    testWidgets('header shows the active role and opens the list', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.text('Active role'), findsOneWidget);
      expect(find.byKey(const Key('dashboard-landowner')), findsOneWidget);

      await tester.tap(find.byKey(const Key('active-role-button')));
      await tester.pumpAndSettle();
      expect(find.text('Switch role'), findsOneWidget);
      for (final r in ['landowner', 'transport', 'shopkeeper']) {
        expect(find.byKey(Key('role-tile-$r')), findsOneWidget);
      }
    });

    testWidgets('picking Driver swaps the dashboard in place', (tester) async {
      final session = await pumpHome(tester);
      await tester.tap(find.byKey(const Key('active-role-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('role-tile-transport')));
      await tester.pumpAndSettle();
      // Let the background save finish so the next test starts clean.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );

      expect(session.user!.role, UserRole.transport);
      expect(find.byKey(const Key('dashboard-driver')), findsOneWidget);
      expect(find.byKey(const Key('dashboard-landowner')), findsNothing);
      expect(find.text('Active Haul'), findsOneWidget);
      expect(find.text('Trip Earnings'), findsOneWidget);
      // The sheet closed and we never left the home page.
      expect(find.text('Switch role'), findsNothing);
      expect(find.byType(RoleHome), findsOneWidget);
    });

    testWidgets('picking Shopkeeper shows shop sections', (tester) async {
      final session = await pumpHome(tester);
      await tester.runAsync(() => session.switchRole(UserRole.shopkeeper));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dashboard-shopkeeper')), findsOneWidget);
      expect(find.textContaining('Customer Orders'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Payment Records'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Payment Records'), findsOneWidget);
    });

    testWidgets('landowner sections are all present', (tester) async {
      await pumpHome(tester);
      expect(find.text('My Land'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Trucks & Drivers'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Crop Calendar'), findsOneWidget);
      expect(find.textContaining('Labour Available'), findsOneWidget);
      expect(find.text('Trucks & Drivers'), findsOneWidget);
    });

    testWidgets('a role the account lacks cannot be switched to', (
      tester,
    ) async {
      final session = await pumpHome(tester);
      await tester.runAsync(() => session.switchRole(UserRole.admin));
      expect(session.user!.role, UserRole.landowner);
    });
  });
}
