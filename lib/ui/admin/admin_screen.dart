import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../state/marketplace_controller.dart';
import '../dashboards/dashboard_parts.dart';
import '../widgets/common.dart';
import '../widgets/place_map.dart';

/// Internal company-manager panel. Reached only by the hidden admin role,
/// so there is no second app to deploy.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketplaceController>();
    final pending = market.pendingApprovals();
    final brokers = market.users
        .where((u) => u.role == UserRole.broker)
        .toList();
    final exporters = market.users
        .where((u) => u.role == UserRole.globalExporter)
        .toList();

    final list = switch (_tab) {
      0 => pending,
      1 => brokers,
      _ => exporters,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Account Verification')),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text('Pending (${pending.length})'),
                  ),
                  const ButtonSegment(value: 1, label: Text('Brokers')),
                  const ButtonSegment(value: 2, label: Text('Exporters')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(
                      icon: Icons.verified_outlined,
                      title: 'Nothing here',
                      message: 'No accounts in this category.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final u = list[i];
                        if (u.verificationStatus ==
                            VerificationStatus.pending) {
                          return PendingUserCard(pendingUser: u);
                        }
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.companyName ?? u.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      // The district is tappable so an
                                      // approver can check where an applicant
                                      // actually is before approving them.
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${u.roleLine} · ',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          PlaceLink(
                                            name: u.district,
                                            subtitle: u.companyName ?? u.name,
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
                                StatusPill(
                                  label: u.verificationStatus.label,
                                  color: u.isApproved
                                      ? AppColors.success
                                      : AppColors.danger,
                                  background: u.isApproved
                                      ? AppColors.clearedSoft
                                      : AppColors.dangerSoft,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
