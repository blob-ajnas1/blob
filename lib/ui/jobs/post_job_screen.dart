import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/enums.dart';
import '../../services/payment_gateway.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _workers = TextEditingController(text: '1');
  final _wage = TextEditingController();
  JobType _type = JobType.group;
  DateTime _workDate = DateTime.now().add(const Duration(days: 2));
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _workers.dispose();
    _wage.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _workDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _workDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final session = context.read<SessionController>();
    final market = context.read<MarketplaceController>();
    final user = session.user!;
    final fee = market.postingFeeFor(user);

    if (fee > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) =>
            _FeeDialog(fee: fee, mode: market.paymentMode),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    final outcome = await market.postJob(
      poster: user,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      jobType: _type,
      workersNeeded: int.parse(_workers.text),
      wagePerWorkerPaise: Money.rupeesToPaise(double.parse(_wage.text)),
      workDate: _workDate,
      onPosterUpdated: session.updateUser,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    // Cancelling checkout is a choice, not an error: keep the form as typed
    // so the user can pay later without re-entering everything.
    showSnack(
      context,
      outcome.message,
      error: !outcome.success && !outcome.cancelled,
    );
    if (outcome.success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final fee = market.postingFeeFor(user);
    final freeLeft = market.freePostsRemaining(user);

    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fee == 0)
                  InfoBanner(
                    icon: Icons.card_giftcard,
                    message:
                        '$freeLeft free post${freeLeft == 1 ? '' : 's'} remaining. '
                        'From your 3rd post onward each costs \u20B950.',
                  )
                else
                  InfoBanner(
                    icon: Icons.payments_outlined,
                    message:
                        'This post will be charged ${Money.format(fee)} at publish.',
                    color: AppColors.warning,
                    background: AppColors.pendingSoft,
                  ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Job title',
                    prefixIcon: Icon(Icons.work_outline),
                    hintText: 'e.g. Paddy harvesting crew needed',
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter a job title' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Work details',
                    alignLabelWithHint: true,
                    hintText: 'Tasks, hours, food or travel provided...',
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Describe the work' : null,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Type of work',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                SegmentedButton<JobType>(
                  segments: const [
                    ButtonSegment(
                      value: JobType.single,
                      label: Text('Single'),
                      icon: Icon(Icons.person, size: 18),
                    ),
                    ButtonSegment(
                      value: JobType.group,
                      label: Text('Group'),
                      icon: Icon(Icons.groups, size: 18),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) {
                    setState(() {
                      _type = s.first;
                      if (_type == JobType.single) _workers.text = '1';
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _workers,
                        enabled: _type == JobType.group,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Workers needed',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) return 'Enter a number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _wage,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Wage / worker',
                          prefixText: '\u20B9 ',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Enter wage';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Work date',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('d MMM yyyy').format(_workDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          fee == 0
                              ? 'Post Job (Free)'
                              : 'Pay ${Money.format(fee)} & Post',
                        ),
                ),
                if (fee > 0) ...[
                  const SizedBox(height: 12),
                  const _SecureNote(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirms the fee before checkout opens and says how payment works.
class _FeeDialog extends StatelessWidget {
  const _FeeDialog({required this.fee, required this.mode});

  final int fee;
  final PaymentMode mode;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Job posting fee'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have used your ${Money.freeJobPostLimit} free job posts. '
            'This post costs ${Money.format(fee)}.',
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pay by UPI (GPay, PhonePe, Paytm, BHIM), card or netbanking. '
            'Your job goes live as soon as payment succeeds.',
            style: TextStyle(height: 1.45, color: AppColors.textSecondary),
          ),
          if (mode == PaymentMode.demo || mode == PaymentMode.test) ...[
            const SizedBox(height: 14),
            InfoBanner(
              icon: Icons.science_outlined,
              message: mode == PaymentMode.demo
                  ? 'Demo mode: no real money will be taken.'
                  : 'Razorpay test mode: use test UPI/cards, no real money.',
              color: AppColors.warning,
              background: AppColors.pendingSoft,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(130, 44)),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Pay ${Money.format(fee)}'),
        ),
      ],
    );
  }
}

class _SecureNote extends StatelessWidget {
  const _SecureNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 15, color: AppColors.textSecondary),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Secure payment by Razorpay · UPI, cards, netbanking',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
