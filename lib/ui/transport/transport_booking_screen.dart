import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/enums.dart';
import '../../data/models/role_subtype.dart';
import '../../data/models/vehicle.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../dashboards/dashboard_parts.dart';
import '../widgets/common.dart';
import '../widgets/location_picker.dart';

/// One booking flow that serves all three vehicle verticals — goods
/// transport, taxi rides and self-drive rentals. The category decides the
/// pricing basis (per km vs per day) and the sub-type chips filter supply.
class TransportBookingScreen extends StatefulWidget {
  final VehicleCategory category;

  const TransportBookingScreen({
    super.key,
    this.category = VehicleCategory.goods,
  });

  const TransportBookingScreen.taxi({super.key})
    : category = VehicleCategory.passenger;

  // There is deliberately no `.rental` constructor. Renting now goes through
  // RentalHubScreen, which shows both directions and discloses whether a
  // vehicle comes from a business or a member. A second, thinner route to
  // renting would hide the lending half of the feature from whoever took it.

  @override
  State<TransportBookingScreen> createState() => _TransportBookingScreenState();
}

class _TransportBookingScreenState extends State<TransportBookingScreen> {
  RoleSubtype? _filter;

  String get _title => switch (widget.category) {
    VehicleCategory.goods => 'Book Transport',
    VehicleCategory.passenger => 'Book a Ride',
    VehicleCategory.rental => 'Rent a Vehicle',
  };

  IconData get _icon => switch (widget.category) {
    VehicleCategory.goods => Icons.inventory_2_outlined,
    VehicleCategory.passenger => Icons.local_taxi_outlined,
    VehicleCategory.rental => Icons.vpn_key_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final offered = market.offeredSubtypes(widget.category);
    final available = market.availableVehicles(
      widget.category,
      subtype: _filter,
    );
    final myBookings = market
        .bookingsForUser(user.id)
        .where((b) => b.requesterId == user.id && b.category == widget.category)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: InfoBanner(
                icon: _icon,
                message: widget.category.description,
              ),
            ),
            if (offered.isNotEmpty)
              SizedBox(
                height: 54,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    ...offered.map(
                      (s) => _FilterChip(
                        label: s.label,
                        icon: s.icon,
                        selected: _filter == s,
                        onTap: () => setState(() => _filter = s),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  const SectionHeader('Available Now'),
                  if (available.isEmpty)
                    const EmptyCard(
                      icon: Icons.no_transfer,
                      message: 'Nothing available in this category yet.',
                    )
                  else
                    ...available.map((v) => _BookableVehicleCard(vehicle: v)),
                  const SizedBox(height: 20),
                  const SectionHeader('My Bookings'),
                  if (myBookings.isEmpty)
                    const EmptyCard(
                      icon: Icons.event_busy_outlined,
                      message: 'You have not booked anything yet.',
                    )
                  else
                    ...myBookings.map((b) => BookingCard(booking: b)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
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

class _BookableVehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _BookableVehicleCard({required this.vehicle});

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
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    vehicle.subtype?.icon ?? Icons.local_shipping,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.vehicleType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${vehicle.ownerName} · ${vehicle.capacityLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${Money.format(vehicle.ratePaise)}/${vehicle.rateUnit}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                ),
                onPressed: () => _openBookingSheet(context, vehicle),
                child: Text(
                  vehicle.category.isDailyRate
                      ? 'Rent this vehicle'
                      : 'Book this vehicle',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBookingSheet(BuildContext context, Vehicle vehicle) =>
      openRentalBookingSheet(context, vehicle);
}

/// Opens the booking sheet for any vehicle.
///
/// Exposed so the rental hub books through this exact flow rather than a
/// second copy of it: fare arithmetic and the ledger entry must not have two
/// implementations that can disagree.
void openRentalBookingSheet(BuildContext context, Vehicle vehicle) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _BookingSheet(vehicle: vehicle),
  );
}

class _BookingSheet extends StatefulWidget {
  final Vehicle vehicle;
  const _BookingSheet({required this.vehicle});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _pickup = TextEditingController();
  final _drop = TextEditingController();
  final _quantity = TextEditingController();
  DateTime _when = DateTime.now().add(const Duration(days: 1));

  bool get _isRental => widget.vehicle.category.isDailyRate;

  @override
  void dispose() {
    _pickup.dispose();
    _drop.dispose();
    _quantity.dispose();
    super.dispose();
  }

  int get _fare {
    final value = double.tryParse(_quantity.text) ?? 0;
    return _isRental
        ? widget.vehicle.ratePerDayPaise * value.round()
        : (widget.vehicle.ratePerKmPaise * value).round();
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              widget.vehicle.vehicleType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.vehicle.capacityLabel} · '
              '${Money.format(widget.vehicle.ratePaise)} per '
              '${widget.vehicle.rateUnit}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            // Suggests gazetteer places so the booking can be mapped later,
            // but still accepts a warehouse or landmark name a closed list
            // would not contain.
            PlaceAutocompleteField(
              controller: _pickup,
              label: _isRental ? 'Pickup branch' : 'Pickup location',
              prefixIcon: Icons.trip_origin,
            ),
            const SizedBox(height: 12),
            PlaceAutocompleteField(
              controller: _drop,
              label: _isRental ? 'Return branch' : 'Drop location',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.numberWithOptions(
                decimal: !_isRental,
              ),
              inputFormatters: [
                if (_isRental)
                  FilteringTextInputFormatter.digitsOnly
                else
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _isRental
                    ? 'Rental duration'
                    : 'Approximate distance',
                suffixText: _isRental ? 'days' : 'km',
                prefixIcon: Icon(
                  _isRental
                      ? Icons.calendar_month_outlined
                      : Icons.route_outlined,
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _when,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                );
                if (picked != null) setState(() => _when = picked);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(_isRental ? 'Start date' : 'Pickup date'),
                    const Spacer(),
                    Text(
                      DateFormat('d MMM yyyy').format(_when),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            if (_fare > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      _isRental ? 'Estimated rent' : 'Estimated fare',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Money.format(_fare),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () async {
                if (_pickup.text.trim().isEmpty ||
                    _drop.text.trim().isEmpty ||
                    _fare <= 0) {
                  showSnack(
                    context,
                    _isRental
                        ? 'Fill pickup, return and number of days'
                        : 'Fill pickup, drop and distance',
                    error: true,
                  );
                  return;
                }
                final value = double.parse(_quantity.text);
                final user = context.read<SessionController>().user!;
                await context.read<MarketplaceController>().bookVehicle(
                  vehicle: widget.vehicle,
                  requester: user,
                  pickup: _pickup.text.trim(),
                  drop: _drop.text.trim(),
                  distanceKm: _isRental ? 0 : value,
                  rentalDays: _isRental ? value.round() : 0,
                  scheduledAt: _when,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                showSnack(
                  context,
                  _isRental ? 'Rental requested' : 'Booking requested',
                );
              },
              child: Text(_isRental ? 'Confirm Rental' : 'Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
