import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/role_subtype.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../dashboards/dashboard_parts.dart';
import '../widgets/common.dart';
import 'create_property_screen.dart';

/// Browse land, commercial and residential rentals. Owners see their own
/// listings and incoming enquiries in the same place.
class PropertyMarketScreen extends StatefulWidget {
  const PropertyMarketScreen({super.key});

  @override
  State<PropertyMarketScreen> createState() => _PropertyMarketScreenState();
}

class _PropertyMarketScreenState extends State<PropertyMarketScreen> {
  RoleSubtype? _filter;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.user!;
    final market = context.watch<MarketplaceController>();
    final canList = user.can(Permission.listProperty);

    final available = market
        .activeProperties(kind: _filter)
        .where((p) => p.ownerId != user.id)
        .toList();
    final mine = market.propertiesByOwner(user.id);
    final incoming = market.enquiriesForOwner(user.id);
    final sent = market.enquiriesBySeeker(user.id);
    final kinds = RoleSubtypeX.propertyKinds;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(session.t('property')),
        actions: [
          if (canList)
            IconButton(
              icon: const Icon(Icons.add_home_work_outlined),
              tooltip: 'List a property',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreatePropertyScreen(),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                children: [
                  _Chip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  ...kinds.map(
                    (k) => _Chip(
                      label: k.label,
                      icon: k.icon,
                      selected: _filter == k,
                      onTap: () => setState(() => _filter = k),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                children: [
                  if (canList) ...[
                    SectionHeader(
                      'My Listings',
                      actionLabel: mine.isEmpty ? null : 'Add new',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CreatePropertyScreen(),
                        ),
                      ),
                    ),
                    if (mine.isEmpty)
                      EmptyCard(
                        icon: Icons.home_work_outlined,
                        message: 'You have not listed any property yet.',
                        actionLabel: 'List your first property',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CreatePropertyScreen(),
                          ),
                        ),
                      )
                    else
                      ...mine.map((p) => PropertyCard(property: p)),
                    const SizedBox(height: 20),
                    const SectionHeader('Enquiries Received'),
                    if (incoming.isEmpty)
                      const EmptyCard(
                        icon: Icons.mark_email_unread_outlined,
                        message: 'No enquiries yet.',
                      )
                    else
                      ...incoming.map(
                        (e) => EnquiryCard(enquiry: e, ownerView: true),
                      ),
                    const SizedBox(height: 20),
                  ],
                  SectionHeader(
                    _filter == null ? 'Available to Rent' : _filter!.label,
                  ),
                  if (available.isEmpty)
                    const EmptyCard(
                      icon: Icons.location_city_outlined,
                      message: 'Nothing available in this category yet.',
                    )
                  else
                    ...available.map((p) => PropertyCard(property: p)),
                  if (sent.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const SectionHeader('My Enquiries'),
                    ...sent.map((e) => EnquiryCard(enquiry: e)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
