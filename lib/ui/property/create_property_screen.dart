import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/role_subtype.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

/// Owners list agricultural land, commercial buildings or residential
/// quarters. The area unit follows the selected property kind so land is
/// captured in acres while buildings are captured in square feet.
class CreatePropertyScreen extends StatefulWidget {
  final RoleSubtype? kind;
  const CreatePropertyScreen({super.key, this.kind});

  @override
  State<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends State<CreatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _area = TextEditingController();
  final _rent = TextEditingController();
  final _deposit = TextEditingController();
  final _locality = TextEditingController();

  late RoleSubtype _kind;
  int _leaseMonths = 11;
  DateTime _availableFrom = DateTime.now();
  bool _saving = false;

  static const List<int> _leaseOptions = [3, 6, 11, 24, 36, 60];

  @override
  void initState() {
    super.initState();
    final owner = context.read<SessionController>().user;
    _kind =
        widget.kind ??
        (RoleSubtypeX.propertyKinds.contains(owner?.subtype)
            ? owner!.subtype!
            : RoleSubtype.agricultureLandLease);
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _area.dispose();
    _rent.dispose();
    _deposit.dispose();
    _locality.dispose();
    super.dispose();
  }

  int get _rentPaise => Money.rupeesToPaise(double.tryParse(_rent.text) ?? 0);
  int get _depositPaise =>
      Money.rupeesToPaise(double.tryParse(_deposit.text) ?? 0);
  int get _moveInPaise => _rentPaise + _depositPaise;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _availableFrom,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 545)),
    );
    if (picked != null) setState(() => _availableFrom = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<SessionController>().user!;
    setState(() => _saving = true);

    await context.read<MarketplaceController>().createProperty(
      owner: user,
      kind: _kind,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      areaValue: double.parse(_area.text),
      rentPerMonthPaise: _rentPaise,
      depositPaise: _depositPaise,
      locality: _locality.text.trim(),
      leaseMonthsMin: _leaseMonths,
      availableFrom: _availableFrom,
    );

    if (!mounted) return;
    showSnack(context, 'Property listed');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unit = _kind.areaUnit;
    return Scaffold(
      appBar: const _Bar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What are you listing?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...RoleSubtypeX.propertyKinds.map(
                  (k) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _KindTile(
                      kind: k,
                      selected: _kind == k,
                      onTap: () => setState(() => _kind = k),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Listing title',
                    prefixIcon: Icon(Icons.title),
                    hintText: 'e.g. Irrigated paddy land near canal',
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter a title' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    hintText:
                        'Water source, soil, road access, power, amenities...',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Add a short description'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _area,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Area',
                          suffixText: unit,
                        ),
                        validator: (v) {
                          final a = double.tryParse(v ?? '');
                          if (a == null || a <= 0) return 'Enter area';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _locality,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Locality',
                          hintText: 'Village / area',
                        ),
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Enter locality'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rent,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Rent / month',
                          prefixText: '\u20B9 ',
                        ),
                        validator: (v) {
                          final r = double.tryParse(v ?? '');
                          if (r == null || r <= 0) return 'Enter rent';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _deposit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Deposit',
                          prefixText: '\u20B9 ',
                        ),
                        validator: (v) {
                          final d = double.tryParse(v ?? '');
                          if (d == null || d < 0) return 'Enter deposit';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Minimum lease period',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _leaseOptions
                      .map(
                        (m) => ChoiceChip(
                          label: Text(
                            m < 12
                                ? '$m months'
                                : '${(m / 12).toStringAsFixed(m % 12 == 0 ? 0 : 1)} yr',
                          ),
                          selected: _leaseMonths == m,
                          onSelected: (_) => setState(() => _leaseMonths = m),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: _leaseMonths == m
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
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
                        Icon(
                          Icons.event_available_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Available from',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${_availableFrom.day}/${_availableFrom.month}/${_availableFrom.year}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_moveInPaise > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tenant pays on agreement (1st month + deposit)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Money.format(_moveInPaise),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Publish Property'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget implements PreferredSizeWidget {
  const _Bar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const Text('List a Property'));
}

class _KindTile extends StatelessWidget {
  final RoleSubtype kind;
  final bool selected;
  final VoidCallback onTap;

  const _KindTile({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              kind.icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kind.description,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
