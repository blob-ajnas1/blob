import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/utils/route_planner.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../data/models/farm.dart';
import '../../data/models/shop.dart';
import '../../data/models/vehicle.dart';
import '../../state/marketplace_controller.dart';
import '../jobs/post_job_screen.dart';
import '../market/create_listing_screen.dart';
import '../market/market_screen.dart';
import '../payments/payments_screen.dart';
import '../transport/fleet_screen.dart';
import '../transport/transport_booking_screen.dart';
import '../widgets/common.dart';
import 'dashboard_parts.dart';

final _when = DateFormat('EEE d MMM, h:mm a');
final _day = DateFormat('d MMM');

void _push(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

// ============================================================================
// Shared building blocks
// ============================================================================

/// Row of three headline numbers at the top of a role dashboard.
class RoleKpiRow extends StatelessWidget {
  final List<RoleKpi> items;
  const RoleKpiRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: items[i]),
        ],
      ],
    );
  }
}

class RoleKpi extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? tint;

  const RoleKpi({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final c = tint ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// White rounded card used for every dashboard section body.
class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Panel({required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  const _Tag(this.text, {required this.color, required this.background});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
    ),
  );
}

// ============================================================================
// 🌾 Landowner
// ============================================================================

class LandownerDashboard extends StatelessWidget {
  final AppUser user;
  const LandownerDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketplaceController>();
    final plots = market.plotsByOwner(user.id);
    final now = DateTime.now();
    final acres = plots.fold<double>(0, (s, p) => s + p.acres);
    final growing = plots.where((p) => !p.isFallow).toList();
    final labour = market.laborersIn(user.district);
    final trucks = market.availableVehicles(VehicleCategory.goods)
      ..removeWhere((v) => v.ownerId == user.id);
    final localTrucks = trucks
        .where((v) => v.district.toLowerCase() == user.district.toLowerCase())
        .toList();
    final myBookings = market
        .bookingsForUser(user.id)
        .where(
          (b) =>
              b.requesterId == user.id &&
              b.category == VehicleCategory.goods &&
              b.status != BookingStatus.delivered &&
              b.status != BookingStatus.cancelled,
        )
        .toList();

    String acresLabel(double a) =>
        a == a.roundToDouble() ? a.toStringAsFixed(0) : a.toStringAsFixed(1);

    return Column(
      key: const Key('dashboard-landowner'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoleKpiRow(
          items: [
            RoleKpi(
              icon: Icons.landscape_outlined,
              value: '${acresLabel(acres)} ac',
              label: '${plots.length} plot${plots.length == 1 ? '' : 's'}',
            ),
            RoleKpi(
              icon: Icons.eco_outlined,
              value: '${growing.length}',
              label: 'Crops growing',
            ),
            RoleKpi(
              icon: Icons.groups_outlined,
              value: '${labour.length}',
              label: 'Workers nearby',
            ),
          ],
        ),
        const SizedBox(height: 16),
        QuickActionsGrid(
          actions: [
            ActionTile(
              icon: Icons.add_location_alt_outlined,
              label: 'Add Plot',
              onTap: () => _showAddPlot(context, user),
            ),
            ActionTile(
              icon: Icons.groups_outlined,
              label: 'Hire Labour',
              onTap: () => _push(context, const PostJobScreen()),
            ),
            ActionTile(
              icon: Icons.local_shipping_outlined,
              label: 'Book Truck',
              onTap: () => _push(context, const TransportBookingScreen()),
            ),
            ActionTile(
              icon: Icons.add_box_outlined,
              label: 'Sell Crops',
              onTap: () => _push(context, const CreateListingScreen()),
            ),
          ],
        ),

        // ---- Land plots ----
        const SizedBox(height: 22),
        SectionHeader(
          'My Land',
          actionLabel: 'Add plot',
          onAction: () => _showAddPlot(context, user),
        ),
        if (plots.isEmpty)
          EmptyCard(
            icon: Icons.landscape_outlined,
            message: 'Add your fields to track crops and harvest dates.',
            actionLabel: 'Add first plot',
            onAction: () => _showAddPlot(context, user),
          )
        else
          for (final p in plots) _PlotCard(plot: p, now: now),

        // ---- Crop management ----
        const SizedBox(height: 22),
        const SectionHeader('Crop Calendar'),
        if (growing.isEmpty)
          const EmptyCard(
            icon: Icons.eco_outlined,
            message: 'Nothing sown right now. Tap "Sow" on a plot to start.',
          )
        else
          _Panel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (final p
                    in (growing..sort(
                      (a, b) =>
                          a.expectedHarvest!.compareTo(b.expectedHarvest!),
                    )))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(Icons.eco, color: AppColors.primary),
                    ),
                    title: Text(
                      '${p.crop} · ${p.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Harvest ~${_day.format(p.expectedHarvest!)} · '
                      '${p.stageAt(now)}',
                    ),
                    trailing: Text(
                      p.daysToHarvest(now) == 0
                          ? 'Now'
                          : '${p.daysToHarvest(now)}d',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: p.daysToHarvest(now)! <= 14
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // ---- Farm labour availability ----
        const SizedBox(height: 22),
        SectionHeader(
          'Labour Available in ${user.district}',
          actionLabel: 'Post job',
          onAction: () => _push(context, const PostJobScreen()),
        ),
        if (labour.isEmpty)
          EmptyCard(
            icon: Icons.groups_outlined,
            message: 'No workers registered in ${user.district} yet.',
            actionLabel: 'Post a job anyway',
            onAction: () => _push(context, const PostJobScreen()),
          )
        else
          _Panel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (final w in labour.take(4))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentSoft,
                      child: Icon(
                        w.laborerType == LaborerType.groupWork
                            ? Icons.groups
                            : Icons.person,
                        color: AppColors.warning,
                      ),
                    ),
                    title: Text(
                      w.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${w.laborerType?.label ?? 'Worker'} · '
                      '${w.city?.isNotEmpty == true ? w.city : w.district}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Call ${w.name}',
                      icon: Icon(Icons.call_outlined, color: AppColors.primary),
                      onPressed: () =>
                          launchUrl(Uri(scheme: 'tel', path: w.phone)),
                    ),
                  ),
              ],
            ),
          ),

        // ---- Truck / driver booking ----
        const SizedBox(height: 22),
        SectionHeader(
          'Trucks & Drivers',
          actionLabel: 'Book',
          onAction: () => _push(context, const TransportBookingScreen()),
        ),
        if (myBookings.isNotEmpty) ...[
          for (final b in myBookings.take(2))
            BookingCard(booking: b, providerView: false),
          const SizedBox(height: 4),
        ],
        _Panel(
          child: Row(
            children: [
              Icon(Icons.local_shipping, color: AppColors.primary, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localTrucks.isNotEmpty
                      ? '${localTrucks.length} truck'
                            '${localTrucks.length == 1 ? '' : 's'} free in '
                            '${user.district} now · ${trucks.length} statewide'
                      : '${trucks.length} trucks available to book',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _push(context, const TransportBookingScreen()),
                child: const Text('Book'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlotCard extends StatelessWidget {
  final FarmPlot plot;
  final DateTime now;
  const _PlotCard({required this.plot, required this.now});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    final progress = plot.progressAt(now);
    final ready = progress != null && progress >= 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plot.name,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _Tag(
                  plot.isFallow ? 'Fallow' : plot.crop!,
                  color: plot.isFallow
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  background: plot.isFallow
                      ? AppColors.background
                      : AppColors.primarySoft,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${plot.acres} acres · ${plot.village} · ${plot.soil} · '
              '${plot.irrigation}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  color: ready ? AppColors.warning : AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${plot.stageAt(now)} · sown ${_day.format(plot.sownOn!)}'
                ' · harvest ~${_day.format(plot.expectedHarvest!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            // Secondary action: a compact text button so the plot's details,
            // not the button, are what the eye lands on.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: plot.isFallow
                  ? TextButton.icon(
                      icon: const Icon(Icons.grass, size: 18),
                      label: const Text('Sow crop'),
                      onPressed: () => _showSow(context, plot),
                    )
                  : TextButton.icon(
                      icon: const Icon(Icons.agriculture, size: 18),
                      label: Text(ready ? 'Mark harvested' : 'Harvested'),
                      onPressed: () async {
                        await market.harvestPlot(plot);
                        if (context.mounted) {
                          showSnack(
                            context,
                            '${plot.crop} harvested on ${plot.name}',
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Common Karnataka crops with typical sowing-to-harvest days.
const _cropDurations = <String, int>{
  'Paddy': 120,
  'Ragi': 110,
  'Sugarcane': 330,
  'Maize': 100,
  'Groundnut': 110,
  'Tomato': 75,
  'Banana': 300,
  'Coconut seedlings': 365,
};

Future<void> _showSow(BuildContext context, FarmPlot plot) async {
  final market = context.read<MarketplaceController>();
  final picked = await showModalBottomSheet<MapEntry<String, int>>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            'Sow on ${plot.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final e in _cropDurations.entries)
            ListTile(
              leading: Icon(Icons.eco_outlined, color: AppColors.primary),
              title: Text(e.key),
              subtitle: Text('About ${e.value} days to harvest'),
              onTap: () => Navigator.of(sheet).pop(e),
            ),
        ],
      ),
    ),
  );
  if (picked == null) return;
  await market.sowPlot(plot, picked.key, picked.value);
  if (context.mounted) {
    showSnack(context, '${picked.key} sown on ${plot.name}');
  }
}

Future<void> _showAddPlot(BuildContext context, AppUser user) async {
  final market = context.read<MarketplaceController>();
  final name = TextEditingController();
  final acres = TextEditingController();
  final village = TextEditingController(text: user.city ?? '');
  var soil = 'Red loam';
  var water = 'Borewell';
  final formKey = GlobalKey<FormState>();

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
      child: StatefulBuilder(
        builder: (sheet, setState) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add a plot',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Plot name or survey no.',
                    hintText: 'e.g. Survey 112/3',
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: acres,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Area (acres)'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return n == null || n <= 0 ? 'Enter acres' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: village,
                  decoration: const InputDecoration(labelText: 'Village'),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter village' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: soil,
                  decoration: const InputDecoration(labelText: 'Soil'),
                  items:
                      const ['Red loam', 'Black clay', 'Sandy loam', 'Laterite']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => soil = v ?? soil),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: water,
                  decoration: const InputDecoration(labelText: 'Water source'),
                  items: const ['Borewell', 'Canal', 'Tank', 'Rain-fed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => water = v ?? water),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(sheet).pop(true);
                    }
                  },
                  child: const Text('Save plot'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (saved == true) {
    await market.addPlot(
      owner: user,
      name: name.text,
      acres: double.parse(acres.text),
      village: village.text,
      soil: soil,
      irrigation: water,
    );
    if (context.mounted) showSnack(context, 'Plot added');
  }
  name.dispose();
  acres.dispose();
  village.dispose();
}

// ============================================================================
// 🚛 Driver
// ============================================================================

class DriverDashboard extends StatelessWidget {
  final AppUser user;
  const DriverDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketplaceController>();
    final requests = market.tripRequestsFor(user.id);
    final active = market.activeHaulsFor(user.id);
    final completed = market.completedTripsFor(user.id);
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);
    final week = market.tripEarningsPaise(user.id, since: weekStart);
    final month = market.tripEarningsPaise(user.id, since: monthStart);
    final enRoute = active
        .where((b) => b.status == BookingStatus.enRoute)
        .toList();

    final route = RoutePlanner.plan(
      user.city?.isNotEmpty == true ? user.city! : user.district,
      [
        for (final b in active)
          RouteJob(
            id: b.id,
            pickup: b.pickup,
            drop: b.drop,
            who: b.requesterName,
          ),
      ],
    );

    return Column(
      key: const Key('dashboard-driver'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoleKpiRow(
          items: [
            RoleKpi(
              icon: Icons.notifications_active_outlined,
              value: '${requests.length}',
              label: 'Trip requests',
              tint: requests.isEmpty ? null : AppColors.warning,
            ),
            RoleKpi(
              icon: Icons.local_shipping_outlined,
              value: '${active.length}',
              label: 'Active hauls',
            ),
            RoleKpi(
              icon: Icons.currency_rupee,
              value: Money.compact(week),
              label: 'Earned this week',
            ),
          ],
        ),
        const SizedBox(height: 16),
        QuickActionsGrid(
          actions: [
            ActionTile(
              icon: Icons.add_road,
              label: 'My Vehicles',
              onTap: () => _push(context, const FleetScreen()),
            ),
            ActionTile(
              icon: Icons.storefront_outlined,
              label: 'Find Loads',
              onTap: () => _push(context, const MarketScreen()),
            ),
            ActionTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payments',
              onTap: () => _push(context, const PaymentsScreen()),
            ),
          ],
        ),

        // ---- Active haul status ----
        const SizedBox(height: 22),
        const SectionHeader('Active Haul'),
        if (active.isEmpty)
          const EmptyCard(
            icon: Icons.local_shipping_outlined,
            message: 'No haul in progress. Accept a trip request below.',
          )
        else
          for (final b in active) _HaulCard(booking: b),

        // ---- Optimal delivery route ----
        const SizedBox(height: 22),
        const SectionHeader('Today\'s Route'),
        if (route.isEmpty)
          EmptyCard(
            icon: Icons.alt_route,
            message: active.isEmpty
                ? 'Accept trips to plan a route through all your stops.'
                : 'Could not map these stops. Check the place names.',
          )
        else
          _RoutePanel(route: route),

        // ---- Available trips ----
        const SizedBox(height: 22),
        SectionHeader('Available Trips (${requests.length})'),
        if (requests.isEmpty)
          const EmptyCard(
            icon: Icons.inbox_outlined,
            message: 'No new trip requests. They will appear here.',
          )
        else
          for (final b in requests) _TripRequestCard(booking: b),

        // ---- Trip earnings ----
        const SizedBox(height: 22),
        SectionHeader(
          'Trip Earnings',
          actionLabel: 'All payments',
          onAction: () => _push(context, const PaymentsScreen()),
        ),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _EarningFigure(label: 'This week', paise: week),
                  ),
                  Expanded(
                    child: _EarningFigure(label: 'This month', paise: month),
                  ),
                  Expanded(
                    child: _EarningFigure(
                      label: 'Trips done',
                      text: '${completed.length}',
                    ),
                  ),
                ],
              ),
              if (enRoute.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '+ ${Money.format(enRoute.fold(0, (s, b) => s + b.farePaise))} '
                  'on delivery of the haul in progress',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
              if (completed.isNotEmpty) ...[
                const Divider(height: 22),
                for (final b in completed.take(3))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${b.pickup} → ${b.drop}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          _day.format(b.scheduledAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          Money.format(b.farePaise),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EarningFigure extends StatelessWidget {
  final String label;
  final int? paise;
  final String? text;
  const _EarningFigure({required this.label, this.paise, this.text});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text ?? Money.format(paise ?? 0),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
}

/// Status ladder for a haul: Accepted → On the way → Delivered.
class _HaulCard extends StatelessWidget {
  final VehicleBooking booking;
  const _HaulCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    final moving = booking.status == BookingStatus.enRoute;
    const steps = ['Accepted', 'On the way', 'Delivered'];
    final at = moving ? 1 : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${booking.pickup} → ${booking.drop}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _Tag(
                  moving ? 'ON THE WAY' : 'ACCEPTED',
                  color: moving ? AppColors.warning : AppColors.primary,
                  background: moving
                      ? AppColors.pendingSoft
                      : AppColors.primarySoft,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${booking.requesterName} · ${booking.quantityLabel} · '
              '${Money.format(booking.farePaise)} · '
              '${_when.format(booking.scheduledAt)}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i <= at ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  Column(
                    children: [
                      Icon(
                        i < at
                            ? Icons.check_circle
                            : i == at
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: i <= at ? AppColors.primary : AppColors.border,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i == at
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: i <= at
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(moving ? Icons.flag : Icons.play_arrow),
                label: Text(moving ? 'Mark delivered' : 'Start trip'),
                onPressed: () async {
                  await market.updateBookingStatus(
                    booking,
                    moving ? BookingStatus.delivered : BookingStatus.enRoute,
                  );
                  if (context.mounted) {
                    showSnack(
                      context,
                      moving
                          ? 'Delivered · ${Money.format(booking.farePaise)} '
                                'added to earnings'
                          : 'Trip started',
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripRequestCard extends StatelessWidget {
  final VehicleBooking booking;
  const _TripRequestCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${booking.pickup} → ${booking.drop}',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  Money.format(booking.farePaise),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${booking.requesterName} · ${booking.quantityLabel} · '
              '${_when.format(booking.scheduledAt)}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => market.updateBookingStatus(
                      booking,
                      BookingStatus.cancelled,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await market.updateBookingStatus(
                        booking,
                        BookingStatus.confirmed,
                      );
                      if (context.mounted) {
                        showSnack(context, 'Trip accepted · added to route');
                      }
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePanel extends StatelessWidget {
  final PlannedRoute route;
  const _RoutePanel({required this.route});

  @override
  Widget build(BuildContext context) {
    final uri = RoutePlanner.directionsUri(route);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${route.stops.length} stops · about '
            '${route.totalKm.toStringAsFixed(0)} km (straight-line)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < route.stops.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: route.stops[i].place,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: '  ${route.stops[i].label}'),
                        ],
                      ),
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                  Text(
                    '${route.stops[i].legKm.toStringAsFixed(0)} km',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          if (route.unplaced.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${route.unplaced.length} trip(s) left out — place not '
                'found on the map.',
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ),
          if (uri != null) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Navigate in Maps'),
              onPressed: () =>
                  launchUrl(uri, mode: LaunchMode.externalApplication),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 🛒 Shopkeeper
// ============================================================================

class ShopkeeperDashboard extends StatelessWidget {
  final AppUser user;
  const ShopkeeperDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketplaceController>();
    final items = market.shopItems(user.id);
    final orders = market.shopOrders(user.id);
    final open = orders.where((o) => o.status.isOpen).toList();
    final reorder = items.where((i) => i.isOut || i.isLow).toList();
    final today = market.shopSalesTodayPaise(user.id);
    final dues = market.shopDuesPaise(user.id);
    final suppliers = <String, List<ShopItem>>{};
    for (final i in reorder) {
      suppliers.putIfAbsent(i.supplier, () => []).add(i);
    }
    final paidRecent = orders.where((o) => o.paid).take(4).toList();
    final unpaid = orders
        .where((o) => !o.paid && o.status != ShopOrderStatus.cancelled)
        .toList();

    return Column(
      key: const Key('dashboard-shopkeeper'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoleKpiRow(
          items: [
            RoleKpi(
              icon: Icons.receipt_long_outlined,
              value: '${open.length}',
              label: 'Orders to fill',
              tint: open.isEmpty ? null : AppColors.warning,
            ),
            RoleKpi(
              icon: Icons.inventory_2_outlined,
              value: '${reorder.length}',
              label: 'Items to reorder',
              tint: reorder.isEmpty ? null : AppColors.danger,
            ),
            RoleKpi(
              icon: Icons.currency_rupee,
              value: Money.compact(today),
              label: 'Sales today',
            ),
          ],
        ),
        const SizedBox(height: 16),
        QuickActionsGrid(
          actions: [
            ActionTile(
              icon: Icons.add_shopping_cart,
              label: 'Add Item',
              onTap: () => _showAddItem(context, user),
            ),
            ActionTile(
              icon: Icons.storefront_outlined,
              label: 'Buy Stock',
              onTap: () => _push(context, const MarketScreen()),
            ),
            ActionTile(
              icon: Icons.local_shipping_outlined,
              label: 'Book Delivery',
              onTap: () => _push(context, const TransportBookingScreen()),
            ),
            ActionTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payments',
              onTap: () => _push(context, const PaymentsScreen()),
            ),
          ],
        ),

        // ---- Incoming customer orders ----
        const SizedBox(height: 22),
        SectionHeader('Customer Orders (${open.length} open)'),
        if (open.isEmpty)
          const EmptyCard(
            icon: Icons.receipt_long_outlined,
            message: 'No open orders. New orders show up here.',
          )
        else
          for (final o in open) _OrderCard(order: o),

        // ---- Store inventory ----
        const SizedBox(height: 22),
        SectionHeader(
          'Store Inventory (${items.length})',
          actionLabel: 'Add item',
          onAction: () => _showAddItem(context, user),
        ),
        if (items.isEmpty)
          EmptyCard(
            icon: Icons.inventory_2_outlined,
            message: 'Add the items you sell to keep track of stock.',
            actionLabel: 'Add first item',
            onAction: () => _showAddItem(context, user),
          )
        else
          _Panel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [for (final i in items) _StockRow(item: i)],
            ),
          ),

        // ---- Supplier stock ----
        const SizedBox(height: 22),
        SectionHeader(
          'Reorder from Suppliers',
          actionLabel: 'Market',
          onAction: () => _push(context, const MarketScreen()),
        ),
        if (suppliers.isEmpty)
          const EmptyCard(
            icon: Icons.check_circle_outline,
            message: 'Everything is well stocked.',
          )
        else
          for (final e in suppliers.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Panel(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.accentSoft,
                      child: const Icon(
                        Icons.warehouse_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.value
                                .map(
                                  (i) =>
                                      '${i.name} (${i.isOut ? 'out' : i.quantityLabel})',
                                )
                                .join(', '),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

        // ---- Payment records ----
        const SizedBox(height: 22),
        SectionHeader(
          'Payment Records',
          actionLabel: 'All',
          onAction: () => _push(context, const PaymentsScreen()),
        ),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _EarningFigure(
                      label: 'Collected today',
                      paise: today,
                    ),
                  ),
                  Expanded(
                    child: _EarningFigure(label: 'Customers owe', paise: dues),
                  ),
                ],
              ),
              if (unpaid.isNotEmpty) ...[
                const Divider(height: 22),
                const Text(
                  'Unpaid',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
                for (final o in unpaid) _PaymentRow(order: o),
              ],
              if (paidRecent.isNotEmpty) ...[
                const Divider(height: 22),
                const Text(
                  'Recent payments',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                for (final o in paidRecent) _PaymentRow(order: o),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ShopOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    final isNew = order.status == ShopOrderStatus.received;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _Tag(
                  order.status.label.toUpperCase(),
                  color: isNew ? AppColors.warning : AppColors.primary,
                  background: isNew
                      ? AppColors.pendingSoft
                      : AppColors.primarySoft,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(order.itemsSummary, style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 2),
            Text(
              '${Money.format(order.totalPaise)} · '
              '${order.paid ? 'Paid' : 'Not paid'} · '
              '${DateFormat('h:mm a').format(order.createdAt)}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton.outlined(
                  tooltip: 'Call ${order.customerName}',
                  icon: const Icon(Icons.call_outlined),
                  onPressed: () =>
                      launchUrl(Uri(scheme: 'tel', path: order.customerPhone)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => market.advanceOrder(order),
                    child: Text(order.status.nextActionLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final ShopItem item;
  const _StockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    final step = item.unit == 'kg' || item.unit == 'litre' ? 5.0 : 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${Money.format(item.pricePaise)}/${item.unit} · '
                  '${item.supplier}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (item.isOut)
            const _Tag(
              'OUT',
              color: AppColors.danger,
              background: AppColors.dangerSoft,
            )
          else if (item.isLow)
            const _Tag(
              'LOW',
              color: AppColors.warning,
              background: AppColors.pendingSoft,
            ),
          IconButton(
            tooltip: 'Remove $step ${item.unit}',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: item.isOut
                ? null
                : () => market.adjustStock(item, -step),
          ),
          SizedBox(
            width: 62,
            child: Text(
              item.quantityLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Add $step ${item.unit}',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => market.adjustStock(item, step),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final ShopOrder order;
  const _PaymentRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              order.customerName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            _day.format(order.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Money.format(order.totalPaise),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (!order.paid) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: () async {
                await market.markOrderPaid(order);
                if (context.mounted) {
                  showSnack(
                    context,
                    '${Money.format(order.totalPaise)} received from '
                    '${order.customerName}',
                  );
                }
              },
              child: const Text('Received'),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showAddItem(BuildContext context, AppUser user) async {
  final market = context.read<MarketplaceController>();
  final name = TextEditingController();
  final qty = TextEditingController();
  final reorder = TextEditingController(text: '10');
  final price = TextEditingController();
  final supplier = TextEditingController();
  var unit = 'kg';
  final formKey = GlobalKey<FormState>();

  String? number(String? v) {
    final n = double.tryParse(v ?? '');
    return n == null || n < 0 ? 'Enter a number' : null;
  }

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
      child: StatefulBuilder(
        builder: (sheet, setState) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add stock item',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Item name'),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: qty,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'In stock',
                        ),
                        validator: number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: const ['kg', 'litre', 'packet', 'bag', 'piece']
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => unit = v ?? unit),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price / unit',
                          prefixText: '\u20B9 ',
                        ),
                        validator: number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: reorder,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Reorder below',
                        ),
                        validator: number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: supplier,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter supplier' : null,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(sheet).pop(true);
                    }
                  },
                  child: const Text('Save item'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (saved == true) {
    await market.addShopItem(
      shop: user,
      name: name.text,
      unit: unit,
      quantity: double.parse(qty.text),
      reorderLevel: double.parse(reorder.text),
      pricePaise: Money.rupeesToPaise(double.parse(price.text)),
      supplier: supplier.text,
    );
    if (context.mounted) showSnack(context, 'Item added to inventory');
  }
  for (final c in [name, qty, reorder, price, supplier]) {
    c.dispose();
  }
}
