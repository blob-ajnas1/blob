import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../admin/admin_screen.dart';
import '../investors/investor_directory_screen.dart';
import '../jobs/post_job_screen.dart';
import '../market/create_listing_screen.dart';
import '../market/market_screen.dart';
import '../payments/payments_screen.dart';
import '../property/create_property_screen.dart';
import '../property/property_market_screen.dart';
import '../transport/fleet_screen.dart';
import '../transport/rental_hub_screen.dart';
import '../transport/transport_booking_screen.dart';
import '../widgets/common.dart';
import 'dashboard_parts.dart';

/// Single entry point that renders the right dashboard for the user's role.
class RoleHome extends StatelessWidget {
  const RoleHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<SessionController>().refreshUser();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            children: [
              HomeTopBar(user: user),
              const SizedBox(height: 4),
              DashboardHeader(user: user),
              const SizedBox(height: 18),
              if (user.isPending) ...[
                const InfoBanner(
                  icon: Icons.hourglass_top,
                  message:
                      'Your account is awaiting verification by the BLOB team. '
                      'Some features stay locked until approval.',
                  color: AppColors.warning,
                  background: AppColors.pendingSoft,
                ),
                const SizedBox(height: 18),
              ],
              // The daily-challenge card was removed with the Learn tab: the
              // education track is now a separate app, so learning content no
              // longer appears on a marketplace dashboard.
              ..._bodyFor(context, user),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _bodyFor(BuildContext context, AppUser user) {
    final body = _roleBody(context, user);
    // Peer rental is appended for every role from this one place rather than
    // added to each dashboard by hand. Twelve separate edits would be twelve
    // chances to leave a role out, and "anyone can list, anyone can rent" is
    // the whole requirement — a role missing it would be a silent failure.
    if (!user.can(Permission.listVehicleForRent)) return body;
    return [...body, const SizedBox(height: 26), const _RentalPrompt()];
  }

  List<Widget> _roleBody(BuildContext context, AppUser user) {
    return switch (user.role) {
      UserRole.landowner => _landowner(context, user),
      UserRole.buyer => _buyer(context, user),
      UserRole.laborer => _laborer(context, user),
      UserRole.broker => _broker(context, user),
      UserRole.transport => _transport(context, user),
      UserRole.foreignInvestor => _investor(context, user),
      UserRole.globalExporter => _exporter(context, user),
      UserRole.taxiService => _taxi(context, user),
      UserRole.vehicleRental => _rental(context, user),
      UserRole.propertyOwner => _property(context, user),
      UserRole.admin => _admin(context, user),
      // Students are routed to EduShell by TrackRouter and never reach a
      // marketplace dashboard. Handled explicitly rather than with a default
      // so that adding a future role still fails the build until it is given
      // a real dashboard.
      UserRole.student => _student(context),
    };
  }

  /// Safety net only. Reaching this means a student was routed into the
  /// marketplace shell, which is a routing bug — say so plainly instead of
  /// rendering a blank or misleading agri dashboard.
  List<Widget> _student(BuildContext context) {
    return const [
      EmptyState(
        icon: Icons.school_outlined,
        title: 'Student account',
        message:
            'Your account uses the student app. Reopen the app to continue, '
            'or change this from Switch account type in your profile.',
      ),
    ];
  }

  // ---------------- Landowner ----------------

  List<Widget> _landowner(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final myListings = market.listingsByOwner(user.id);
    final myJobs = market.jobsByPoster(user.id);

    return [
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.add_box_outlined,
            label: 'Sell Crops',
            onTap: () => _push(context, const CreateListingScreen()),
          ),
          ActionTile(
            icon: Icons.groups_outlined,
            label: 'Hire Labour',
            onTap: () => _push(context, const PostJobScreen()),
          ),
          ActionTile(
            icon: Icons.local_shipping_outlined,
            label: 'Transport',
            onTap: () => _push(context, const TransportBookingScreen()),
          ),
          ActionTile(
            icon: Icons.trending_up,
            label: 'Investors',
            onTap: () => _push(context, const InvestorDirectoryScreen()),
          ),
          ActionTile(
            icon: Icons.agriculture_outlined,
            label: 'Lease Land',
            onTap: () => _push(context, const PropertyMarketScreen()),
          ),
          ActionTile(
            icon: Icons.local_taxi_outlined,
            label: 'Book Ride',
            onTap: () => _push(context, const TransportBookingScreen.taxi()),
          ),
          // No rental tile here: every dashboard already ends with the
          // Rent / Lend card, and a second route to the same screen just
          // crowds the grid.
          ActionTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payments',
            onTap: () => _push(context, const PaymentsScreen()),
          ),
        ],
      ),
      const SizedBox(height: 22),
      SectionHeader(
        'My Listings',
        actionLabel: myListings.isEmpty ? null : 'Add new',
        onAction: () => _push(context, const CreateListingScreen()),
      ),
      if (myListings.isEmpty)
        EmptyCard(
          icon: Icons.grass,
          message: 'You have not listed any crops yet.',
          actionLabel: 'List your first crop',
          onAction: () => _push(context, const CreateListingScreen()),
        )
      else
        MyListingsStrip(listings: myListings.take(6).toList()),
      const SizedBox(height: 22),
      const SectionHeader('My Job Posts'),
      if (myJobs.isEmpty)
        EmptyCard(
          icon: Icons.work_outline,
          message: 'No jobs posted. Your first 2 posts are free.',
          actionLabel: 'Post a job',
          onAction: () => _push(context, const PostJobScreen()),
        )
      else
        ...myJobs.take(3).map((j) => JobCard(job: j)),
    ];
  }

  // ---------------- Buyer ----------------

  List<Widget> _buyer(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final fromFarmers = market.listingsFor(ListingChannel.toBuyers);
    final myResale = market.listingsByOwner(user.id);

    return [
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.storefront_outlined,
            label: 'Buy Crops',
            onTap: () => _push(context, const MarketScreen()),
          ),
          ActionTile(
            icon: Icons.sell_outlined,
            label: 'Sell to Exporters',
            onTap: () => _push(
              context,
              const CreateListingScreen(channel: ListingChannel.toExporters),
            ),
          ),
          ActionTile(
            icon: Icons.groups_outlined,
            label: 'Hire Labour',
            onTap: () => _push(context, const PostJobScreen()),
          ),
          ActionTile(
            icon: Icons.local_shipping_outlined,
            label: 'Transport',
            onTap: () => _push(context, const TransportBookingScreen()),
          ),
        ],
      ),
      const SizedBox(height: 22),
      SectionHeader(
        'Fresh from Farmers',
        actionLabel: 'View all',
        onAction: () => _push(context, const MarketScreen()),
      ),
      if (fromFarmers.isEmpty)
        const EmptyCard(
          icon: Icons.storefront_outlined,
          message: 'No crops available right now. Check back soon.',
        )
      else
        ...fromFarmers
            .take(4)
            .map((l) => ListingCard(listing: l, showBuy: true)),
      const SizedBox(height: 22),
      const SectionHeader('My Export Listings'),
      if (myResale.isEmpty)
        EmptyCard(
          icon: Icons.public,
          message: 'Resell your purchased stock to global exporters.',
          actionLabel: 'Create export listing',
          onAction: () => _push(
            context,
            const CreateListingScreen(channel: ListingChannel.toExporters),
          ),
        )
      else
        ...myResale.take(3).map((l) => ListingCard(listing: l)),
    ];
  }

  // ---------------- Laborer ----------------

  List<Widget> _laborer(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final openJobs = market.openJobs();
    final myApps = market.applicationsByLaborer(user.id);

    return [
      WorkTypeBanner(type: user.laborerType ?? LaborerType.singleWorker),
      const SizedBox(height: 20),
      const SectionHeader('Work Available Near You'),
      if (openJobs.isEmpty)
        const EmptyCard(
          icon: Icons.work_off_outlined,
          message: 'No open jobs right now. We will show new work here.',
        )
      else
        ...openJobs.take(4).map((j) => JobCard(job: j, showApply: true)),
      const SizedBox(height: 22),
      const SectionHeader('My Applications'),
      if (myApps.isEmpty)
        const EmptyCard(
          icon: Icons.assignment_outlined,
          message: 'You have not applied to any job yet.',
        )
      else
        ...myApps.take(4).map((a) => ApplicationCard(application: a)),
    ];
  }

  // ---------------- Broker ----------------

  List<Widget> _broker(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final openDeals = market.listingsFor(ListingChannel.toBuyers);

    return [
      CommissionSummary(
        earnedPaise: market.commissionEarnedPaise(user.id),
        pendingPaise: market.pendingIncomingPaise(user.id),
      ),
      const SizedBox(height: 20),
      const SectionHeader('Deals You Can Facilitate'),
      if (openDeals.isEmpty)
        const EmptyCard(
          icon: Icons.handshake_outlined,
          message: 'No active listings to broker at the moment.',
        )
      else
        ...openDeals
            .take(5)
            .map((l) => ListingCard(listing: l, brokerMode: true)),
    ];
  }

  // ---------------- Transport ----------------

  List<Widget> _transport(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final fleet = market.vehiclesByOwner(user.id);
    final jobs = market.bookingsForUser(user.id);

    return [
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.add_road,
            label: 'Add Vehicle',
            onTap: () => _push(context, const FleetScreen()),
          ),
          ActionTile(
            icon: Icons.inventory_2_outlined,
            label: 'Goods Jobs',
            onTap: () => _push(context, const FleetScreen()),
          ),
          ActionTile(
            icon: Icons.storefront_outlined,
            label: 'Market',
            onTap: () => _push(context, const MarketScreen()),
          ),
          ActionTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Earnings',
            onTap: () => _push(context, const PaymentsScreen()),
          ),
        ],
      ),
      const SizedBox(height: 22),
      SectionHeader(
        'My Fleet',
        actionLabel: 'Manage',
        onAction: () => _push(context, const FleetScreen()),
      ),
      if (fleet.isEmpty)
        EmptyCard(
          icon: Icons.local_shipping_outlined,
          message: 'Add your first vehicle to start receiving bookings.',
          actionLabel: 'Add vehicle',
          onAction: () => _push(context, const FleetScreen()),
        )
      else
        ...fleet.take(4).map((v) => VehicleCard(vehicle: v)),
      const SizedBox(height: 22),
      const SectionHeader('Incoming Bookings'),
      if (jobs.isEmpty)
        const EmptyCard(
          icon: Icons.event_note_outlined,
          message: 'No bookings yet.',
        )
      else
        ...jobs.take(4).map((b) => BookingCard(booking: b, providerView: true)),
    ];
  }

  // ---------------- Foreign Investor ----------------

  List<Widget> _investor(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final projects = market.listingsFor(ListingChannel.toBuyers);
    final myInvestments = market.investments
        .where((i) => i.investorId == user.id)
        .toList();

    return [
      const InfoBanner(
        icon: Icons.currency_rupee,
        message:
            'All investments are made and settled in Indian Rupees (INR) only.',
      ),
      const SizedBox(height: 20),
      const SectionHeader('Projects Open for Investment'),
      if (projects.isEmpty)
        const EmptyCard(
          icon: Icons.trending_up,
          message: 'No projects available for investment right now.',
        )
      else
        ...projects
            .take(5)
            .map((l) => ListingCard(listing: l, investorMode: true)),
      const SizedBox(height: 22),
      const SectionHeader('My Investments'),
      if (myInvestments.isEmpty)
        const EmptyCard(
          icon: Icons.savings_outlined,
          message: 'You have not invested in any project yet.',
        )
      else
        ...myInvestments.map((i) => InvestmentCard(investment: i)),
    ];
  }

  // ---------------- Global Exporter ----------------

  List<Widget> _exporter(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final exportStock = market.listingsFor(ListingChannel.toExporters);

    return [
      ExporterBanner(user: user),
      const SizedBox(height: 20),
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.inventory_2_outlined,
            label: 'Export Stock',
            onTap: () => _push(context, const MarketScreen()),
          ),
          ActionTile(
            icon: Icons.local_shipping_outlined,
            label: 'Book Freight',
            onTap: () => _push(context, const TransportBookingScreen()),
          ),
          ActionTile(
            icon: Icons.receipt_long_outlined,
            label: 'Payments',
            onTap: () => _push(context, const PaymentsScreen()),
          ),
          ActionTile(
            icon: Icons.flight_takeoff,
            label: 'Expedite',
            onTap: () => showSnack(
              context,
              'Priority shipping requested for your next order.',
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      const SectionHeader('Export-Ready Stock'),
      if (exportStock.isEmpty)
        const EmptyCard(
          icon: Icons.public_off,
          message: 'No export-ready listings at the moment.',
        )
      else
        ...exportStock.map((l) => ListingCard(listing: l, showBuy: true)),
    ];
  }

  // ---------------- Taxi Service ----------------

  List<Widget> _taxi(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final fleet = market.vehiclesByOwner(user.id);
    final rides = market.bookingsForUser(user.id);

    return [
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.local_taxi_outlined,
            label: 'Add Cab',
            onTap: () => _push(context, const FleetScreen()),
          ),
          ActionTile(
            icon: Icons.event_note_outlined,
            label: 'Ride Requests',
            onTap: () => _push(context, const FleetScreen()),
          ),
          ActionTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Earnings',
            onTap: () => _push(context, const PaymentsScreen()),
          ),
          ActionTile(
            icon: Icons.home_work_outlined,
            label: 'Property',
            onTap: () => _push(context, const PropertyMarketScreen()),
          ),
        ],
      ),
      const SizedBox(height: 22),
      SectionHeader(
        'My Cabs & Buses',
        actionLabel: 'Manage',
        onAction: () => _push(context, const FleetScreen()),
      ),
      if (fleet.isEmpty)
        EmptyCard(
          icon: Icons.local_taxi_outlined,
          message:
              'Add an auto, cab or traveller bus to start receiving rides.',
          actionLabel: 'Add vehicle',
          onAction: () => _push(context, const FleetScreen()),
        )
      else
        ...fleet.take(4).map((v) => VehicleCard(vehicle: v)),
      const SizedBox(height: 22),
      const SectionHeader('Ride Requests'),
      if (rides.isEmpty)
        const EmptyCard(
          icon: Icons.route_outlined,
          message: 'No ride requests yet.',
        )
      else
        ...rides
            .take(4)
            .map((b) => BookingCard(booking: b, providerView: true)),
    ];
  }

  // ---------------- Vehicle Rental ----------------

  List<Widget> _rental(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final fleet = market.vehiclesByOwner(user.id);
    final hires = market.bookingsForUser(user.id);

    return [
      const InfoBanner(
        icon: Icons.vpn_key_outlined,
        message:
            'Self-drive rentals are billed per day. Confirm licence and '
            'deposit before releasing a vehicle.',
      ),
      const SizedBox(height: 20),
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.directions_car_filled_outlined,
            label: 'Add Vehicle',
            onTap: () => _push(context, const FleetScreen()),
          ),
          ActionTile(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Hire Requests',
            onTap: () => _push(context, const FleetScreen()),
          ),
          ActionTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Earnings',
            onTap: () => _push(context, const PaymentsScreen()),
          ),
          ActionTile(
            icon: Icons.home_work_outlined,
            label: 'Property',
            onTap: () => _push(context, const PropertyMarketScreen()),
          ),
        ],
      ),
      const SizedBox(height: 22),
      SectionHeader(
        'Rental Fleet',
        actionLabel: 'Manage',
        onAction: () => _push(context, const FleetScreen()),
      ),
      if (fleet.isEmpty)
        EmptyCard(
          icon: Icons.directions_car_outlined,
          message: 'List cars, jeeps, SUVs, bikes or scooters for daily hire.',
          actionLabel: 'Add vehicle',
          onAction: () => _push(context, const FleetScreen()),
        )
      else
        ...fleet.take(4).map((v) => VehicleCard(vehicle: v)),
      const SizedBox(height: 22),
      const SectionHeader('Hire Requests'),
      if (hires.isEmpty)
        const EmptyCard(
          icon: Icons.event_available_outlined,
          message: 'No rental requests yet.',
        )
      else
        ...hires
            .take(4)
            .map((b) => BookingCard(booking: b, providerView: true)),
    ];
  }

  // ---------------- Property & Land Rental ----------------

  List<Widget> _property(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final mine = market.propertiesByOwner(user.id);
    final enquiries = market.enquiriesForOwner(user.id);

    return [
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.add_home_work_outlined,
            label: 'List Property',
            onTap: () => _push(context, const CreatePropertyScreen()),
          ),
          ActionTile(
            icon: Icons.home_work_outlined,
            label: 'Browse',
            onTap: () => _push(context, const PropertyMarketScreen()),
          ),
          ActionTile(
            icon: Icons.mark_email_unread_outlined,
            label: 'Enquiries',
            onTap: () => _push(context, const PropertyMarketScreen()),
          ),
          ActionTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Rent Income',
            onTap: () => _push(context, const PaymentsScreen()),
          ),
        ],
      ),
      const SizedBox(height: 22),
      SectionHeader(
        'My Properties',
        actionLabel: mine.isEmpty ? null : 'Add new',
        onAction: () => _push(context, const CreatePropertyScreen()),
      ),
      if (mine.isEmpty)
        EmptyCard(
          icon: Icons.home_work_outlined,
          message:
              'List agricultural land, a commercial building or residential '
              'quarters to start receiving enquiries.',
          actionLabel: 'List your first property',
          onAction: () => _push(context, const CreatePropertyScreen()),
        )
      else
        ...mine.take(4).map((p) => PropertyCard(property: p)),
      const SizedBox(height: 22),
      const SectionHeader('Enquiries Received'),
      if (enquiries.isEmpty)
        const EmptyCard(
          icon: Icons.mark_email_unread_outlined,
          message: 'No enquiries yet. Listings appear in the Property tab.',
        )
      else
        ...enquiries
            .take(4)
            .map((e) => EnquiryCard(enquiry: e, ownerView: true)),
    ];
  }

  // ---------------- Admin ----------------

  List<Widget> _admin(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final pending = market.pendingApprovals();

    return [
      AdminSummary(
        totalUsers: market.users.length,
        pendingCount: pending.length,
        listingCount: market.listings.length,
        jobCount: market.jobs.length,
      ),
      const SizedBox(height: 20),
      SectionHeader(
        'Awaiting Verification',
        actionLabel: pending.isEmpty ? null : 'Review all',
        onAction: () => _push(context, const AdminScreen()),
      ),
      if (pending.isEmpty)
        const EmptyCard(
          icon: Icons.verified_outlined,
          message: 'No accounts awaiting approval.',
        )
      else
        ...pending.take(4).map((u) => PendingUserCard(pendingUser: u)),
    ];
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

/// Both directions of peer rental, shown on every marketplace dashboard.
///
/// It states outright that no licence or business account is needed, because
/// the reason members do not list is that they assume renting out a vehicle is
/// something only registered operators may do.
class _RentalPrompt extends StatelessWidget {
  const _RentalPrompt();

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketplaceController>();
    final user = context.watch<SessionController>().user!;
    final mine = market.rentalsListedBy(user.id);

    void open({bool lend = false}) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RentalHubScreen(startOnLend: lend),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Vehicle Rental'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mine.isEmpty
                    ? 'Rent a vehicle by the day, or earn from one you '
                          'already own. No licence or business account needed.'
                    : 'You have ${mine.length} vehicle'
                          '${mine.length == 1 ? '' : 's'} listed for rent.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.vpn_key_outlined, size: 18),
                      label: const Text('Rent'),
                      onPressed: () => open(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.handshake_outlined, size: 18),
                      label: Text(mine.isEmpty ? 'Lend' : 'Manage'),
                      onPressed: () => open(lend: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
