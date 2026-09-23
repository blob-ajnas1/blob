import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/enums.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

class CreateListingScreen extends StatefulWidget {
  final ListingChannel? channel;
  const CreateListingScreen({super.key, this.channel});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _crop = TextEditingController();
  final _desc = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  late ListingChannel _channel;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _channel = widget.channel ?? ListingChannel.toBuyers;
  }

  @override
  void dispose() {
    _crop.dispose();
    _desc.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  int get _totalPaise {
    final qty = double.tryParse(_qty.text) ?? 0;
    final price = double.tryParse(_price.text) ?? 0;
    return Money.rupeesToPaise(qty * price);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<SessionController>().user!;
    setState(() => _saving = true);

    await context.read<MarketplaceController>().createListing(
      owner: user,
      cropName: _crop.text.trim(),
      description: _desc.text.trim(),
      quantityQuintal: double.parse(_qty.text),
      pricePerQuintalPaise: Money.rupeesToPaise(double.parse(_price.text)),
      channel: _channel,
    );

    if (!mounted) return;
    showSnack(context, 'Listing published');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Listing')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _crop,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Crop / product name',
                    prefixIcon: Icon(Icons.grass),
                    hintText: 'e.g. Paddy (Sona Masuri)',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Enter the crop name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    hintText: 'Quality, grade, moisture, packaging...',
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
                        controller: _qty,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          suffixText: 'quintal',
                        ),
                        validator: (v) {
                          final q = double.tryParse(v ?? '');
                          if (q == null || q <= 0) return 'Enter quantity';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Price / quintal',
                          prefixText: '\u20B9 ',
                        ),
                        validator: (v) {
                          final p = double.tryParse(v ?? '');
                          if (p == null || p <= 0) return 'Enter price';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Who can buy this?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<ListingChannel>(
                  segments: const [
                    ButtonSegment(
                      value: ListingChannel.toBuyers,
                      label: Text('Buyers'),
                      icon: Icon(Icons.shopping_basket, size: 18),
                    ),
                    ButtonSegment(
                      value: ListingChannel.toExporters,
                      label: Text('Exporters'),
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
                const SizedBox(height: 20),
                if (_totalPaise > 0)
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
                          'Total lot value',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Money.format(_totalPaise),
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
                      : const Text('Publish Listing'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
