import 'dart:io';

import 'package:blob/core/rbac/permissions.dart';
import 'package:blob/core/theme/app_colors.dart';
import 'package:blob/core/theme/app_theme.dart';
import 'package:blob/data/local_db.dart';
import 'package:blob/data/models/app_user.dart';
import 'package:blob/data/models/enums.dart';
import 'package:blob/data/models/learning.dart';
import 'package:blob/state/learning_controller.dart';
import 'package:blob/state/marketplace_controller.dart';
import 'package:blob/state/session_controller.dart';
import 'package:blob/ui/edu/edu_shell.dart';
import 'package:blob/ui/market/market_screen.dart';
import 'package:blob/ui/shell/app_shell.dart';
import 'package:blob/ui/shell/track_router.dart';
import 'package:blob/ui/widgets/blob_logo.dart';
import 'package:blob/ui/widgets/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

Future<SessionController> _session(
  WidgetTester tester, {
  required bool student,
}) async {
  final user = AppUser(
    id: student ? 'logo-student' : 'logo-buyer',
    phone: '+910000000001',
    countryCode: '+91',
    name: 'Test User',
    role: student ? UserRole.student : UserRole.buyer,
    category: student ? UserCategory.student : UserCategory.jobSeeker,
    district: 'Mandya',
    createdAt: DateTime(2025),
  );
  final directory = await tester.runAsync(() async {
    final dir = await Directory.systemTemp.createTemp('blob_logo_test_');
    final db = LocalDb.instance;
    await db.initAt(dir.path);
    await db.put(LocalDb.users, user.id, user.toMap());
    await db.setSetting('session_user_id', user.id);
    return dir;
  });
  if (directory == null) throw StateError('Could not create the test database');
  addTearDown(() async {
    await tester.runAsync(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
  });

  final session = SessionController()..load();
  addTearDown(session.dispose);
  return session;
}

Future<void> _pumpTrack(WidgetTester tester, SessionController session) async {
  // IndexedStack also lays out the existing marketplace tabs, so give the
  // full shell the same width used by the existing route tests.
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(500, 760);
  addTearDown(tester.view.reset);
  addTearDown(() => AppColors.applyPalette(const AgriPalette()));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
        ChangeNotifierProvider(create: (_) => MarketplaceController()),
        ChangeNotifierProvider(create: (_) => LearningController()),
      ],
      child: MaterialApp(theme: AppTheme.agri, home: const TrackRouter()),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  for (final size in [24.0, 48.0, 96.0, 240.0]) {
    for (final onDark in [false, true]) {
      testWidgets('BLOB mark fits ${size.toInt()}dp, onDark=$onDark', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(child: BlobLogoMark(size: size, onDark: onDark)),
              ),
            ),
          );
          final mark = find.byType(BlobLogoMark);
          expect(mark, findsOneWidget);
          expect(tester.getSize(mark), Size(size, size));
          expect(find.bySemanticsLabel('BLOB logo'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  for (final onDark in [false, true]) {
    testWidgets('BLOB mark paints the specified geometry, onDark=$onDark', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Center(child: BlobLogoMark(onDark: onDark))),
      );
      final paintWidget = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(BlobLogoMark),
          matching: find.byType(CustomPaint),
        ),
      );
      void paint(Canvas canvas) =>
          paintWidget.painter!.paint(canvas, const Size(200, 200));
      expect(
        paint,
        paints
          ..translate(x: 0, y: 0)
          ..translate(x: 7, y: 0)
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              const Rect.fromLTWH(40, 38, 28, 124),
              const Radius.circular(14),
            ),
            color: onDark ? AppColors.brandCream : AppColors.brandInk,
          )
          ..circle(
            x: 102,
            y: 74,
            radius: 36,
            color: onDark ? AppColors.brandGreenOnDark : AppColors.brandGreen,
          )
          ..circle(
            x: 106,
            y: 122,
            radius: 40,
            color: onDark ? AppColors.brandBlueOnDark : AppColors.brandBlue,
          )
          ..clipPath(
            pathMatcher: isA<Path>().having(
              (path) => path.getBounds(),
              'top-circle bounds',
              const Rect.fromLTWH(66, 38, 72, 72),
            ),
          )
          ..circle(x: 106, y: 122, radius: 40, color: AppColors.brandGold),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mark stays within a smaller non-square constraint', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 38,
            height: 27,
            child: BlobLogoMark(size: 240),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(BlobLogoMark)), const Size(38, 27));
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing placements retain their size and dark variant', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            BlobMark(size: 118, onDark: true),
            BlobMark(size: 56),
            BlobMark(size: 42),
            BlobMark(size: 34),
          ],
        ),
      ),
    );
    final marks = tester.widgetList<BlobLogoMark>(find.byType(BlobLogoMark));
    expect(marks.map((mark) => mark.size), [118, 56, 42, 34]);
    expect(marks.map((mark) => mark.onDark), [true, false, false, false]);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marketplace shell shows the new mark and BLOB text', (tester) async {
    final session = await _session(tester, student: false);
    await _pumpTrack(tester, session);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(BlobLogoMark), findsOneWidget);
    expect(find.text('BLOB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student shell has no marketplace or BLOB mark', (tester) async {
    final session = await _session(tester, student: true);
    await _pumpTrack(tester, session);
    expect(Rbac.of(UserRole.student), isEmpty);
    expect(find.byType(EduShell), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(MarketScreen), findsNothing);
    expect(find.byType(BlobLogoMark), findsNothing);
    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
