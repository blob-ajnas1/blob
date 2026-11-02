import 'dart:io';

import 'package:blob/core/i18n/strings.dart';
import 'package:blob/core/rbac/permissions.dart';
import 'package:blob/core/theme/app_colors.dart';
import 'package:blob/core/theme/app_theme.dart';
import 'package:blob/data/local_db.dart';
import 'package:blob/data/models/app_user.dart';
import 'package:blob/data/models/enums.dart';
import 'package:blob/data/models/learning.dart';
import 'package:blob/data/models/ledger.dart';
import 'package:blob/data/models/listing.dart';
import 'package:blob/state/learning_controller.dart';
import 'package:blob/state/marketplace_controller.dart';
import 'package:blob/state/session_controller.dart';
import 'package:blob/ui/auth/category_screen.dart';
import 'package:blob/ui/auth/role_selection_screen.dart';
import 'package:blob/ui/auth/student_details_screen.dart';
import 'package:blob/ui/dashboards/dashboard_parts.dart';
import 'package:blob/ui/dashboards/role_home.dart';
import 'package:blob/ui/edu/edu_home_screen.dart';
import 'package:blob/ui/edu/edu_shell.dart';
import 'package:blob/ui/jobs/post_job_screen.dart';
import 'package:blob/ui/learning/games_task_screen.dart';
import 'package:blob/ui/learning/quiz_task_screen.dart';
import 'package:blob/ui/learning/video_task_screen.dart';
import 'package:blob/ui/market/create_listing_screen.dart';
import 'package:blob/ui/market/listing_detail_screen.dart';
import 'package:blob/ui/market/market_screen.dart';
import 'package:blob/ui/shell/app_shell.dart';
import 'package:blob/ui/shell/track_router.dart';
import 'package:blob/ui/transport/transport_booking_screen.dart';
import 'package:blob/ui/widgets/floating_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class _Fixture {
  const _Fixture({required this.session, required this.student});

  final SessionController session;
  final AppUser student;
}

