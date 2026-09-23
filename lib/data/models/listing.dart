import 'enums.dart';

/// listings table/collection — crops & agricultural products.
class Listing {
  final String id;
  final String ownerId;
  final String ownerName;
  final UserRole ownerRole; // landowner (origin) or buyer (resale to exporter)
  final String cropName;
  final String description;
  final double quantityQuintal;
  final int pricePerQuintalPaise; // INR paise — integer money only
  final String district;
  final ListingChannel channel;
  final ListingStatus status;
  final String? imageAsset;
  final DateTime createdAt;

  const Listing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerRole,
    required this.cropName,
    required this.description,
    required this.quantityQuintal,
    required this.pricePerQuintalPaise,
    required this.district,
    required this.channel,
    required this.createdAt,
    this.status = ListingStatus.active,
    this.imageAsset,
  });

  int get totalPaise => (pricePerQuintalPaise * quantityQuintal).round();

  Listing copyWith({ListingStatus? status}) => Listing(
    id: id,
    ownerId: ownerId,
    ownerName: ownerName,
    ownerRole: ownerRole,
    cropName: cropName,
    description: description,
    quantityQuintal: quantityQuintal,
    pricePerQuintalPaise: pricePerQuintalPaise,
    district: district,
    channel: channel,
    status: status ?? this.status,
    imageAsset: imageAsset,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'owner_name': ownerName,
    'owner_role': ownerRole.name,
    'crop_name': cropName,
    'description': description,
    'quantity_quintal': quantityQuintal,
    'price_per_quintal_paise': pricePerQuintalPaise,
    'district': district,
    'channel': channel.name,
    'status': status.name,
    'image_asset': imageAsset,
    'created_at': createdAt.toIso8601String(),
  };

  factory Listing.fromMap(Map<dynamic, dynamic> m) => Listing(
    id: m['id'] as String? ?? '',
    ownerId: m['owner_id'] as String? ?? '',
    ownerName: m['owner_name'] as String? ?? '',
    ownerRole: UserRoleX.fromId(m['owner_role'] as String? ?? 'landowner'),
    cropName: m['crop_name'] as String? ?? '',
    description: m['description'] as String? ?? '',
    quantityQuintal: (m['quantity_quintal'] as num?)?.toDouble() ?? 0,
    pricePerQuintalPaise: (m['price_per_quintal_paise'] as num?)?.toInt() ?? 0,
    district: m['district'] as String? ?? '',
    channel: ListingChannelX.fromId(m['channel'] as String? ?? 'toBuyers'),
    status: ListingStatusX.fromId(m['status'] as String? ?? 'active'),
    imageAsset: m['image_asset'] as String?,
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
