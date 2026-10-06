import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/money.dart';
import '../data/local_db.dart';
import '../data/models/app_user.dart';
import '../data/models/enums.dart';
import '../data/models/job.dart';
import '../data/models/ledger.dart';
import '../data/models/listing.dart';
import '../data/models/property.dart';
import '../data/models/role_subtype.dart';
import '../data/models/vehicle.dart';
import '../services/payment_gateway.dart';

class JobPostOutcome {
  final bool success;
  final String message;
  final int feeChargedPaise;

  /// True when the user backed out of checkout — not an error to shout about.
  final bool cancelled;

  const JobPostOutcome({
    required this.success,
    required this.message,
    this.feeChargedPaise = 0,
    this.cancelled = false,
  });
}

/// Central marketplace store: listings, jobs, applications, ledger,
/// vehicles, bookings and investments.
class MarketplaceController extends ChangeNotifier {
  MarketplaceController({PaymentGateway? gateway})
    : _gateway = gateway ?? PaymentGateway.fromEnvironment();

  final PaymentGateway _gateway;

  PaymentMode get paymentMode => _gateway.mode;

  final _db = LocalDb.instance;
  final _uuid = const Uuid();

  // ---------------- Reads ----------------

  List<AppUser> get users =>
      _db.all(LocalDb.users).map(AppUser.fromMap).toList();

