import 'enums.dart';
import 'role_subtype.dart';

/// vehicles table/collection.
///
/// Two kinds of owner sit in here. Commercial operators (transport, taxi and
/// registered rental businesses) list from their fleet workspace. Ordinary
/// members list a single idle vehicle for rent — see [peerListed]. Both are
/// the same record because a renter browses one pool and books through one
/// flow; only the disclosure differs.
class Vehicle {
  final String id;
  final String ownerId;
  final String ownerName;
  final VehicleCategory category;
  final RoleSubtype? subtype; // provider specialisation this vehicle serves
  final String vehicleType; // Tractor Trailer, Mini Truck, Tempo, Jeep, Bus
  final String registrationNumber;
  final double capacityValue; // tonnes for goods, seats for passenger/rental
  final int ratePerKmPaise; // 0 for daily-rate rentals
  final int ratePerDayPaise; // 0 for per-km categories
  final String district;
  final bool available;

  /// Listed by an ordinary member rather than a registered operator.
  ///
  /// Shown to renters instead of being kept internal: renting a neighbour's
  /// tractor and hiring from a licensed firm carry different expectations
  /// about paperwork and recourse, and the renter is entitled to know which
  /// one they are dealing with before they commit money.
  final bool peerListed;

  /// Owner's own terms — fuel, deposit, driver, area limits. Free text because
  /// these conditions are genuinely local and a fixed set of fields would
  /// force owners to misstate them.
  final String notes;

  const Vehicle({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.category,
    required this.vehicleType,
    required this.registrationNumber,
    required this.capacityValue,
    required this.district,
    this.subtype,
    this.ratePerKmPaise = 0,
    this.ratePerDayPaise = 0,
    this.available = true,
    this.peerListed = false,
    this.notes = '',
  });

  String get capacityLabel => switch (category) {
    VehicleCategory.goods => '${capacityValue.toStringAsFixed(1)} tonnes',
    _ => '${capacityValue.toInt()} seats',
  };

  /// Rentals are billed by the day, transport and taxis by the kilometre.
  int get ratePaise => category.isDailyRate ? ratePerDayPaise : ratePerKmPaise;

  String get rateUnit => category.isDailyRate ? 'day' : 'km';

  /// Fields an owner may revise after listing.
  ///
  /// Rate, kind, capacity and notes are editable because a first-time lister
  /// routinely gets the price wrong and would otherwise have to delete and
  /// re-list, losing the record. Identity, owner and district are not
  /// editable: the district is derived from the owner's account, and letting
  /// a registration number change would turn one listing into a different
  /// vehicle while bookings still pointed at it.
  Vehicle copyWith({
    bool? available,
    RoleSubtype? subtype,
    String? vehicleType,
    double? capacityValue,
    int? ratePerKmPaise,
    int? ratePerDayPaise,
    String? notes,
  }) => Vehicle(
    id: id,
    ownerId: ownerId,
    ownerName: ownerName,
    category: category,
    subtype: subtype ?? this.subtype,
    vehicleType: vehicleType ?? this.vehicleType,
    registrationNumber: registrationNumber,
    capacityValue: capacityValue ?? this.capacityValue,
    ratePerKmPaise: ratePerKmPaise ?? this.ratePerKmPaise,
    ratePerDayPaise: ratePerDayPaise ?? this.ratePerDayPaise,
    district: district,
    available: available ?? this.available,
    peerListed: peerListed,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'owner_name': ownerName,
    'category': category.name,
    'subtype': subtype?.name,
    'vehicle_type': vehicleType,
    'registration_number': registrationNumber,
    'capacity_value': capacityValue,
    'rate_per_km_paise': ratePerKmPaise,
    'rate_per_day_paise': ratePerDayPaise,
    'district': district,
    'available': available,
    'peer_listed': peerListed,
    'notes': notes,
  };

  factory Vehicle.fromMap(Map<dynamic, dynamic> m) => Vehicle(
    id: m['id'] as String? ?? '',
    ownerId: m['owner_id'] as String? ?? '',
    ownerName: m['owner_name'] as String? ?? '',
    category: VehicleCategoryX.fromId(m['category'] as String? ?? 'goods'),
    subtype: RoleSubtypeX.tryFromId(m['subtype'] as String?),
    vehicleType: m['vehicle_type'] as String? ?? '',
    registrationNumber: m['registration_number'] as String? ?? '',
    capacityValue: (m['capacity_value'] as num?)?.toDouble() ?? 0,
    ratePerKmPaise: (m['rate_per_km_paise'] as num?)?.toInt() ?? 0,
    ratePerDayPaise: (m['rate_per_day_paise'] as num?)?.toInt() ?? 0,
    district: m['district'] as String? ?? '',
    available: m['available'] as bool? ?? true,
    // Absent on records written before peer listing existed, which were all
    // created by commercial operators — so false is the correct reading.
    peerListed: m['peer_listed'] as bool? ?? false,
    notes: m['notes'] as String? ?? '',
  );
}

