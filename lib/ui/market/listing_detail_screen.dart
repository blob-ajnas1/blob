import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../data/models/listing.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';
import '../widgets/place_map.dart';

class ListingDetailScreen extends StatelessWidget {
  final Listing listing;
  final bool brokerMode;
  final bool investorMode;

  const ListingDetailScreen({
    super.key,
    required this.listing,
    this.brokerMode = false,
    this.investorMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final canBuy =
        user.can(Permission.buyProducts) &&
        listing.ownerId != user.id &&
        listing.status == ListingStatus.active;
    final canInvest =
        user.can(Permission.investInProjects) &&
        listing.status == ListingStatus.active;

    return Scaffold(
      appBar: AppBar(title: Text(listing.cropName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.cropName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${listing.quantityQuintal.toStringAsFixed(0)} quintal available',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${Money.format(listing.pricePerQuintalPaise)} / quintal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total lot ${Money.format(listing.totalPaise)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Seller',
              value: '${listing.ownerName} (${listing.ownerRole.label})',
            ),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'District',
              value: listing.district,
              isPlace: true,
              placeSubtitle: '${listing.cropName} · ${listing.ownerName}',
            ),
            _DetailRow(
              icon: Icons.sell_outlined,
              label: 'Offered to',
              value: listing.channel.label,
            ),
            _DetailRow(
              icon: Icons.info_outline,
              label: 'Status',
              value: listing.status.label,
            ),
            const SizedBox(height: 18),
            const Text(
              'Description',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              listing.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 26),
            if (brokerMode)
              InfoBanner(
                icon: Icons.handshake_outlined,
                message:
                    'As broker you earn ${(Money.brokerCommissionRate * 100).toStringAsFixed(1)}% '
                    '(${Money.format(Money.brokerCommissionOn(listing.totalPaise))}) when this deal closes.',
              ),
            if (canBuy) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout),
                label: Text('Buy for ${Money.format(listing.totalPaise)}'),
                onPressed: () => _confirmPurchase(context, user, market),
              ),
            ],
            if (canInvest) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.trending_up),
                label: const Text('Invest in this project'),
                onPressed: () => _investDialog(context, user, market),
              ),
            ],
            if (listing.ownerId == user.id &&
                listing.status == ListingStatus.active) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Withdraw listing'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: () async {
                  await market.updateListingStatus(
                    listing,
                    ListingStatus.withdrawn,
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPurchase(
    BuildContext context,
    AppUser buyer,
    MarketplaceController market,
  ) async {
    final brokers = market.usersByRole(UserRole.broker);
    AppUser? chosenBroker;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Confirm purchase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${listing.cropName}\n'
                '${listing.quantityQuintal.toStringAsFixed(0)} quintal',
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 10),
              Text(
                Money.format(listing.totalPaise),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              if (brokers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Broker (optional)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<AppUser?>(
                  initialValue: chosenBroker,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  hint: const Text('No broker'),
                  items: [
                    const DropdownMenuItem<AppUser?>(
                      value: null,
                      child: Text('No broker'),
                    ),
                    ...brokers.map(
                      (b) => DropdownMenuItem<AppUser?>(
                        value: b,
                        child: Text(b.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => chosenBroker = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await market.purchaseListing(
      listing: listing,
      buyer: buyer,
      broker: chosenBroker,
    );
    if (!context.mounted) return;
    showSnack(
      context,
      'Purchase recorded. Payment is now pending in your tracker.',
    );
    Navigator.of(context).pop();
  }

  Future<void> _investDialog(
    BuildContext context,
    AppUser investor,
    MarketplaceController market,
  ) async {
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Investment amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All investments are settled in Indian Rupees (INR).',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                prefixText: '\u20B9 ',
                labelText: 'Amount',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () {
              final rupees = int.tryParse(controller.text.trim()) ?? 0;
              Navigator.of(
                dialogContext,
              ).pop(rupees > 0 ? Money.rupeesToPaise(rupees) : null);
            },
            child: const Text('Invest'),
          ),
        ],
      ),
    );

    if (amount == null || !context.mounted) return;
    await market.createInvestment(
      investor: investor,
      project: listing,
      amountPaise: amount,
    );
    if (!context.mounted) return;
    showSnack(context, 'Investment of ${Money.format(amount)} recorded');
    Navigator.of(context).pop();
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// Renders the value as a tappable [PlaceLink] that opens a map. Unknown
  /// names degrade to plain text, so this is safe on any location field.
  final bool isPlace;

  /// Context line for the map screen, e.g. the crop being sold here.
  final String? placeSubtitle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isPlace = false,
    this.placeSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: isPlace
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: PlaceLink(
                      name: value,
                      subtitle: placeSubtitle,
                      showIcon: false,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Text(
                    value,
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