  List<Listing> get listings {
    final items = _db.all(LocalDb.listings).map(Listing.fromMap).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<Job> get jobs {
    final items = _db.all(LocalDb.jobs).map(Job.fromMap).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<JobApplication> get applications =>
      _db.all(LocalDb.applications).map(JobApplication.fromMap).toList();

  List<LedgerEntry> get ledger {
    final items = _db.all(LocalDb.ledger).map(LedgerEntry.fromMap).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<Vehicle> get vehicles =>
      _db.all(LocalDb.vehicles).map(Vehicle.fromMap).toList();

  List<VehicleBooking> get bookings {
    final items = _db
        .all(LocalDb.bookings)
        .map(VehicleBooking.fromMap)
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<Investment> get investments =>
      _db.all(LocalDb.investments).map(Investment.fromMap).toList();

  List<PropertyListing> get properties {
    final items = _db
        .all(LocalDb.properties)
        .map(PropertyListing.fromMap)
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<PropertyEnquiry> get enquiries {
    final items = _db
        .all(LocalDb.enquiries)
        .map(PropertyEnquiry.fromMap)
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  // ---------------- Scoped queries (simple filters, sorted in memory) ----

  List<Listing> listingsFor(ListingChannel channel) => listings
      .where((l) => l.channel == channel && l.status == ListingStatus.active)
      .toList();

  List<Listing> listingsByOwner(String ownerId) =>
      listings.where((l) => l.ownerId == ownerId).toList();

  List<Job> jobsByPoster(String posterId) =>
      jobs.where((j) => j.posterId == posterId).toList();

  List<Job> openJobs() =>
      jobs.where((j) => j.status == JobStatus.open).toList();

  List<JobApplication> applicationsForJob(String jobId) =>
      applications.where((a) => a.jobId == jobId).toList();

  List<JobApplication> applicationsByLaborer(String laborerId) {
    final items = applications.where((a) => a.laborerId == laborerId).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<Vehicle> vehiclesByOwner(String ownerId) =>
      vehicles.where((v) => v.ownerId == ownerId).toList();

  List<Vehicle> availableVehicles(
    VehicleCategory category, {
    RoleSubtype? subtype,
  }) => vehicles
      .where(
        (v) =>
            v.category == category &&
            v.available &&
            (subtype == null || v.subtype == subtype),
      )
      .toList();

  /// Distinct specialisations that currently have stock in a category.
  List<RoleSubtype> offeredSubtypes(VehicleCategory category) {
    final seen = <RoleSubtype>[];
    for (final v in availableVehicles(category)) {
      final s = v.subtype;
      if (s != null && !seen.contains(s)) seen.add(s);
    }
    seen.sort((a, b) => a.index.compareTo(b.index));
    return seen;
  }

  List<PropertyListing> propertiesByOwner(String ownerId) =>
      properties.where((p) => p.ownerId == ownerId).toList();

  List<PropertyListing> activeProperties({RoleSubtype? kind}) => properties
      .where(
        (p) =>
            p.status == ListingStatus.active &&
            (kind == null || p.kind == kind),
      )
      .toList();

  List<RoleSubtype> get offeredPropertyKinds {
    final seen = <RoleSubtype>[];
    for (final p in activeProperties()) {
      if (!seen.contains(p.kind)) seen.add(p.kind);
    }
    seen.sort((a, b) => a.index.compareTo(b.index));
    return seen;
  }

  List<PropertyEnquiry> enquiriesForOwner(String ownerId) =>
      enquiries.where((e) => e.ownerId == ownerId).toList();

  List<PropertyEnquiry> enquiriesBySeeker(String seekerId) =>
      enquiries.where((e) => e.seekerId == seekerId).toList();

  List<VehicleBooking> bookingsForUser(String userId) => bookings
      .where((b) => b.requesterId == userId || b.providerId == userId)
      .toList();

  List<LedgerEntry> ledgerFor(String userId) =>
      ledger.where((e) => e.payerId == userId || e.payeeId == userId).toList();

  int pendingIncomingPaise(String userId) => ledger
      .where((e) => e.payeeId == userId && e.status == PaymentStatus.pending)
      .fold(0, (sum, e) => sum + e.amountPaise);

  int clearedIncomingPaise(String userId) => ledger
      .where((e) => e.payeeId == userId && e.status == PaymentStatus.cleared)
      .fold(0, (sum, e) => sum + e.amountPaise);

  int pendingOutgoingPaise(String userId) => ledger
      .where((e) => e.payerId == userId && e.status == PaymentStatus.pending)
      .fold(0, (sum, e) => sum + e.amountPaise);

  int clearedOutgoingPaise(String userId) => ledger
      .where((e) => e.payerId == userId && e.status == PaymentStatus.cleared)
      .fold(0, (sum, e) => sum + e.amountPaise);

  int commissionEarnedPaise(String brokerId) => ledger
      .where(
        (e) => e.payeeId == brokerId && e.type == LedgerType.brokerCommission,
      )
      .fold(0, (sum, e) => sum + e.amountPaise);

  List<AppUser> pendingApprovals() => users
      .where((u) => u.verificationStatus == VerificationStatus.pending)
      .toList();

  List<AppUser> usersByRole(UserRole role) =>
      users.where((u) => u.role == role && u.isApproved).toList();

  // ---------------- Listings ----------------

  Future<Listing> createListing({
    required AppUser owner,
    required String cropName,
    required String description,
    required double quantityQuintal,
    required int pricePerQuintalPaise,
    required ListingChannel channel,
  }) async {
    final listing = Listing(
      id: _uuid.v4(),
      ownerId: owner.id,
      ownerName: owner.name,
      ownerRole: owner.role,
      cropName: cropName,
      description: description,
      quantityQuintal: quantityQuintal,
      pricePerQuintalPaise: pricePerQuintalPaise,
      district: owner.district,
      channel: channel,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.listings, listing.id, listing.toMap());
    notifyListeners();
    return listing;
  }

  Future<void> updateListingStatus(
    Listing listing,
    ListingStatus status,
  ) async {
    final updated = listing.copyWith(status: status);
    await _db.put(LocalDb.listings, updated.id, updated.toMap());
    notifyListeners();
  }

  /// Purchase a listing. Creates a pending ledger entry for the seller and,
  /// when a broker facilitated the deal, an automatic commission entry.
  Future<void> purchaseListing({
    required Listing listing,
    required AppUser buyer,
    AppUser? broker,
  }) async {
    await _addLedger(
      payerId: buyer.id,
      payerName: buyer.name,
      payeeId: listing.ownerId,
      payeeName: listing.ownerName,
      amountPaise: listing.totalPaise,
      type: LedgerType.productPurchase,
      reference: listing.id,
      note: '${listing.cropName} · ${listing.quantityQuintal} quintal',
    );

    if (broker != null) {
      final commission = Money.brokerCommissionOn(listing.totalPaise);
      await _addLedger(
        payerId: buyer.id,
        payerName: buyer.name,
        payeeId: broker.id,
        payeeName: broker.name,
        amountPaise: commission,
        type: LedgerType.brokerCommission,
        reference: listing.id,
        note: 'Commission 2.5% · ${listing.cropName}',
      );
    }

    await updateListingStatus(listing, ListingStatus.sold);
  }

  // ---------------- Jobs & monetization ----------------

  /// First 2 posts per user are free; ₹50 from the 3rd onward.
  int postingFeeFor(AppUser user) =>
      !Money.jobPostingFeesEnabled ||
          user.freeJobPostsUsed < Money.freeJobPostLimit
      ? 0
      : Money.jobPostingFeePaise;

  int freePostsRemaining(AppUser user) =>
      (Money.freeJobPostLimit - user.freeJobPostsUsed).clamp(
        0,
        Money.freeJobPostLimit,
      );

  Future<JobPostOutcome> postJob({
    required AppUser poster,
    required String title,
    required String description,
    required JobType jobType,
    required int workersNeeded,
    required int wagePerWorkerPaise,
    required DateTime workDate,
    required Future<void> Function(AppUser updated) onPosterUpdated,
  }) async {
    final fee = postingFeeFor(poster);
    final jobId = _uuid.v4();
    String? paymentRef;

    if (fee > 0) {
      final result = await _gateway.charge(
        amountPaise: fee,
        description: 'Job posting fee',
        payer: Payer(id: poster.id, name: poster.name, phoneE164: poster.phone),
        reference: jobId,
      );
      if (!result.success) {
        return JobPostOutcome(
          success: false,
          message: result.message,
          cancelled: result.cancelled,
        );
      }
      paymentRef = result.gatewayRef;
    }

    final job = Job(
      id: jobId,
      posterId: poster.id,
      posterName: poster.name,
      posterRole: poster.role,
      title: title,
      description: description,
      jobType: jobType,
      workersNeeded: workersNeeded,
      wagePerWorkerPaise: wagePerWorkerPaise,
      district: poster.district,
      workDate: workDate,
      postingFeePaise: fee,
      createdAt: DateTime.now(),
    );
    // Job saved first: the money is already taken, so the thing paid for
    // must exist before anything else can fail.
    await _db.put(LocalDb.jobs, job.id, job.toMap());

    if (fee > 0) {
      await _addLedger(
        payerId: poster.id,
        payerName: poster.name,
        payeeId: 'platform',
        payeeName: 'BLOB Platform',
        amountPaise: fee,
        type: LedgerType.jobPostingFee,
        reference: job.id,
        note: 'Job posting fee · $title',
        status: PaymentStatus.cleared,
        gatewayRef: paymentRef,
      );
    }

    final updatedPoster = poster.copyWith(
      freeJobPostsUsed: poster.freeJobPostsUsed + 1,
    );
    await _db.put(LocalDb.users, updatedPoster.id, updatedPoster.toMap());
    await onPosterUpdated(updatedPoster);

    notifyListeners();
    return JobPostOutcome(
      success: true,
      message: fee == 0
          ? 'Job posted'
          : _gateway.mode == PaymentMode.demo
          ? 'Job posted · demo payment, no money taken'
          : 'Job posted · ${Money.format(fee)} paid',
      feeChargedPaise: fee,
    );
  }

  Future<void> applyToJob({
    required Job job,
    required AppUser laborer,
    int groupSize = 1,
  }) async {
    final already = applications.any(
      (a) => a.jobId == job.id && a.laborerId == laborer.id,
    );
    if (already) return;

    final app = JobApplication(
      id: _uuid.v4(),
      jobId: job.id,
      laborerId: laborer.id,
      laborerName: laborer.name,
      laborerType: laborer.laborerType ?? LaborerType.singleWorker,
      groupSize: groupSize,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.applications, app.id, app.toMap());
    notifyListeners();
  }

  Future<void> assignApplication(JobApplication app, Job job) async {
    final updated = app.copyWith(status: ApplicationStatus.assigned);
    await _db.put(LocalDb.applications, updated.id, updated.toMap());
    await _db.put(
      LocalDb.jobs,
      job.id,
      job.copyWith(status: JobStatus.assigned).toMap(),
    );
    notifyListeners();
  }

  Future<void> acceptAssignment(JobApplication app) async {
    final updated = app.copyWith(status: ApplicationStatus.accepted);
    await _db.put(LocalDb.applications, updated.id, updated.toMap());
    final job = jobs.where((j) => j.id == app.jobId).firstOrNull;
    if (job != null) {
      await _db.put(
        LocalDb.jobs,
        job.id,
        job.copyWith(status: JobStatus.inProgress).toMap(),
      );
    }
    notifyListeners();
  }

  /// Completing a job creates the wage payable to the laborer.
  Future<void> completeJob({
    required Job job,
    required JobApplication app,
  }) async {
    await _db.put(
      LocalDb.applications,
      app.id,
      app.copyWith(status: ApplicationStatus.completed).toMap(),
    );
    await _db.put(
      LocalDb.jobs,
      job.id,
      job.copyWith(status: JobStatus.completed).toMap(),
    );

    final wage = job.wagePerWorkerPaise * app.groupSize;
    await _addLedger(
      payerId: job.posterId,
      payerName: job.posterName,
      payeeId: app.laborerId,
      payeeName: app.laborerName,
      amountPaise: wage,
      type: LedgerType.laborWage,
      reference: job.id,
      note: job.title,
    );
    notifyListeners();
  }

  // ---------------- Vehicles & bookings ----------------

  Future<void> addVehicle({
    required AppUser owner,
    required VehicleCategory category,
    required String vehicleType,
    required String registrationNumber,
    required double capacityValue,
    required int ratePaise,
    RoleSubtype? subtype,
  }) async {
    final vehicle = Vehicle(
      id: _uuid.v4(),
      ownerId: owner.id,
      ownerName: owner.name,
      category: category,
      subtype: subtype ?? owner.subtype,
      vehicleType: vehicleType,
      registrationNumber: registrationNumber,
      capacityValue: capacityValue,
      ratePerKmPaise: category.isDailyRate ? 0 : ratePaise,
      ratePerDayPaise: category.isDailyRate ? ratePaise : 0,
      district: owner.district,
    );
    await _db.put(LocalDb.vehicles, vehicle.id, vehicle.toMap());
    notifyListeners();
  }

  /// Lists a vehicle for rent on behalf of an ordinary member.
  ///
  /// Separate entry point from [addVehicle] rather than another flag on it,
  /// because the two have genuinely different rules: this one is always a
  /// daily-rate rental, always marks the record [Vehicle.peerListed], and
  /// accepts a rental kind chosen freely instead of inheriting the account's
  /// provider specialisation.
  Future<Vehicle> listVehicleForRent({
    required AppUser owner,
    required RoleSubtype kind,
    required String vehicleType,
    required String registrationNumber,
    required double capacityValue,
    required int ratePerDayPaise,
    String notes = '',
  }) async {
    final vehicle = Vehicle(
      id: _uuid.v4(),
      ownerId: owner.id,
      ownerName: owner.name,
      category: VehicleCategory.rental,
      subtype: kind,
      vehicleType: vehicleType,
      registrationNumber: registrationNumber,
      capacityValue: capacityValue,
      ratePerDayPaise: ratePerDayPaise,
      // Derived from the account, never typed. Keeps every listing's district
      // a real gazetteer place without asking the lister for it again.
      district: owner.district,
      peerListed: true,
      notes: notes,
    );
    await _db.put(LocalDb.vehicles, vehicle.id, vehicle.toMap());
    notifyListeners();
    return vehicle;
  }

  /// Every vehicle offered for rent, whichever kind of owner listed it.
  /// Renters browse one pool; the card discloses who they would be renting
  /// from.
  List<Vehicle> rentableVehicles({RoleSubtype? kind}) =>
      availableVehicles(VehicleCategory.rental, subtype: kind);

  /// A member's own rental listings, for the "vehicles I lend" view.
  List<Vehicle> rentalsListedBy(String ownerId) => vehicles
      .where((v) => v.ownerId == ownerId && v.category.isDailyRate)
      .toList();

  Future<void> toggleVehicleAvailability(Vehicle v) async {
    final updated = v.copyWith(available: !v.available);
    await _db.put(LocalDb.vehicles, updated.id, updated.toMap());
    notifyListeners();
  }

  /// Revises an existing listing. Only the fields [Vehicle.copyWith] allows
  /// can move; identity and district stay put.
  Future<void> updateVehicle(
    Vehicle v, {
    RoleSubtype? kind,
    String? vehicleType,
    double? capacityValue,
    int? ratePaise,
    String? notes,
  }) async {
    final updated = v.copyWith(
      subtype: kind,
      vehicleType: vehicleType,
      capacityValue: capacityValue,
      ratePerKmPaise: ratePaise != null && !v.category.isDailyRate
          ? ratePaise
          : null,
      ratePerDayPaise: ratePaise != null && v.category.isDailyRate
          ? ratePaise
          : null,
      notes: notes,
    );
    await _db.put(LocalDb.vehicles, updated.id, updated.toMap());
    notifyListeners();
  }

  /// Whether a listing can be withdrawn outright.
  ///
  /// Blocked while a booking is still live, so a renter who has already
  /// committed cannot have the vehicle vanish from under them. Once trips are
  /// completed or cancelled the listing is free to go.
  bool canDeleteVehicle(String vehicleId) => !bookings.any(
    (b) =>
        b.vehicleId == vehicleId &&
        b.status != BookingStatus.delivered &&
        b.status != BookingStatus.cancelled,
  );

  /// Withdraws a listing. Returns false when a live booking blocks it, so the
  /// caller can explain why rather than failing silently.
  Future<bool> deleteVehicle(Vehicle v) async {
    if (!canDeleteVehicle(v.id)) return false;
    await _db.delete(LocalDb.vehicles, v.id);
    notifyListeners();
    return true;
  }

  /// Books a goods trip, a taxi ride or a self-drive rental. Pass
  /// [distanceKm] for per-km categories, [rentalDays] for daily rentals.
  Future<VehicleBooking> bookVehicle({
    required Vehicle vehicle,
    required AppUser requester,
    required String pickup,
    required String drop,
    required DateTime scheduledAt,
    double distanceKm = 0,
    int rentalDays = 0,
  }) async {
    final isRental = vehicle.category.isDailyRate;
    final fare = isRental
        ? vehicle.ratePerDayPaise * rentalDays
        : (vehicle.ratePerKmPaise * distanceKm).round();

    final booking = VehicleBooking(
      id: _uuid.v4(),
      vehicleId: vehicle.id,
      vehicleLabel: '${vehicle.vehicleType} · ${vehicle.registrationNumber}',
      category: vehicle.category,
      requesterId: requester.id,
      requesterName: requester.name,
      providerId: vehicle.ownerId,
      pickup: pickup,
      drop: drop,
      distanceKm: isRental ? 0 : distanceKm,
      rentalDays: isRental ? rentalDays : 0,
      farePaise: fare,
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.bookings, booking.id, booking.toMap());

    await _addLedger(
      payerId: requester.id,
      payerName: requester.name,
      payeeId: vehicle.ownerId,
      payeeName: vehicle.ownerName,
      amountPaise: fare,
      type: switch (vehicle.category) {
        VehicleCategory.goods => LedgerType.transportFare,
        VehicleCategory.passenger => LedgerType.taxiFare,
        VehicleCategory.rental => LedgerType.vehicleRentFee,
      },
      reference: booking.id,
      note: isRental
          ? '${vehicle.vehicleType} · ${booking.quantityLabel}'
          : '$pickup to $drop · ${booking.quantityLabel}',
    );
    notifyListeners();
    return booking;
  }

  Future<void> updateBookingStatus(
    VehicleBooking booking,
    BookingStatus status,
  ) async {
    await _db.put(
      LocalDb.bookings,
      booking.id,
      booking.copyWith(status: status).toMap(),
    );
    notifyListeners();
  }

  // ---------------- Investments ----------------

  Future<void> createInvestment({
    required AppUser investor,
    required Listing project,
    required int amountPaise,
  }) async {
    final inv = Investment(
      id: _uuid.v4(),
      investorId: investor.id,
      investorName: investor.name,
      projectId: project.id,
      projectTitle: project.cropName,
      landownerId: project.ownerId,
      landownerName: project.ownerName,
      amountPaise: amountPaise,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.investments, inv.id, inv.toMap());
    await _addLedger(
      payerId: investor.id,
      payerName: investor.name,
      payeeId: project.ownerId,
      payeeName: project.ownerName,
      amountPaise: amountPaise,
      type: LedgerType.investment,
      reference: project.id,
      note: 'Investment · ${project.cropName}',
    );
    notifyListeners();
  }

  // ---------------- Property, land & rental ----------------

  Future<PropertyListing> createProperty({
    required AppUser owner,
    required RoleSubtype kind,
    required String title,
    required String description,
    required double areaValue,
    required int rentPerMonthPaise,
    required int depositPaise,
    required String locality,
    required int leaseMonthsMin,
    required DateTime availableFrom,
  }) async {
    final property = PropertyListing(
      id: _uuid.v4(),
      ownerId: owner.id,
      ownerName: owner.name,
      kind: kind,
      title: title,
      description: description,
      areaValue: areaValue,
      rentPerMonthPaise: rentPerMonthPaise,
      depositPaise: depositPaise,
      locality: locality,
      district: owner.district,
      leaseMonthsMin: leaseMonthsMin,
      availableFrom: availableFrom,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.properties, property.id, property.toMap());
    notifyListeners();
    return property;
  }

  Future<void> updatePropertyStatus(
    PropertyListing property,
    ListingStatus status,
  ) async {
    final updated = property.copyWith(status: status);
    await _db.put(LocalDb.properties, updated.id, updated.toMap());
    notifyListeners();
  }

  Future<PropertyEnquiry> raiseEnquiry({
    required PropertyListing property,
    required AppUser seeker,
    required int months,
    required String message,
  }) async {
    final enquiry = PropertyEnquiry(
      id: _uuid.v4(),
      propertyId: property.id,
      propertyTitle: property.title,
      ownerId: property.ownerId,
      seekerId: seeker.id,
      seekerName: seeker.name,
      months: months,
      message: message,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.enquiries, enquiry.id, enquiry.toMap());
    notifyListeners();
    return enquiry;
  }

  /// Agreeing a lease reserves the property and raises the first month's
  /// rent plus deposit as a payable.
  Future<void> setEnquiryStatus(
    PropertyEnquiry enquiry,
    EnquiryStatus status,
  ) async {
    final updated = enquiry.copyWith(status: status);
    await _db.put(LocalDb.enquiries, updated.id, updated.toMap());

    if (status == EnquiryStatus.agreed) {
      final property = properties
          .where((p) => p.id == enquiry.propertyId)
          .firstOrNull;
      if (property != null) {
        await updatePropertyStatus(property, ListingStatus.reserved);
        await _addLedger(
          payerId: enquiry.seekerId,
          payerName: enquiry.seekerName,
          payeeId: property.ownerId,
          payeeName: property.ownerName,
          amountPaise: property.rentPerMonthPaise + property.depositPaise,
          type: LedgerType.propertyRent,
          reference: property.id,
          note: '${property.title} · first month + deposit',
        );
      }
    }
    notifyListeners();
  }

  // ---------------- Ledger ----------------

  Future<void> _addLedger({
    required String payerId,
    required String payerName,
    required String payeeId,
    required String payeeName,
    required int amountPaise,
    required LedgerType type,
    required String reference,
    required String note,
    PaymentStatus status = PaymentStatus.pending,
    String? gatewayRef,
  }) async {
    final entry = LedgerEntry(
      id: _uuid.v4(),
      payerId: payerId,
      payerName: payerName,
      payeeId: payeeId,
      payeeName: payeeName,
      amountPaise: amountPaise,
      type: type,
      status: status,
      reference: reference,
      note: note,
      createdAt: DateTime.now(),
      clearedAt: status == PaymentStatus.cleared ? DateTime.now() : null,
      gatewayRef: gatewayRef,
    );
    await _db.put(LocalDb.ledger, entry.id, entry.toMap());
  }

  /// Clears a pending payout through the gateway.
  Future<bool> clearPayment(LedgerEntry entry) async {
    if (entry.status == PaymentStatus.cleared) return true;
    final result = await _gateway.payout(
      amountPaise: entry.amountPaise,
      payeeId: entry.payeeId,
      description: entry.note,
    );
    if (!result.success) return false;
    final updated = entry.copyWith(
      status: PaymentStatus.cleared,
      clearedAt: DateTime.now(),
    );
    await _db.put(LocalDb.ledger, updated.id, updated.toMap());
    notifyListeners();
    return true;
  }

  Future<void> clearAllPending(String payerId) async {
    final pending = ledger
        .where((e) => e.payerId == payerId && e.status == PaymentStatus.pending)
        .toList();
    for (final e in pending) {
      await clearPayment(e);
    }
  }

  // ---------------- Admin ----------------

  Future<void> setVerification(AppUser user, VerificationStatus status) async {
    final updated = user.copyWith(verificationStatus: status);
    await _db.put(LocalDb.users, updated.id, updated.toMap());
    notifyListeners();
  }
}
