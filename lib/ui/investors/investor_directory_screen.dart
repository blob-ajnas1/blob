import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/enums.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';
import '../widgets/place_map.dart';

/// Landowner tool to discover and connect with foreign investors.
class InvestorDirectoryScreen extends StatelessWidget {
  const InvestorDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final investors = market.usersByRole(UserRole.foreignInvestor);
    final myInvestments = market.investments
        .where((i) => i.landownerId == user.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Find Investors')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const InfoBanner(
              icon: Icons.currency_rupee,
              message:
                  'Investors fund projects in Indian Rupees (INR). '
                  'List your crop first so investors can find your project.',
            ),
            const SizedBox(height: 18),
            const SectionHeader('Verified Investors'),
            if (investors.isEmpty)
              const EmptyState(
                icon: Icons.trending_up,
                title: 'No investors yet',
                message:
                    'Foreign investors will appear here once they join BLOB.',
              )
            else
              ...investors.map(
                (inv) => _InvestorCard(
                  name: inv.name,
                  company: inv.companyName ?? '—',
                  country: inv.country ?? '—',
                ),
              ),
            if (myInvestments.isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionHeader('Investments in My Projects'),
              ...myInvestments.map(
                (i) => Padding(
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
                                i.projectTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'From ${i.investorName}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Money.format(i.amountPaise),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvestorCard extends StatelessWidget {
  final String name;
  final String company;
  final String country;

  const _InvestorCard({
    required this.name,
    required this.company,
    required this.country,
  });

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
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.trending_up, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Only the country half is tappable — the company name is
                  // not a place.
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$company · ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      PlaceLink(
                        name: country,
                        subtitle: '$name · $company',
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
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(88, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () =>
                  showSnack(context, 'Connection request sent to $name'),
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
