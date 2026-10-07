import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../data/models/job.dart';
import '../../data/models/listing.dart';
import '../../data/models/property.dart';
import '../../data/models/role_subtype.dart';
import '../../data/models/vehicle.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../market/listing_detail_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/place_map.dart';
import 'role_switcher.dart';
import '../../core/utils/crop_images.dart';

final _dateFmt = DateFormat('d MMM');

/// Light app bar that sits above the dashboard: brand lockup on the left,
/// the user's district and a notification bell on the right.
class HomeTopBar extends StatelessWidget {
  final AppUser user;
  const HomeTopBar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const BlobMark(size: 34),
          const SizedBox(width: 10),
          // The active role replaces the wordmark: it is the one thing on the
          // bar the user acts on, so it gets the prominent slot.
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActiveRoleButton(user: user),
            ),
          ),
          const SizedBox(width: 8),
          // The header location doubles as the shortcut to "where am I on the
          // map", so the pin and the name are one tap target.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: PlaceLink(
              name: user.city?.trim().isNotEmpty == true
                  ? user.city!
                  : user.district,
              subtitle: user.city?.trim().isNotEmpty == true
                  ? user.district
                  : user.stateName,
              icon: Icons.location_on_outlined,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _NotificationBell(user: user),
        ],
      ),
    );
  }
}

/// Bell with a red dot when the account still needs attention.
class _NotificationBell extends StatelessWidget {
  final AppUser user;
  const _NotificationBell({required this.user});

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketplaceController>();
    final pendingMoney =
        market.pendingIncomingPaise(user.id) > 0 ||
        market.pendingOutgoingPaise(user.id) > 0;
    final hasAlert = user.isPending || pendingMoney;

    return Semantics(
      label: hasAlert ? 'Notifications, unread' : 'Notifications',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showSnack(
          context,
          hasAlert
              ? 'You have pending items that need attention.'
              : 'No new notifications.',
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none,
                size: 23,
                color: AppColors.primary,
              ),
              if (hasAlert)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark green header card: local-language greeting, verified role pill and
/// two circular INR stat rings.
class DashboardHeader extends StatelessWidget {
  final AppUser user;
  const DashboardHeader({super.key, required this.user});

  /// First name only — the greeting is personal, and full legal/company names
  /// overflow the card on narrow screens.
  String get _firstName {
    final parts = user.name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'there' : parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketplaceController>();
    final session = context.watch<SessionController>();
    final isPayer =
        user.role == UserRole.buyer ||
        user.role == UserRole.shopkeeper ||
        user.role == UserRole.globalExporter ||
        user.role == UserRole.foreignInvestor;

    // Landowners both earn and spend, so show what actually landed.
    final primaryPaise = isPayer
        ? market.clearedOutgoingPaise(user.id)
        : market.clearedIncomingPaise(user.id);
    final secondaryPaise = isPayer
        ? market.pendingOutgoingPaise(user.id)
        : market.pendingIncomingPaise(user.id);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${session.t('greeting')},',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _RolePill(user: user),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatRing(
            label: isPayer ? 'Paid' : 'Cleared',
            amountPaise: primaryPaise,
          ),
          const SizedBox(width: 8),
          _StatRing(
            label: isPayer ? 'To Pay' : 'Pending',
            amountPaise: secondaryPaise,
            amountColor: AppColors.pending,
          ),
        ],
      ),
    );
  }
}

/// White pill under the greeting showing the role, with a tick once approved.
class _RolePill extends StatelessWidget {
  final AppUser user;
  const _RolePill({required this.user});

