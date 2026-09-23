import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../dashboards/dashboard_parts.dart';
import '../widgets/common.dart';
import 'create_listing_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _query = '';
  ListingChannel _channel = ListingChannel.toBuyers;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final market = context.watch<MarketplaceController>();
    final user = session.user;
    if (user == null) return const SizedBox.shrink();

    // Exporters only ever see the export channel.
    final lockedToExport = user.role == UserRole.globalExporter;
    final channel = lockedToExport ? ListingChannel.toExporters : _channel;

    var items = market.listingsFor(channel);
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      items = items
          .where(
            (l) =>
                l.cropName.toLowerCase().contains(q) ||
                l.district.toLowerCase().contains(q) ||
                l.ownerName.toLowerCase().contains(q),
          )
          .toList();
    }

    final canBuy = user.can(Permission.buyProducts);
    final canInvest = user.can(Permission.investInProjects);
    final isBroker = user.can(Permission.facilitateDeals);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          if (user.can(Permission.listCrops) ||
              user.can(Permission.resellToExporters))
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'New listing',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreateListingScreen(),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search crop, district or seller',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            if (!lockedToExport)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SegmentedButton<ListingChannel>(
                  segments: const [
                    ButtonSegment(
                      value: ListingChannel.toBuyers,
                      label: Text('From Farmers'),
                      icon: Icon(Icons.agriculture, size: 18),
                    ),
                    ButtonSegment(
                      value: ListingChannel.toExporters,
                      label: Text('Export Stock'),
                      icon: Icon(Icons.public, size: 18),
                    ),
                  ],
                  selected: {_channel},
                  onSelectionChanged: (s) => setState(() => _channel = s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
              ),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Nothing here yet',
                      message:
                          'No listings match your search. Try a different crop or district.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (context, i) => ListingCard(
                        listing: items[i],
                        showBuy: canBuy,
                        brokerMode: isBroker,
                        investorMode: canInvest,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
