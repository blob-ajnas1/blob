import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../data/models/role_subtype.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../dashboards/dashboard_parts.dart';
import '../widgets/common.dart';

/// Fleet management for transport, taxi and rental providers. The role's
/// specialisation list decides which buckets are shown, so no per-role
/// branching lives in this screen.
class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  /// The vehicle bucket this provider sells from.
  static VehicleCategory categoryFor(AppUser user) => switch (user.role) {
    UserRole.taxiService => VehicleCategory.passenger,
    UserRole.vehicleRental => VehicleCategory.rental,
    _ => VehicleCategory.goods,
  };

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final category = categoryFor(user);
    final mine = market.vehiclesByOwner(user.id);
    final buckets = RoleSubtypeX.forRole(user.role);
    final incoming = market
        .bookingsForUser(user.id)
        .where((b) => b.providerId == user.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(category.isDailyRate ? 'Rental Fleet' : 'My Fleet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add vehicle',
            onPressed: () => _addVehicleSheet(context, category),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            for (final bucket in buckets) ...[
              SectionHeader(bucket.label),
              Builder(
                builder: (_) {
                  final items = mine.where((v) => v.subtype == bucket).toList();
                  if (items.isEmpty) {
                    return EmptyCard(
                      icon: bucket.icon,
                      message: 'No ${bucket.label.toLowerCase()} added yet.',
                      actionLabel: 'Add vehicle',
                      onAction: () =>
                          _addVehicleSheet(context, category, bucket),
                    );
                  }
                  return Column(
                    children: items
                        .map((v) => VehicleCard(vehicle: v))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            Builder(
              builder: (_) {
                final unbucketed = mine
                    .where((v) => v.subtype == null)
                    .toList();
                if (unbucketed.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('Other Vehicles'),
                    ...unbucketed.map((v) => VehicleCard(vehicle: v)),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            const SectionHeader('Booking Requests'),
            if (incoming.isEmpty)
              const EmptyCard(
                icon: Icons.event_note_outlined,
                message: 'No booking requests yet.',
              )
            else
              ...incoming.map(
                (b) => BookingCard(booking: b, providerView: true),
              ),
          ],
        ),
      ),
    );
  }

  void _addVehicleSheet(
    BuildContext context,
    VehicleCategory category, [
    RoleSubtype? preset,
  ]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddVehicleSheet(category: category, preset: preset),
    );
  }
}

class _AddVehicleSheet extends StatefulWidget {
  final VehicleCategory category;
  final RoleSubtype? preset;

  const _AddVehicleSheet({required this.category, this.preset});

  @override
  State<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<_AddVehicleSheet> {
  final _type = TextEditingController();
  final _reg = TextEditingController();
  final _capacity = TextEditingController();
  final _rate = TextEditingController();
  RoleSubtype? _subtype;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionController>().user!;
    _subtype =
        widget.preset ?? user.subtype ?? RoleSubtypeX.defaultFor(user.role);
  }

  @override
  void dispose() {
    _type.dispose();
    _reg.dispose();
    _capacity.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionController>().user!;
    final options = RoleSubtypeX.forRole(user.role);
    final isDaily = widget.category.isDailyRate;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Vehicle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            if (options.isNotEmpty) ...[
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options
                    .map(
                      (s) => ChoiceChip(
                        avatar: Icon(
                          s.icon,
                          size: 16,
                          color: _subtype == s
                              ? Colors.white
                              : AppColors.primary,
                        ),
                        label: Text(s.label),
                        selected: _subtype == s,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _subtype == s
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        onSelected: (_) => setState(() => _subtype = s),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _type,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Vehicle model',
                hintText: 'e.g. Tata 407 Mini Truck',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reg,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Registration number',
                hintText: 'KA 09 C 1234',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,1}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Capacity',
                      suffixText: widget.category == VehicleCategory.goods
                          ? 'tonnes'
                          : 'seats',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _rate,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: isDaily ? 'Rate per day' : 'Rate per km',
                      prefixText: '\u20B9 ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final capacity = double.tryParse(_capacity.text) ?? 0;
                final rate = int.tryParse(_rate.text) ?? 0;
                if (_type.text.trim().isEmpty ||
                    _reg.text.trim().isEmpty ||
                    capacity <= 0 ||
                    rate <= 0) {
                  showSnack(context, 'Fill all fields', error: true);
                  return;
                }
                await context.read<MarketplaceController>().addVehicle(
                  owner: user,
                  category: widget.category,
                  subtype: _subtype,
                  vehicleType: _type.text.trim(),
                  registrationNumber: _reg.text.trim(),
                  capacityValue: capacity,
                  ratePaise: rate * 100,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                showSnack(context, 'Vehicle added');
              },
              child: const Text('Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}
