import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/local_db.dart';
import 'data/seed.dart';
import 'core/i18n/strings.dart';
import 'state/learning_controller.dart';
import 'state/marketplace_controller.dart';
import 'state/session_controller.dart';
import 'ui/onboarding/welcome_screen.dart';
import 'ui/shell/track_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.instance.init();
  await Seed.ensure();
  runApp(const BlobApp());
}

class BlobApp extends StatelessWidget {
  const BlobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionController()..load()),
        ChangeNotifierProvider(create: (_) => MarketplaceController()),
        ChangeNotifierProvider(create: (_) => LearningController()),
      ],
      child: MaterialApp(
        title: 'BLOB',
        debugShowCheckedModeBanner: false,
        // Agri is the pre-login theme; signed-in users get their track's
        // theme from TrackRouter, which overrides this for students.
        theme: AppTheme.agri,
        home: const _Root(),
        builder: (context, child) {
          // Urdu, Kashmiri and Sindhi are right-to-left scripts; without this
          // the whole layout reads backwards.
          final language = context.watch<SessionController>().language;
          return Directionality(
            textDirection: language.isRtl
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    // TrackRouter, not AppShell: it picks the marketplace or education app
    // from the user's category and applies the matching theme.
    if (session.isLoggedIn) return const TrackRouter();
    return const WelcomeScreen();
  }
}
