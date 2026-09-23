import 'enums.dart';
import 'role_subtype.dart';

/// properties table/collection — land, commercial and residential rentals.
///
/// The property "kind" reuses [RoleSubtype] because it is literally the same
/// taxonomy the owner signed up under, which keeps one source of truth.
class PropertyListing {
  final String id;
  final String ownerId;
  final String ownerName;
  final RoleSubtype kind;
  final String title;
  final String description;
  final double areaValue; // acres for land, sq ft for buildings
  final int rentPerMonthPaise;
  final int depositPaise;
  final String locality;
  final String district;
  final int leaseMonthsMin;
  final ListingStatus status;
  final DateTime availableFrom;
  final DateTime createdAt;

  const PropertyListing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.kind,
    required this.title,
    required this.description,
    required this.areaValue,
    required this.rentPerMonthPaise,
    required this.depositPaise,
    required this.locality,
    required this.district,
    required this.availableFrom,
    required this.createdAt,
    this.leaseMonthsMin = 11,
    this.status = ListingStatus.active,
  });

  String get areaLabel {
    final unit = kind.areaUnit;
    return unit == 'acre'
        ? '${areaValue.toStringAsFixed(areaValue % 1 == 0 ? 0 : 1)} acre'
        : '${areaValue.toStringAsFixed(0)} sq ft';
  }

  PropertyListing copyWith({ListingStatus? status}) => PropertyListing(
    id: id,
    ownerId: ownerId,
    ownerName: ownerName,
    kind: kind,
    title: title,
    description: description,
    areaValue: areaValue,
    rentPerMonthPaise: rentPerMonthPaise,
    depositPaise: depositPaise,
    locality: locality,
    district: district,
    leaseMonthsMin: leaseMonthsMin,
    status: status ?? this.status,
    availableFrom: availableFrom,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'owner_name': ownerName,
    'kind': kind.name,
    'title': title,
    'description': description,
    'area_value': areaValue,
    'rent_per_month_paise': rentPerMonthPaise,
    'deposit_paise': depositPaise,
    'locality': locality,
    'district': district,
    'lease_months_min': leaseMonthsMin,
    'status': status.name,
    'available_from': availableFrom.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  factory PropertyListing.fromMap(Map<dynamic, dynamic> m) => PropertyListing(
    id: m['id'] as String? ?? '',
    ownerId: m['owner_id'] as String? ?? '',
    ownerName: m['owner_name'] as String? ?? '',
    kind:
        RoleSubtypeX.tryFromId(m['kind'] as String?) ??
        RoleSubtype.agricultureLandLease,
    title: m['title'] as String? ?? '',
    description: m['description'] as String? ?? '',
    areaValue: (m['area_value'] as num?)?.toDouble() ?? 0,
    rentPerMonthPaise: (m['rent_per_month_paise'] as num?)?.toInt() ?? 0,
    depositPaise: (m['deposit_paise'] as num?)?.toInt() ?? 0,
    locality: m['locality'] as String? ?? '',
    district: m['district'] as String? ?? '',
    leaseMonthsMin: (m['lease_months_min'] as num?)?.toInt() ?? 11,
    status: ListingStatusX.fromId(m['status'] as String? ?? 'active'),
    availableFrom:
        DateTime.tryParse(m['available_from'] as String? ?? '') ??
        DateTime.now(),
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// property_enquiries table/collection — a seeker asking to lease.
class PropertyEnquiry {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String ownerId;
  final String seekerId;
  final String seekerName;
  final int months;
  final String message;
  final EnquiryStatus status;
  final DateTime createdAt;

  const PropertyEnquiry({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.ownerId,
    required this.seekerId,
    required this.seekerName,
    required this.months,
    required this.message,
    required this.createdAt,
    this.status = EnquiryStatus.open,
  });

  PropertyEnquiry copyWith({EnquiryStatus? status}) => PropertyEnquiry(
    id: id,
    propertyId: propertyId,
    propertyTitle: propertyTitle,
    ownerId: ownerId,
    seekerId: seekerId,
    seekerName: seekerName,
    months: months,
    message: message,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'property_id': propertyId,
    'property_title': propertyTitle,
    'owner_id': ownerId,
    'seeker_id': seekerId,
    'seeker_name': seekerName,
    'months': months,
    'message': message,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory PropertyEnquiry.fromMap(Map<dynamic, dynamic> m) => PropertyEnquiry(
    id: m['id'] as String? ?? '',
    propertyId: m['property_id'] as String? ?? '',
    propertyTitle: m['property_title'] as String? ?? '',
    ownerId: m['owner_id'] as String? ?? '',
    seekerId: m['seeker_id'] as String? ?? '',
    seekerName: m['seeker_name'] as String? ?? '',
    months: (m['months'] as num?)?.toInt() ?? 11,
    message: m['message'] as String? ?? '',
    status: EnquiryStatusX.fromId(m['status'] as String? ?? 'open'),
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
