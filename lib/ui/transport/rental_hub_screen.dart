import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../data/models/role_subtype.dart';
import '../../data/models/vehicle.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../dashboards/dashboard_parts.dart';
import '../widgets/common.dart';
import '../widgets/place_map.dart';
import 'transport_booking_screen.dart';

/// Peer-to-peer vehicle rental, open to every member.
///
/// Two tabs rather than two screens, because the whole point of this feature
/// is that both directions belong to the same person: the farmer who rents a
/// tractor in June is the one lending out his trailer in September. Splitting
/// them into separate entry points would make lending look like a different,
/// more official activity than it is.
class RentalHubScreen extends StatefulWidget {
  /// Opens straight onto the lending tab, for entry points that promise it.
  final bool startOnLend;

  const RentalHubScreen({super.key, this.startOnLend = false});

  @override
  State<RentalHubScreen> createState() => _RentalHubScreenState();
}

class _RentalHubScreenState extends State<RentalHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.startOnLend ? 1 : 0,
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Rental'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.vpn_key_outlined), text: 'Rent'),
            Tab(icon: Icon(Icons.handshake_outlined), text: 'Lend'),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: TabBarView(
          controller: _tabs,
          children: const [_RentTab(), _LendTab()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Rent side

class _RentTab extends StatefulWidget {
  const _RentTab();

  @override
  State<_RentTab> createState() => _RentTabState();
}

class _RentTabState extends State<_RentTab> {
  RoleSubtype? _kind;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final offered = market.offeredSubtypes(VehicleCategory.rental);
    final available = market
        .rentableVehicles(kind: _kind)
        // A member's own listing is not something they can rent, and showing
        // it just makes the list look fuller than it is.
        .where((v) => v.ownerId != user.id)
        .toList();
    final mine = market
        .bookingsForUser(user.id)
        .where(
          (b) =>
              b.requesterId == user.id && b.category == VehicleCategory.rental,
        )
        .toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: InfoBanner(
            icon: Icons.vpn_key_outlined,
            message:
                'Rent by the day from rental businesses and from other '
                'members near you.',
          ),
        ),
        if (offered.isNotEmpty)
          SizedBox(
            height: 54,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              children: [
                RentalFilterChip(
                  label: 'All',
                  selected: _kind == null,
                  onTap: () => setState(() => _kind = null),
                ),
                ...offered.map(
                  (s) => RentalFilterChip(
                    label: s.label,
                    icon: s.icon,
                    selected: _kind == s,
                    onTap: () => setState(() => _kind = s),
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
              const SectionHeader('Available to Rent'),
              if (available.isEmpty)
                const EmptyCard(
                  icon: Icons.no_transfer,
                  message: 'Nothing listed for rent in this category yet.',
                )
              else
                ...available.map((v) => RentableVehicleCard(vehicle: v)),
              const SizedBox(height: 20),
              const SectionHeader('My Rentals'),
              if (mine.isEmpty)
                const EmptyCard(
                  icon: Icons.event_busy_outlined,
                  message: 'You have not rented anything yet.',
                )
              else
                ...mine.map((b) => BookingCard(booking: b)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Lend side

class _LendTab extends StatelessWidget {
  const _LendTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final mine = market.rentalsListedBy(user.id);
    final requests = market
        .bookingsForUser(user.id)
        .where(
          (b) =>
              b.providerId == user.id && b.category == VehicleCategory.rental,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        InfoBanner(
          icon: Icons.handshake_outlined,
          message:
              'Put any vehicle you own up for rent and set your own '
              'daily rate. Renters near ${user.district.isEmpty ? 'you' : user.district} '
              'will see it.',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('List a vehicle for rent'),
            onPressed: () => openListForRentSheet(context),
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader('Vehicles I Lend'),
        if (mine.isEmpty)
          EmptyCard(
            icon: Icons.vpn_key_outlined,
            message:
                'You have nothing listed for rent yet. An idle tractor, '
                'car or bike can earn while you are not using it.',
            actionLabel: 'List a vehicle',
            onAction: () => openListForRentSheet(context),
          )
        else
          ...mine.map((v) => _MyRentalCard(vehicle: v)),
        const SizedBox(height: 22),
        const SectionHeader('Rental Requests'),
        if (requests.isEmpty)
          const EmptyCard(
            icon: Icons.event_note_outlined,
            message: 'No one has asked for your vehicles yet.',
          )
        else
          ...requests.map((b) => BookingCard(booking: b, providerView: true)),
      ],
    );
  }
}

/// An owner's own listing: rate, status, and the controls to revise or
/// withdraw it. Deliberately richer than the renter-facing card, which shows
/// nothing an owner needs.
class _MyRentalCard extends StatelessWidget {
  final Vehicle vehicle;
  const _MyRentalCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketplaceController>();
    final blocked = !market.canDeleteVehicle(vehicle.id);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    vehicle.subtype?.icon ?? Icons.vpn_key,
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
                        '${vehicle.registrationNumber} · '
                        '${Money.format(vehicle.ratePaise)}/day',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill.text(
                  vehicle.available ? 'Listed' : 'Paused',
                  positive: vehicle.available,
                ),
              ],
            ),
            if (vehicle.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                vehicle.notes.trim(),
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                // Pausing rather than deleting is the usual case — the owner
                // wants the vehicle back for a week, not off the platform.
                Switch(
                  value: vehicle.available,
                  activeThumbColor: AppColors.primary,
                  onChanged: (_) => market.toggleVehicleAvailability(vehicle),
                ),
                Text(
                  vehicle.available ? 'Available' : 'Paused',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      openListForRentSheet(context, existing: vehicle),
                  child: const Text('Edit'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: blocked
                        ? AppColors.textSecondary
                        : AppColors.danger,
                  ),
                  onPressed: () => _confirmRemove(context, blocked),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, bool blocked) {
    if (blocked) {
      showSnack(
        context,
        'This vehicle has a live booking. Complete or cancel it first, '
        'or pause the listing instead.',
        error: true,
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this listing?'),
        content: Text(
          '${vehicle.vehicleType} will no longer be offered for rent. '
          'You can list it again at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep it'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async {
              final market = context.read<MarketplaceController>();
              Navigator.of(dialogContext).pop();
              final removed = await market.deleteVehicle(vehicle);
              if (!context.mounted) return;
              showSnack(
                context,
                removed
                    ? 'Listing removed'
                    : 'Could not remove — a booking is still live',
                error: !removed,
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- Renter-facing card

/// A vehicle a member can rent, from whoever listed it.
///
/// Lives here rather than in the booking screen because it shows one thing
/// that screen's card does not: whether the owner is a registered rental
/// business or a fellow member.
class RentableVehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const RentableVehicleCard({super.key, required this.vehicle});

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    vehicle.subtype?.icon ?? Icons.vpn_key,
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
                  '${Money.format(vehicle.ratePaise)}/day',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // The district is a real gazetteer place, so it opens a map.
                PlaceLink(
                  name: vehicle.district,
                  subtitle: vehicle.vehicleType,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                _OwnerKindBadge(peerListed: vehicle.peerListed),
              ],
            ),
            if (vehicle.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                vehicle.notes.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                ),
                onPressed: () => openRentalBookingSheet(context, vehicle),
                child: const Text('Rent this vehicle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Says plainly who the renter would be dealing with. Not decoration: it is
/// the difference between a licensed firm with paperwork and a neighbour with
/// a spare vehicle, and the renter should not have to guess.
class _OwnerKindBadge extends StatelessWidget {
  final bool peerListed;
  const _OwnerKindBadge({required this.peerListed});

  @override
  Widget build(BuildContext context) {
    final label = peerListed ? 'Member listing' : 'Rental business';
    final icon = peerListed ? Icons.person_outline : Icons.storefront_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared chip, reused by the rent tab. Kept public so the hub and the
/// transport booking screen cannot drift into two different-looking filters.
class RentalFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const RentalFilterChip({
    super.key,
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

// ------------------------------------------------------------ Listing sheet

void openListForRentSheet(BuildContext context, {Vehicle? existing}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ListForRentSheet(existing: existing),
  );
}

/// One form for both listing and editing. The same fields govern both, and
/// two near-identical forms would be two places for the validation to drift.
class _ListForRentSheet extends StatefulWidget {
  final Vehicle? existing;
  const _ListForRentSheet({this.existing});

  @override
  State<_ListForRentSheet> createState() => _ListForRentSheetState();
}

class _ListForRentSheetState extends State<_ListForRentSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _type;
  late final TextEditingController _reg;
  late final TextEditingController _capacity;
  late final TextEditingController _rate;
  late final TextEditingController _notes;
  late RoleSubtype _kind;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _type = TextEditingController(text: v?.vehicleType ?? '');
    _reg = TextEditingController(text: v?.registrationNumber ?? '');
    _capacity = TextEditingController(
      text: v == null ? '' : v.capacityValue.toInt().toString(),
    );
    _rate = TextEditingController(
      // Stored in paise, shown in rupees.
      text: v == null ? '' : (v.ratePaise ~/ 100).toString(),
    );
    _notes = TextEditingController(text: v?.notes ?? '');
    _kind = v?.subtype ?? RoleSubtypeX.rentalKinds.first;
  }

  @override
  void dispose() {
    _type.dispose();
    _reg.dispose();
    _capacity.dispose();
    _rate.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionController>().user!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit listing' : 'List a vehicle for rent',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isEdit
                    ? 'Update your rate or details. Renters see the change '
                          'immediately.'
                    : 'Anyone can lend a vehicle — you do not need to be a '
                          'rental business.',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('What are you lending?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RoleSubtypeX.rentalKinds
                    .map(
                      (s) => ChoiceChip(
                        avatar: Icon(
                          s.icon,
                          size: 16,
                          color: _kind == s ? Colors.white : AppColors.primary,
                        ),
                        label: Text(s.label),
                        selected: _kind == s,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _kind == s
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        onSelected: (_) => setState(() => _kind = s),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _type,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Vehicle model',
                  hintText: 'e.g. Mahindra 575 DI Tractor',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Name the vehicle so renters know what it is'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reg,
                // Not editable on an existing listing: bookings already point
                // at this vehicle, and swapping the registration would
                // silently make them refer to a different one.
                enabled: !_isEdit,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Registration number',
                  hintText: 'KA 09 C 1234',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  helperText: _isEdit
                      ? 'Registration cannot be changed after listing'
                      : null,
                ),
                validator: (v) => (v == null || v.trim().length < 4)
                    ? 'Enter the registration number'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacity,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Seats',
                        suffixText: 'seats',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '') ?? 0;
                        return n <= 0 ? 'Required' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _rate,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Rate per day',
                        prefixText: '\u20B9 ',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '') ?? 0;
                        return n <= 0 ? 'Required' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Your terms (optional)',
                  hintText:
                      'e.g. Renter fills fuel. \u20B92,000 deposit. '
                      'Within Mandya district only.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              // States the one thing the form does not ask for, so the lister
              // is not left wondering where their listing will appear.
              InfoBanner(
                icon: Icons.place_outlined,
                message: user.district.isEmpty
                    ? 'Your listing uses the district on your account.'
                    : 'Listed in ${user.district}, from your account details.',
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _busy ? null : () => _submit(user),
                child: Text(_isEdit ? 'Save changes' : 'List for rent'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AppUser user) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);

    final market = context.read<MarketplaceController>();
    final capacity = double.parse(_capacity.text.trim());
    final ratePaise = int.parse(_rate.text.trim()) * 100;

    if (_isEdit) {
      await market.updateVehicle(
        widget.existing!,
        kind: _kind,
        vehicleType: _type.text.trim(),
        capacityValue: capacity,
        ratePaise: ratePaise,
        notes: _notes.text.trim(),
      );
    } else {
      await market.listVehicleForRent(
        owner: user,
        kind: _kind,
        vehicleType: _type.text.trim(),
        registrationNumber: _reg.text.trim().toUpperCase(),
        capacityValue: capacity,
        ratePerDayPaise: ratePaise,
        notes: _notes.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    showSnack(
      context,
      _isEdit ? 'Listing updated' : 'Your vehicle is now listed for rent',
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    ),
  );
}