Future<_Fixture> _fixture(
  WidgetTester tester, {
  bool student = false,
  AppLanguage language = AppLanguage.english,
}) async {
  final now = DateTime.now();
  final buyer = AppUser(
    id: 'buyer-test',
    phone: '+919000000001',
    countryCode: '+91',
    name: 'Asha Buyer',
    role: UserRole.buyer,
    roles: [UserRole.buyer, UserRole.transport],
    district: 'Mandya',
    city: 'Maddur',
    category: UserCategory.jobSeeker,
    createdAt: now,
  );
  final learner = AppUser(
    id: 'student-test',
    phone: '+919000000002',
    countryCode: '+91',
    name: 'Meera Student',
    role: UserRole.student,
    district: 'Mandya',
    category: UserCategory.student,
    createdAt: now,
  );
  final listing = Listing(
    id: 'ragi-test',
    ownerId: 'farmer-test',
    ownerName: 'Leela Farmer',
    ownerRole: UserRole.landowner,
    cropName: 'Ragi',
    description: 'Fresh ragi',
    quantityQuintal: 12,
    pricePerQuintalPaise: 320000,
    district: 'Mandya',
    channel: ListingChannel.toBuyers,
    imageAsset: 'assets/crops/ragi.jpg',
    createdAt: now,
  );
  LedgerEntry entry(String id, int amount, PaymentStatus status) => LedgerEntry(
    id: id,
    payerId: buyer.id,
    payerName: buyer.name,
    payeeId: listing.ownerId,
    payeeName: listing.ownerName,
    amountPaise: amount,
    type: LedgerType.productPurchase,
    status: status,
    reference: listing.id,
    note: '',
    createdAt: now,
  );
  final profile = StudentProfile(
    userId: learner.id,
    tenthMarksCardNumber: '',
    currentClass: 'Class 10',
    collegeName: 'Example school',
    goals: '',
    updatedAt: now,
  );
  final learnerProgress = DailyProgress(
    userId: learner.id,
    dayKey: DailyProgress.dayKeyOf(now),
    videoMinutes: 5,
    gamesPlayed: 1,
  );
  final buyerProgress = DailyProgress(
    userId: buyer.id,
    dayKey: DailyProgress.dayKeyOf(now),
  );

  // All Hive setup and writes use the real clock; fakeAsync cannot complete
  // Hive's file IO. Every widget test gets its own isolated temporary boxes.
  final directory = await tester.runAsync(() async {
    final dir = await Directory.systemTemp.createTemp('blob_restyle_');
    final db = LocalDb.instance;
    await db.initAt(dir.path);
    await db.put(LocalDb.users, buyer.id, buyer.toMap());
    await db.put(LocalDb.users, learner.id, learner.toMap());
    await db.put(LocalDb.listings, listing.id, listing.toMap());
    for (final record in [
      entry('paid-test', 125000, PaymentStatus.cleared),
      entry('pending-test', 97500, PaymentStatus.pending),
    ]) {
      await db.put(LocalDb.ledger, record.id, record.toMap());
    }
    await db.put(LocalDb.studentProfiles, learner.id, profile.toMap());
    await db.put(
      LocalDb.dailyProgress,
      '${learnerProgress.userId}_${learnerProgress.dayKey}',
      learnerProgress.toMap(),
    );
    await db.put(
      LocalDb.dailyProgress,
      '${buyerProgress.userId}_${buyerProgress.dayKey}',
      buyerProgress.toMap(),
    );
    await db.setSetting('session_user_id', student ? learner.id : buyer.id);
    await db.setSetting('language_code', language.code);
    return dir;
  });
  if (directory == null) throw StateError('Could not create the test database');
  addTearDown(() async {
    await tester.runAsync(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
  });

  return _Fixture(session: SessionController()..load(), student: learner);
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _Fixture fixture,
  Widget screen, {
  required double width,
  double textScale = 1.3,
  bool education = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 760);
  addTearDown(tester.view.reset);
  AppColors.applyPalette(education ? const EduPalette() : const AgriPalette());
  addTearDown(() => AppColors.applyPalette(const AgriPalette()));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: fixture.session),
        ChangeNotifierProvider(create: (_) => MarketplaceController()),
        ChangeNotifierProvider(create: (_) => LearningController()),
      ],
      child: MaterialApp(
        theme: education ? AppTheme.edu : AppTheme.agri,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Directionality(
            textDirection: fixture.session.language.isRtl
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child!,
          ),
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Finder _scrollableWithin(Finder screen) => find
    .descendant(of: screen, matching: find.byType(Scrollable))
    .first;

Future<void> _show(
  WidgetTester tester,
  Finder target,
  Finder scrollable,
) async {
  await tester.scrollUntilVisible(target, 180, scrollable: scrollable);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('About you fits ${width.toInt()}dp at 1.3 text scale', (
      tester,
    ) async {
      final fixture = await _fixture(tester);
      await _pumpScreen(tester, fixture, const CategoryScreen(), width: width);
      expect(find.text('Which best describes you?'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      await _show(
        tester,
        find.text('Job Seeker'),
        _scrollableWithin(find.byType(CategoryScreen)),
      );
      await tester.tap(find.text('Job Seeker'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Account types fit ${width.toInt()}dp at 1.3 text scale', (
      tester,
    ) async {
      final fixture = await _fixture(tester);
      await _pumpScreen(
        tester,
        fixture,
        const RoleSelectionScreen(category: UserCategory.jobSeeker),
        width: width,
      );
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNull);
      final scrollable = _scrollableWithin(find.byType(RoleSelectionScreen));
      for (final meta in kRoleMeta) {
        final card = find.byKey(ValueKey('role-choice-${meta.role.name}'));
        await _show(tester, card, scrollable);
        expect(card, findsOneWidget);
        if (meta.role == UserRole.broker) {
          expect(
            find.descendant(of: card, matching: find.text('Approval needed')),
            findsOneWidget,
          );
          expect(find.text('Verified'), findsNothing);
        }
        if (meta.role == UserRole.transport) {
          expect(
            find.descendant(of: card, matching: find.text('Driver')),
            findsOneWidget,
          );
          await tester.tap(card);
          await tester.pumpAndSettle();
        }
      }
      expect(kRoleMeta.length, 11);
      expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Buyer home fits ${width.toInt()}dp at 1.3 text scale', (
      tester,
    ) async {
      final fixture = await _fixture(tester);
      await _pumpScreen(tester, fixture, const RoleHome(), width: width);
      expect(find.text('Namaste, Asha'), findsOneWidget);
      expect(find.byKey(const Key('active-role-button')), findsOneWidget);
      expect(find.text('₹1,250'), findsOneWidget);
      expect(find.text('₹975'), findsOneWidget);
      for (final label in [
        'Buy Crops',
        'Sell to Exporters',
        'Hire Labour',
        'Transport',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      final scrollable = _scrollableWithin(find.byType(RoleHome));
      final listing = find.byKey(const Key('buyer-listing-ragi-test'));
      await _show(tester, listing, scrollable);
      expect(find.descendant(of: listing, matching: find.text('Ragi')), findsOneWidget);
      expect(
        find.descendant(of: listing, matching: find.textContaining('12 quintal')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: listing, matching: find.textContaining('₹3,200')),
        findsOneWidget,
      );
      final thumb = tester.widget<CropThumb>(
        find.descendant(of: listing, matching: find.byType(CropThumb)),
      );
      expect(thumb.imageAsset, 'assets/crops/ragi.jpg');
      await _show(tester, find.text('Vehicle Rental'), scrollable);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Student home fits ${width.toInt()}dp at 1.3 text scale', (
      tester,
    ) async {
      final fixture = await _fixture(tester, student: true);
      await _pumpScreen(
        tester,
        fixture,
        const EduHomeScreen(),
        width: width,
        education: true,
      );
      expect(find.text('Hi, Meera'), findsOneWidget);
      expect(find.textContaining('Class 10'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Active learners today'), findsOneWidget);
      expect(find.text('Total learners using the app'), findsOneWidget);
      // Both existing counters include the student and job-seeker records.
      expect(find.text('2').evaluate().length, greaterThanOrEqualTo(2));
      expect(find.byIcon(Icons.notifications_none), findsNothing);
      expect(find.text('View all'), findsNothing);
      final scrollable = _scrollableWithin(find.byType(EduHomeScreen));
      for (final type in DailyTaskType.values) {
        await _show(
          tester,
          find.byKey(ValueKey('student-task-${type.name}')),
          scrollable,
        );
        if (type == DailyTaskType.video) {
          expect(find.text('5/15 min'), findsOneWidget);
        }
        if (type == DailyTaskType.games) {
          expect(find.text('1/3 rounds'), findsOneWidget);
        }
      }
      await _show(tester, find.text('Last 7 days'), scrollable);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Floating tabs fit ${width.toInt()}dp at 1.3 text scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 760);
      addTearDown(tester.view.reset);
      AppColors.applyPalette(const AgriPalette());
      var tapped = -1;
      const items = [
        FloatingNavItem(
          id: 'home',
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        FloatingNavItem(
          id: 'market',
          label: 'Market',
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront,
        ),
        FloatingNavItem(
          id: 'jobs',
          label: 'Jobs',
          icon: Icons.work_outline,
          activeIcon: Icons.work,
        ),
        FloatingNavItem(
          id: 'payments',
          label: 'Payments',
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet,
        ),
        FloatingNavItem(
          id: 'profile',
          label: 'Profile',
          icon: Icons.person_outline,
          activeIcon: Icons.person,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              items: items,
              selectedIndex: 0,
              onTap: (index) => tapped = index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('floating-nav-profile')));
      expect(tapped, 4);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Category choices retain the existing routes and prompt', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    await _pumpScreen(
      tester,
      fixture,
      const CategoryScreen(),
      width: 500,
      textScale: 1,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pump();
    expect(find.text('Please choose one option to continue'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(CategoryScreen)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Student'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentDetailsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _show(
      tester,
      find.text('Job Seeker'),
      _scrollableWithin(find.byType(CategoryScreen)),
    );
    await tester.tap(find.text('Job Seeker'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    final screen = tester.widget<RoleSelectionScreen>(
      find.byType(RoleSelectionScreen),
    );
    expect(screen.category, UserCategory.jobSeeker);
  });

  testWidgets('Driver continues to the existing profile/subtype flow', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    await _pumpScreen(
      tester,
      fixture,
      const RoleSelectionScreen(category: UserCategory.jobSeeker),
      width: 500,
      textScale: 1,
    );
    final driver = find.byKey(const Key('role-choice-transport'));
    await _show(tester, driver, _scrollableWithin(find.byType(RoleSelectionScreen)));
    await tester.tap(driver);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    final profile = tester.widget<ProfileSetupScreen>(
      find.byType(ProfileSetupScreen),
    );
    expect(profile.role, UserRole.transport);
    expect(profile.category, UserCategory.jobSeeker);
  });

  testWidgets('Buyer actions and farmer card open their existing screens', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    await _pumpScreen(tester, fixture, const RoleHome(), width: 500, textScale: 1);
    final actions = <String, Type>{
      'Buy Crops': MarketScreen,
      'Sell to Exporters': CreateListingScreen,
      'Hire Labour': PostJobScreen,
      'Transport': TransportBookingScreen,
    };
    for (final action in actions.entries) {
      await _show(tester, find.text(action.key), _scrollableWithin(find.byType(RoleHome)));
      await tester.tap(find.text(action.key));
      await tester.pumpAndSettle();
      expect(find.byType(action.value), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
    }
    final listing = find.byKey(const Key('buyer-listing-ragi-test'));
    await _show(tester, listing, _scrollableWithin(find.byType(RoleHome)));
    await tester.tap(listing);
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailScreen), findsOneWidget);
    final detail = tester.widget<ListingDetailScreen>(find.byType(ListingDetailScreen));
    expect(detail.listing.id, 'ragi-test');
  });

  testWidgets('Buyer role switcher really changes the active dashboard', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    await _pumpScreen(tester, fixture, const RoleHome(), width: 500, textScale: 1);
    await tester.tap(find.byKey(const Key('active-role-button')));
    await tester.pumpAndSettle();
    expect(find.text('Switch role'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('role-tile-transport')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(fixture.session.user!.role, UserRole.transport);
    expect(find.byKey(const Key('dashboard-driver')), findsOneWidget);
    expect(find.byType(RoleHome), findsOneWidget);
  });

  testWidgets('Marketplace tabs are permission-driven and still switch', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    await _pumpScreen(tester, fixture, const TrackRouter(), width: 500, textScale: 1);
    final user = fixture.session.user!;
    expect(user.can(Permission.browseMarket), isTrue);
    expect(user.can(Permission.postJobs), isTrue);
    expect(user.can(Permission.viewPaymentTracker), isTrue);
    final bar = tester.widget<FloatingNavBar>(find.byType(FloatingNavBar));
    expect(bar.items.map((item) => item.id).toList(), [
      'home', 'market', 'jobs', 'payments', 'profile',
    ]);
    await tester.tap(find.byKey(const Key('floating-nav-jobs')));
    await tester.pumpAndSettle();
    expect(tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).selectedIndex, 2);

    await tester.runAsync(() => fixture.session.switchRole(UserRole.transport));
    await tester.pumpAndSettle();
    expect(fixture.session.user!.can(Permission.manageFleet), isTrue);
    expect(fixture.session.user!.can(Permission.postJobs), isFalse);
    final driverBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(driverBar.items.map((item) => item.label).toList(), [
      'Home', 'Fleet', 'Market', 'Payments', 'Profile',
    ]);
  });

  testWidgets('Student track keeps its four tabs and excludes marketplace', (
    tester,
  ) async {
    final fixture = await _fixture(tester, student: true);
    await _pumpScreen(
      tester,
      fixture,
      const TrackRouter(),
      width: 500,
      textScale: 1,
      education: true,
    );
    expect(Rbac.of(UserRole.student), isEmpty);
    expect(find.byType(EduShell), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(RoleHome), findsNothing);
    expect(find.byType(MarketScreen), findsNothing);
    final bar = tester.widget<FloatingNavBar>(find.byType(FloatingNavBar));
    expect(bar.items.map((item) => item.id).toList(), [
      'edu_tab_today', 'edu_tab_compete', 'edu_tab_progress', 'profile',
    ]);
    for (var index = 0; index < bar.items.length; index++) {
      await tester.tap(find.byKey(ValueKey('floating-nav-${bar.items[index].id}')));
      await tester.pumpAndSettle();
      expect(tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).selectedIndex, index);
      expect(find.byType(MarketScreen), findsNothing);
      expect(find.byType(AppShell), findsNothing);
    }
  });

  testWidgets('Student task cards open the existing education task screens', (
    tester,
  ) async {
    final fixture = await _fixture(tester, student: true);
    await _pumpScreen(
      tester,
      fixture,
      const EduHomeScreen(),
      width: 500,
      textScale: 1,
      education: true,
    );
    final destinations = <DailyTaskType, Type>{
      DailyTaskType.video: VideoTaskScreen,
      DailyTaskType.games: GamesTaskScreen,
      DailyTaskType.quiz: QuizTaskScreen,
    };
    for (final destination in destinations.entries) {
      final card = find.byKey(ValueKey('student-task-${destination.key.name}'));
      await _show(tester, card, _scrollableWithin(find.byType(EduHomeScreen)));
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(destination.value), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Urdu RTL renders all four screens at 320dp and 1.3 scale', (
    tester,
  ) async {
    final fixture = await _fixture(tester, language: AppLanguage.urdu);
    for (final screen in <Widget>[
      const CategoryScreen(),
      const RoleSelectionScreen(category: UserCategory.jobSeeker),
      const RoleHome(),
    ]) {
      await _pumpScreen(tester, fixture, screen, width: 320);
      expect(
        Directionality.of(tester.element(find.byType(screen.runtimeType))),
        TextDirection.rtl,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.runAsync(() => fixture.session.switchTo(fixture.student));
    await _pumpScreen(
      tester,
      fixture,
      const EduHomeScreen(),
      width: 320,
      education: true,
    );
    expect(
      Directionality.of(tester.element(find.byType(EduHomeScreen))),
      TextDirection.rtl,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
