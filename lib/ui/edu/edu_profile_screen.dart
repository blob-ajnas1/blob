import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/learning.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../auth/switch_account_type_screen.dart';
import '../onboarding/language_screen.dart';
import '../onboarding/welcome_screen.dart';
import '../../data/gazetteer.dart';
import '../widgets/common.dart';
import '../widgets/place_map.dart';

/// Education track — "Profile" tab.
///
/// Shows only student-relevant information: academic details from signup, and
/// learning progress. There is deliberately no verification status, no free
/// post allowance and no company or country field — those belong to the
/// marketplace track and would be meaningless here.
///
/// This screen hosts "Switch account type", which is the single sanctioned
/// route between the two apps.
class EduProfileScreen extends StatelessWidget {
  const EduProfileScreen({super.key});

  static const _category = UserCategory.student;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final learning = context.watch<LearningController>();
    final user = session.user;
    if (user == null) return const SizedBox.shrink();

    final profile = learning.profileFor(user.id);
    final points = learning.totalPoints(user.id);
    final streak = learning.currentStreak(user.id);
    final rank = learning.rankOf(user.id, category: _category);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(session.t('profile'))),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _ProfileHeader(
              name: user.name,
              currentClass: profile?.currentClass ?? 'Student',
              district: user.district,
              city: user.city,
            ),
            const SizedBox(height: 18),
            const SectionHeader('My learning'),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    icon: Icons.stars_rounded,
                    label: 'Points',
                    value: '$points',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value: '${streak}d',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    icon: Icons.emoji_events_outlined,
                    label: 'Rank',
                    value: rank == null ? '\u2014' : '#$rank',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionHeader('Academic details'),
            if (profile == null)
              const InfoBanner(
                icon: Icons.info_outline,
                message:
                    'Your academic details are not saved yet. They were '
                    'collected during signup \u2014 contact support if this '
                    'looks wrong.',
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _Row(
                      icon: Icons.school_outlined,
                      label: 'Current class',
                      value: profile.currentClass,
                    ),
                    _Row(
                      icon: Icons.apartment_outlined,
                      label: 'School / college',
                      value: profile.collegeName,
                    ),
                    // Students below Class 10 have no 10th marks card yet, so
                    // the value is empty and the row is dropped rather than
                    // shown blank.
                    if (profile.tenthMarksCardNumber.trim().isNotEmpty)
                      _Row(
                        icon: Icons.badge_outlined,
                        label: '10th marks card',
                        value: profile.tenthMarksCardNumber,
                      ),
                    if (user.city != null && user.city!.trim().isNotEmpty)
                      _Row(
                        icon: Icons.location_city_outlined,
                        label: 'City / town',
                        value: user.city!,
                        isPlace: true,
                      ),
                    _Row(
                      icon: Icons.location_on_outlined,
                      label: 'District',
                      value: user.district,
                      isPlace: true,
                    ),
                    if (user.stateName != null &&
                        user.stateName!.trim().isNotEmpty)
                      _Row(
                        icon: Icons.map_outlined,
                        label: 'State',
                        value: user.stateName!,
                        isPlace: true,
                      ),
                    // Goals are optional, so an empty value means "not stated"
                    // rather than missing data. Drop the row instead of
                    // showing a blank one.
                    if (profile.goals.trim().isNotEmpty)
                      _Row(
                        icon: Icons.flag_outlined,
                        label: 'Goal',
                        value: profile.goals,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            const SectionHeader('Account'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _Tile(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    subtitle: '${user.countryCode} ${user.phone}',
                  ),
                  if (user.aadhaarLast4 != null)
                    _Tile(
                      icon: Icons.verified_user_outlined,
                      title: 'Aadhaar',
                      subtitle: 'Verified \u00b7 xxxx xxxx ${user.aadhaarLast4}',
                    ),
                  _Tile(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: session.language.nativeName,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const LanguageScreen(fromSettings: true),
                      ),
                    ),
                  ),
                  // The only route from the education app into the marketplace
                  // app. Placed here, behind an explicit confirmation, rather
                  // than as a tab — the two tracks are separate products.
                  _Tile(
                    icon: Icons.swap_horiz,
                    title: 'Switch account type',
                    subtitle: 'Currently Student \u00b7 change to Job Seeker',
                    isLast: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SwitchAccountTypeScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(session.t('logout')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              onPressed: () async {
                await session.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.currentClass,
    required this.district,
    this.city,
  });

  final String name;
  final String currentClass;
  final String district;
  final String? city;

  /// Prefer the town over the district: it is the more useful pin, and the
  /// district is where older accounts stop.
  String get place =>
      (city != null && city!.trim().isNotEmpty) ? city!.trim() : district;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Student \u00b7 $currentClass',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  // PlaceLink is not used here: it tints the link with
                  // AppColors.primary, which is the gradient this header is
                  // painted with, so the text would vanish. The map is opened
                  // directly instead and the white-on-brand styling kept.
                  InkWell(
                    onTap: () => openPlaceMap(
                      context,
                      place,
                      subtitle: 'Student \u00b7 $currentClass',
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                              decoration: Gazetteer.isKnown(place)
                                  ? TextDecoration.underline
                                  : null,
                              decorationColor:
                                  Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A plain count tile. The shared [StatTile] renders money (it takes
/// `amountPaise`), which is wrong for points, streaks and ranks.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.isPlace = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Renders the value as a tappable [PlaceLink] opening a map.
  final bool isPlace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 11),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: isPlace && value.isNotEmpty
                ? Align(
                    alignment: Alignment.centerRight,
                    child: PlaceLink(
                      name: value,
                      subtitle: label,
                      showIcon: false,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Text(
                    value.isEmpty ? '\u2014' : value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: onTap == null
              ? null
              : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onTap: onTap,
        ),
        if (!isLast)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