  @override
  Widget build(BuildContext context) {
    final approved = !user.isPending;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            approved ? Icons.check_circle : Icons.hourglass_top,
            size: 13,
            color: approved ? AppColors.primary : AppColors.pending,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              user.role.shortLabel.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular white money chip used inside the green header.
class _StatRing extends StatelessWidget {
  final String label;
  final int amountPaise;
  final Color? amountColor;

  const _StatRing({
    required this.label,
    required this.amountPaise,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label ${Money.format(amountPaise)}',
      child: Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '\u20B9',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: FittedBox(
                child: Text(
                  Money.compact(amountPaise),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: amountColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally scrolling strip of quick actions.
///
/// A wrapping grid pushed content below the fold once landowners gained eight
/// actions, so this scrolls sideways instead: about four tiles are visible and
/// the clipped next one signals there is more to swipe to.
///
/// The parent list applies a 16px inset, but the strip should bleed to both
/// screen edges. [OverflowBox] lets it render wider than its parent (negative
/// padding is not legal in Flutter), while the list's own inset keeps the first
/// tile aligned with the rest of the page.
class QuickActionsGrid extends StatelessWidget {
  final List<Widget> actions;

  /// Horizontal inset applied by the enclosing page.
  final double pageInset;

  const QuickActionsGrid({
    super.key,
    required this.actions,
    this.pageInset = 16,
  });

  static const double _tileWidth = 86;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: 96,
      child: OverflowBox(
        maxWidth: fullWidth,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: pageInset),
          itemCount: actions.length,
          separatorBuilder: (_, __) => const SizedBox(width: _gap),
          itemBuilder: (_, i) => SizedBox(width: _tileWidth, child: actions[i]),
        ),
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyCard({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  final Listing listing;
  final bool showBuy;
  final bool brokerMode;
  final bool investorMode;

  const ListingCard({
    super.key,
    required this.listing,
    this.showBuy = false,
    this.brokerMode = false,
    this.investorMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ListingDetailScreen(
              listing: listing,
              brokerMode: brokerMode,
              investorMode: investorMode,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CropThumb(
                  imageAsset: listing.imageAsset,
                  cropName: listing.cropName,
                  width: 52,
                  height: 52,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.cropName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${listing.quantityQuintal.toStringAsFixed(0)} quintal · ${listing.district}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${Money.format(listing.pricePerQuintalPaise)} / quintal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (listing.status != ListingStatus.active)
                          StatusPill.text(listing.status.label),
                      ],
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

/// Crop photograph with a graceful fallback if the asset is missing.
class CropThumb extends StatelessWidget {
  final String? imageAsset;
  final String cropName;
  final double? width;
  final double? height;

  const CropThumb({
    super.key,
    required this.cropName,
    this.imageAsset,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      CropImages.resolve(imageAsset: imageAsset, cropName: cropName),
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: AppColors.primarySoft,
        child: Center(child: Icon(Icons.grass, color: AppColors.primary)),
      ),
    );
  }
}

/// Horizontally scrolling photo cards for the owner's own crop listings.
///
/// Photos make a crop far easier to recognise at a glance than a text row,
/// which matters for users who read slowly or are working in bright sunlight.
class MyListingsStrip extends StatelessWidget {
  final List<Listing> listings;
  final double pageInset;

  const MyListingsStrip({
    super.key,
    required this.listings,
    this.pageInset = 16,
  });

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: 214,
      child: OverflowBox(
        maxWidth: fullWidth,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: pageInset),
          itemCount: listings.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _ListingPhotoCard(listing: listings[i]),
        ),
      ),
    );
  }
}

class _ListingPhotoCard extends StatelessWidget {
  final Listing listing;
  const _ListingPhotoCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ListingDetailScreen(listing: listing),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: CropThumb(
                      imageAsset: listing.imageAsset,
                      cropName: listing.cropName,
                      width: double.infinity,
                      height: 104,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _ListingOverflowMenu(listing: listing),
                  ),
                  if (listing.status != ListingStatus.active)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: StatusPill.text(listing.status.label),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.cropName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Quantity: ${listing.quantityQuintal.toStringAsFixed(0)} quintals',
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${Money.format(listing.pricePerQuintalPaise)} / quintal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overflow menu on a listing photo: mark sold / reserved / withdrawn.
class _ListingOverflowMenu extends StatelessWidget {
  final Listing listing;
  const _ListingOverflowMenu({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<ListingStatus>(
        icon: const Icon(Icons.more_horiz, size: 18),
        iconSize: 18,
        padding: EdgeInsets.zero,
        tooltip: 'Listing options',
        constraints: const BoxConstraints(minWidth: 168),
        onSelected: (status) async {
          await context.read<MarketplaceController>().updateListingStatus(
            listing,
            status,
          );
          if (!context.mounted) return;
          showSnack(context, 'Listing marked ${status.label.toLowerCase()}.');
        },
        itemBuilder: (_) => ListingStatus.values
            .where((s) => s != listing.status)
            .map(
              (s) => PopupMenuItem<ListingStatus>(
                value: s,
                child: Text('Mark ${s.label.toLowerCase()}'),
              ),
            )
            .toList(),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  final bool showApply;

  const JobCard({super.key, required this.job, this.showApply = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => JobDetailScreen(jobId: job.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    job.jobType == JobType.group ? Icons.groups : Icons.person,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusPill.text(job.status.label),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.people_outline,
                    label: '${job.workersNeeded} needed',
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.event_outlined,
                    label: _dateFmt.format(job.workDate),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${Money.format(job.wagePerWorkerPaise)} per worker',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (showApply)
                    const Text(
                      'Tap to apply',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
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

class ApplicationCard extends StatelessWidget {
  final JobApplication application;
  const ApplicationCard({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketplaceController>();
    final job = market.jobs.where((j) => j.id == application.jobId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job?.title ?? 'Job',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job == null
                        ? ''
                        : '${Money.format(job.wagePerWorkerPaise * application.groupSize)} · ${_dateFmt.format(job.workDate)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            StatusPill.text(application.status.label),
          ],
        ),
      ),
    );
  }
}

class WorkTypeBanner extends StatelessWidget {
  final LaborerType type;
  const WorkTypeBanner({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            type == LaborerType.groupWork ? Icons.groups : Icons.person,
            size: 30,
            color: AppColors.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommissionSummary extends StatelessWidget {
  final int earnedPaise;
  final int pendingPaise;

  const CommissionSummary({
    super.key,
    required this.earnedPaise,
    required this.pendingPaise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: 'Commission Earned',
              value: Money.format(earnedPaise),
              color: AppColors.success,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _Metric(
              label: 'Awaiting Clearance',
              value: Money.format(pendingPaise),
              color: AppColors.pending,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                vehicle.subtype?.icon ??
                    switch (vehicle.category) {
                      VehicleCategory.goods => Icons.local_shipping,
                      VehicleCategory.passenger => Icons.local_taxi,
                      VehicleCategory.rental => Icons.vpn_key,
                    },
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.vehicleType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${vehicle.registrationNumber} · ${vehicle.capacityLabel}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Money.format(vehicle.ratePaise)} / ${vehicle.rateUnit}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: vehicle.available,
              activeThumbColor: AppColors.primary,
              onChanged: (_) => market.toggleVehicleAvailability(vehicle),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final VehicleBooking booking;
  final bool providerView;

  const BookingCard({
    super.key,
    required this.booking,
    this.providerView = false,
  });

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Both ends of the trip are place names, so both link to the
                // map independently. A pickup point that is a landmark rather
                // than a town simply renders as plain text.
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: PlaceLink(
                          name: booking.pickup,
                          subtitle: 'Pickup',
                          showIcon: false,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Text(
                        ' → ',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Flexible(
                        child: PlaceLink(
                          name: booking.drop,
                          subtitle: 'Drop',
                          showIcon: false,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill.text(booking.status.label),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${booking.vehicleLabel} · ${booking.quantityLabel}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  Money.format(booking.farePaise),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (providerView && booking.status == BookingStatus.requested)
                  TextButton(
                    onPressed: () => market.updateBookingStatus(
                      booking,
                      BookingStatus.confirmed,
                    ),
                    child: const Text('Confirm'),
                  ),
                if (providerView && booking.status == BookingStatus.confirmed)
                  TextButton(
                    onPressed: () => market.updateBookingStatus(
                      booking,
                      BookingStatus.delivered,
                    ),
                    child: const Text('Mark delivered'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InvestmentCard extends StatelessWidget {
  final Investment investment;
  const InvestmentCard({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investment.projectTitle,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    investment.landownerName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(investment.amountPaise),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                StatusPill.payment(investment.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExporterBanner extends StatelessWidget {
  final AppUser user;
  const ExporterBanner({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.companyName ?? user.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.country ?? ''} · Reg ${user.registrationNo ?? '—'}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSummary extends StatelessWidget {
  final int totalUsers;
  final int pendingCount;
  final int listingCount;
  final int jobCount;

  const AdminSummary({
    super.key,
    required this.totalUsers,
    required this.pendingCount,
    required this.listingCount,
    required this.jobCount,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: [
        _AdminTile(label: 'Total Users', value: '$totalUsers'),
        _AdminTile(
          label: 'Pending Approval',
          value: '$pendingCount',
          highlight: pendingCount > 0,
        ),
        _AdminTile(label: 'Listings', value: '$listingCount'),
        _AdminTile(label: 'Jobs Posted', value: '$jobCount'),
      ],
    );
  }
}

class _AdminTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _AdminTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.pendingSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppColors.pending : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: highlight ? AppColors.pending : AppColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class PendingUserCard extends StatelessWidget {
  final AppUser pendingUser;
  const PendingUserCard({super.key, required this.pendingUser});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingUser.companyName ?? pendingUser.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${pendingUser.roleLine} · ${pendingUser.phone}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const StatusPill(
                  label: 'Pending',
                  color: AppColors.pending,
                  background: AppColors.pendingSoft,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    onPressed: () async {
                      await market.setVerification(
                        pendingUser,
                        VerificationStatus.rejected,
                      );
                      if (context.mounted) {
                        showSnack(context, 'Account rejected');
                      }
                    },
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: () async {
                      await market.setVerification(
                        pendingUser,
                        VerificationStatus.approved,
                      );
                      if (context.mounted) {
                        showSnack(context, 'Account approved');
                      }
                    },
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Property & land rental
// ---------------------------------------------------------------------------

/// Human label for a property listing's lifecycle state.
String propertyStatusLabel(ListingStatus status) => switch (status) {
  ListingStatus.active => 'Available',
  ListingStatus.reserved => 'Reserved',
  ListingStatus.sold => 'Leased',
  ListingStatus.withdrawn => 'Withdrawn',
};

class PropertyCard extends StatelessWidget {
  final PropertyListing property;
  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final isOwner = property.ownerId == user.id;
    final canEnquire =
        !isOwner &&
        property.status == ListingStatus.active &&
        user.can(Permission.browseProperty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(property.kind.icon, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Locality is free text typed by the owner, so it is not
                      // reliably mappable; the district behind it always is.
                      // Only that half links, with the locality carried into
                      // the map screen as context.
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${property.locality} · ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          PlaceLink(
                            name: property.district,
                            subtitle:
                                '${property.locality} · ${property.title}',
                            iconSize: 12,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusPill.text(propertyStatusLabel(property.status)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Tag(icon: Icons.straighten, text: property.areaLabel),
                _Tag(
                  icon: Icons.event_repeat,
                  text: 'Min ${property.leaseMonthsMin} mo',
                ),
                _Tag(
                  icon: Icons.event_available_outlined,
                  text: 'From ${_dateFmt.format(property.availableFrom)}',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              property.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${Money.format(property.rentPerMonthPaise)} / month',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Deposit ${Money.format(property.depositPaise)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isOwner) _OwnerPropertyMenu(property: property),
                if (canEnquire)
                  FilledButton(
                    onPressed: () => _openEnquirySheet(context, property, user),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Text('Enquire'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerPropertyMenu extends StatelessWidget {
  final PropertyListing property;
  const _OwnerPropertyMenu({required this.property});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    return PopupMenuButton<ListingStatus>(
      tooltip: 'Change status',
      icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
      onSelected: (s) => market.updatePropertyStatus(property, s),
      itemBuilder: (_) => ListingStatus.values
          .where((s) => s != property.status)
          .map(
            (s) => PopupMenuItem<ListingStatus>(
              value: s,
              child: Text('Mark ${propertyStatusLabel(s).toLowerCase()}'),
            ),
          )
          .toList(),
    );
  }
}

Future<void> _openEnquirySheet(
  BuildContext context,
  PropertyListing property,
  AppUser seeker,
) async {
  final market = context.read<MarketplaceController>();
  final messageCtrl = TextEditingController();
  int months = property.leaseMonthsMin;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${Money.format(property.rentPerMonthPaise)}/month · '
              'deposit ${Money.format(property.depositPaise)}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lease duration',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: months > property.leaseMonthsMin
                      ? () => setSheet(() => months -= 1)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$months months',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: months < 120
                      ? () => setSheet(() => months += 1)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message to owner',
                alignLabelWithHint: true,
                hintText: 'Intended use, start date, questions...',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total lease value',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    Money.format(property.rentPerMonthPaise * months),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await market.raiseEnquiry(
                  property: property,
                  seeker: seeker,
                  months: months,
                  message: messageCtrl.text.trim(),
                );
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                if (context.mounted) {
                  showSnack(context, 'Enquiry sent to ${property.ownerName}');
                }
              },
              child: const Text('Send Enquiry'),
            ),
          ],
        ),
      ),
    ),
  );
  messageCtrl.dispose();
}

class EnquiryCard extends StatelessWidget {
  final PropertyEnquiry enquiry;
  final bool ownerView;

  const EnquiryCard({super.key, required this.enquiry, this.ownerView = false});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    final open =
        enquiry.status == EnquiryStatus.open ||
        enquiry.status == EnquiryStatus.shortlisted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    enquiry.propertyTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusPill.text(enquiry.status.label),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ownerView
                  ? '${enquiry.seekerName} · ${enquiry.months} months'
                  : '${enquiry.months} months · sent ${_dateFmt.format(enquiry.createdAt)}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (enquiry.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  enquiry.message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
            if (ownerView && open) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  TextButton(
                    onPressed: () => market.setEnquiryStatus(
                      enquiry,
                      EnquiryStatus.declined,
                    ),
                    child: const Text('Decline'),
                  ),
                  const Spacer(),
                  if (enquiry.status == EnquiryStatus.open)
                    TextButton(
                      onPressed: () => market.setEnquiryStatus(
                        enquiry,
                        EnquiryStatus.shortlisted,
                      ),
                      child: const Text('Shortlist'),
                    ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () =>
                        market.setEnquiryStatus(enquiry, EnquiryStatus.agreed),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Agree lease'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
