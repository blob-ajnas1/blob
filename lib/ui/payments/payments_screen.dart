import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/enums.dart';
import '../../data/models/ledger.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

final _fmt = DateFormat('d MMM yyyy');

/// Payment Tracker Dashboard — pending payouts, cleared payments and
/// complete history, all in INR.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();

    final all = market.ledgerFor(user.id);
    final toPay = all
        .where((e) => e.payerId == user.id && e.status == PaymentStatus.pending)
        .toList();
    final toReceive = all
        .where((e) => e.payeeId == user.id && e.status == PaymentStatus.pending)
        .toList();
    final cleared = all
        .where((e) => e.status == PaymentStatus.cleared)
        .toList();

    final entries = switch (_tab) {
      0 => toPay,
      1 => toReceive,
      _ => cleared,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Tracker')),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'You Owe',
                      amountPaise: toPay.fold(0, (s, e) => s + e.amountPaise),
                      color: AppColors.pending,
                      background: AppColors.pendingSoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Due to You',
                      amountPaise: toReceive.fold(
                        0,
                        (s, e) => s + e.amountPaise,
                      ),
                      color: AppColors.info,
                      background: const Color(0xFFE8F1FC),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Cleared',
                      amountPaise: cleared.fold(0, (s, e) => s + e.amountPaise),
                      color: AppColors.success,
                      background: AppColors.clearedSoft,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('To Pay')),
                  ButtonSegment(value: 1, label: Text('Incoming')),
                  ButtonSegment(value: 2, label: Text('History')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ),
            if (_tab == 0 && toPay.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.done_all),
                  label: Text(
                    'Clear all '
                    '${Money.format(toPay.fold(0, (s, e) => s + e.amountPaise))}',
                  ),
                  onPressed: () async {
                    await market.clearAllPending(user.id);
                    if (context.mounted) {
                      showSnack(context, 'All pending payments cleared');
                    }
                  },
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: entries.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: switch (_tab) {
                        0 => 'Nothing to pay',
                        1 => 'Nothing incoming',
                        _ => 'No history yet',
                      },
                      message: switch (_tab) {
                        0 => 'You have no pending payments to clear.',
                        1 => 'No one owes you money right now.',
                        _ => 'Cleared payments will appear here.',
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: entries.length,
                      itemBuilder: (context, i) => _LedgerTile(
                        entry: entries[i],
                        currentUserId: user.id,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amountPaise;
  final Color color;
  final Color background;

  const _SummaryCard({
    required this.label,
    required this.amountPaise,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.compact(amountPaise),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  final LedgerEntry entry;
  final String currentUserId;

  const _LedgerTile({required this.entry, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    final outgoing = entry.payerId == currentUserId;
    final counterparty = outgoing ? entry.payeeName : entry.payerName;

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
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: outgoing
                        ? AppColors.pendingSoft
                        : AppColors.clearedSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    outgoing ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 20,
                    color: outgoing ? AppColors.pending : AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.type.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${outgoing ? 'To' : 'From'} $counterparty',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (entry.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Money.format(entry.amountPaise),
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: outgoing
                            ? AppColors.textPrimary
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StatusPill.payment(entry.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  entry.status == PaymentStatus.cleared &&
                          entry.clearedAt != null
                      ? 'Cleared ${_fmt.format(entry.clearedAt!)}'
                      : 'Raised ${_fmt.format(entry.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (outgoing && entry.status == PaymentStatus.pending)
                  TextButton(
                    onPressed: () async {
                      final ok = await market.clearPayment(entry);
                      if (context.mounted) {
                        showSnack(
                          context,
                          ok ? 'Payment cleared' : 'Payment failed',
                          error: !ok,
                        );
                      }
                    },
                    child: const Text('Clear now'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