/// vehicle_bookings table/collection.
class VehicleBooking {
  final String id;
  final String vehicleId;
  final String vehicleLabel;
  final VehicleCategory category;
  final String requesterId;
  final String requesterName;
  final String providerId;
  final String pickup;
  final String drop;
  final double distanceKm; // 0 for daily rentals
  final int rentalDays; // 0 for per-km bookings
  final int farePaise;
  final DateTime scheduledAt;
  final BookingStatus status;
  final DateTime createdAt;

  const VehicleBooking({
    required this.id,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.category,
    required this.requesterId,
    required this.requesterName,
    required this.providerId,
    required this.pickup,
    required this.drop,
    required this.farePaise,
    required this.scheduledAt,
    required this.createdAt,
    this.distanceKm = 0,
    this.rentalDays = 0,
    this.status = BookingStatus.requested,
  });

  /// "120 km" or "3 days" depending on how the booking is priced.
  String get quantityLabel => category.isDailyRate
      ? '$rentalDays ${rentalDays == 1 ? 'day' : 'days'}'
      : '${distanceKm.toStringAsFixed(0)} km';

  VehicleBooking copyWith({BookingStatus? status}) => VehicleBooking(
    id: id,
    vehicleId: vehicleId,
    vehicleLabel: vehicleLabel,
    category: category,
    requesterId: requesterId,
    requesterName: requesterName,
    providerId: providerId,
    pickup: pickup,
    drop: drop,
    distanceKm: distanceKm,
    rentalDays: rentalDays,
    farePaise: farePaise,
    scheduledAt: scheduledAt,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'vehicle_id': vehicleId,
    'vehicle_label': vehicleLabel,
    'category': category.name,
    'requester_id': requesterId,
    'requester_name': requesterName,
    'provider_id': providerId,
    'pickup': pickup,
    'drop': drop,
    'distance_km': distanceKm,
    'rental_days': rentalDays,
    'fare_paise': farePaise,
    'scheduled_at': scheduledAt.toIso8601String(),
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory VehicleBooking.fromMap(Map<dynamic, dynamic> m) => VehicleBooking(
    id: m['id'] as String? ?? '',
    vehicleId: m['vehicle_id'] as String? ?? '',
    vehicleLabel: m['vehicle_label'] as String? ?? '',
    category: VehicleCategoryX.fromId(m['category'] as String? ?? 'goods'),
    requesterId: m['requester_id'] as String? ?? '',
    requesterName: m['requester_name'] as String? ?? '',
    providerId: m['provider_id'] as String? ?? '',
    pickup: m['pickup'] as String? ?? '',
    drop: m['drop'] as String? ?? '',
    distanceKm: (m['distance_km'] as num?)?.toDouble() ?? 0,
    rentalDays: (m['rental_days'] as num?)?.toInt() ?? 0,
    farePaise: (m['fare_paise'] as num?)?.toInt() ?? 0,
    scheduledAt:
        DateTime.tryParse(m['scheduled_at'] as String? ?? '') ?? DateTime.now(),
    status: BookingStatusX.fromId(m['status'] as String? ?? 'requested'),
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// investments table/collection — foreign investor → landowner projects. INR only.
class Investment {
  final String id;
  final String investorId;
  final String investorName;
  final String projectId;
  final String projectTitle;
  final String landownerId;
  final String landownerName;
  final int amountPaise;
  final PaymentStatus status;
  final DateTime createdAt;

  const Investment({
    required this.id,
    required this.investorId,
    required this.investorName,
    required this.projectId,
    required this.projectTitle,
    required this.landownerId,
    required this.landownerName,
    required this.amountPaise,
    required this.createdAt,
    this.status = PaymentStatus.pending,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'investor_id': investorId,
    'investor_name': investorName,
    'project_id': projectId,
    'project_title': projectTitle,
    'landowner_id': landownerId,
    'landowner_name': landownerName,
    'amount_paise': amountPaise,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory Investment.fromMap(Map<dynamic, dynamic> m) => Investment(
    id: m['id'] as String? ?? '',
    investorId: m['investor_id'] as String? ?? '',
    investorName: m['investor_name'] as String? ?? '',
    projectId: m['project_id'] as String? ?? '',
    projectTitle: m['project_title'] as String? ?? '',
    landownerId: m['landowner_id'] as String? ?? '',
    landownerName: m['landowner_name'] as String? ?? '',
    amountPaise: (m['amount_paise'] as num?)?.toInt() ?? 0,
    status: PaymentStatusX.fromId(m['status'] as String? ?? 'pending'),
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
