import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/i18n/strings.dart';
import '../../data/models/enums.dart';
import '../../data/models/learning.dart';
import '../../data/models/role_subtype.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../auth/switch_account_type_screen.dart';
import '../onboarding/language_screen.dart';
import '../onboarding/welcome_screen.dart';
import '../widgets/common.dart';
import '../widgets/place_map.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final market = context.watch<MarketplaceController>();
    final user = session.user!;

    return Scaffold(
      appBar: AppBar(title: Text(session.t('profile'))),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Container(
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
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'B',
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
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.phone,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role.label.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (user.subtype != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                user.subtype!.icon,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  user.subtype!.label,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
            if (user.stateName != null && user.stateName!.trim().isNotEmpty)
              _Row(
                icon: Icons.map_outlined,
                label: 'State',
                value: user.stateName!,
                isPlace: true,
              ),
            if (user.subtype != null)
              _Row(
                icon: user.subtype!.icon,
                label: 'Specialisation',
                value: user.subtype!.label,
              ),
            if (user.laborerType != null)
              _Row(
                icon: Icons.work_outline,
                label: 'Crew size',
                value: user.laborerType!.label,
              ),
            if (user.companyName != null)
              _Row(
                icon: Icons.business_outlined,
                label: 'Company',
                value: user.companyName!,
              ),
            if (user.country != null)
              _Row(
                icon: Icons.public,
                label: 'Country',
                value: user.country!,
                isPlace: true,
              ),
            _Row(
              icon: Icons.verified_user_outlined,
              label: 'Status',
              value: user.verificationStatus.label,
            ),
            if (Money.jobPostingFeesEnabled)
              _Row(
                icon: Icons.post_add,
                label: 'Free posts left',
                value:
                    '${market.freePostsRemaining(user)} of '
                    '${Money.freeJobPostLimit}',
              ),
            const SizedBox(height: 18),
            const SectionHeader('Settings'),
            _Tile(
              icon: Icons.language,
              title: 'Language',
              subtitle: session.language.nativeName,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LanguageScreen(fromSettings: true),
                ),
              ),
            ),
            // The only route from the marketplace app into the education app.
            // Deliberately here rather than as a tab: the two tracks are
            // separate products, so crossing is an explicit account change.
            _Tile(
              icon: Icons.swap_horiz,
              title: 'Switch account type',
              subtitle: _switchSubtitle(user.category),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SwitchAccountTypeScreen(),
                ),
              ),
            ),
            // Debug builds only. This signs into ANY account on the device,
            // administrators included, with no password or OTP — it is a
            // complete authentication bypass and must never reach a release
            // build. Kept for local review of the role dashboards.
            if (kDebugMode)
              _Tile(
                icon: Icons.people_outline,
                title: 'Switch account (debug build)',
                subtitle: 'Preview any role instantly',
                onTap: () => _switchAccount(context, market),
              ),
            const SizedBox(height: 10),
            const InfoBanner(
              icon: Icons.currency_rupee,
              message:
                  'BLOB operates exclusively in Indian Rupees (INR) for all '
                  'users, including international investors and exporters.',
            ),
            const SizedBox(height: 18),
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

  /// Names both sides of the switch so the row is self-explanatory. A user
  /// whose category was never set is treated as a job seeker, matching how the
  /// rest of the marketplace app reads a null category.
  String _switchSubtitle(UserCategory? category) {
    final current = category ?? UserCategory.jobSeeker;
    final other = current == UserCategory.student
        ? UserCategory.jobSeeker
        : UserCategory.student;
    return 'Currently ${current.label} \u00b7 change to ${other.label}';
  }

  void _switchAccount(BuildContext context, MarketplaceController market) {
    final session = context.read<SessionController>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(
                  'Switch account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Demo shortcut for reviewing each role dashboard.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: market.users.map((u) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          u.name[0].toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      title: Text(
                        u.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${u.roleLine}${u.isPending ? ' · Pending' : ''}',
                      ),
                      onTap: () async {
                        await session.switchTo(u);
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// When true the value is rendered as a [PlaceLink], so tapping it opens the
  /// place on a map. Names the gazetteer does not know fall back to plain text
  /// automatically, so this is safe to set on any location-shaped field.
  final bool isPlace;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.isPlace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: isPlace
                ? Align(
                    alignment: Alignment.centerRight,
                    child: PlaceLink(
                      name: value,
                      subtitle: label,
                      // The row already carries a location icon on the left;
                      // a second pin here would just be noise. Colour and
                      // underline carry the affordance instead.
                      showIcon: false,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
