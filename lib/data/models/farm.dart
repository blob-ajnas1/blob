/// A landowner's field. Powers the "My Land" and crop-management cards.
class FarmPlot {
  final String id;
  final String ownerId;
  final String name; // "North field", "Survey 112/3"
  final double acres;
  final String village;
  final String district;
  final String soil; // Red loam, Black cotton...
  final String irrigation; // Borewell, Canal, Rain-fed
  final String? crop; // null when the plot is fallow
  final DateTime? sownOn;
  final int cropDays; // typical sowing-to-harvest duration for [crop]
  final DateTime createdAt;

  const FarmPlot({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.acres,
    required this.village,
    required this.district,
    required this.soil,
    required this.irrigation,
    required this.createdAt,
    this.crop,
    this.sownOn,
    this.cropDays = 0,
  });

  bool get isFallow => crop == null || sownOn == null || cropDays <= 0;

  DateTime? get expectedHarvest =>
      isFallow ? null : sownOn!.add(Duration(days: cropDays));

  /// 0..1 of the way from sowing to harvest; null when fallow.
  double? progressAt(DateTime now) {
    if (isFallow) return null;
    final elapsed = now.difference(sownOn!).inHours / 24;
    return (elapsed / cropDays).clamp(0.0, 1.0);
  }

  /// Plain-language stage for the progress bar.
  String stageAt(DateTime now) {
    final p = progressAt(now);
    if (p == null) return 'Fallow — ready to sow';
    if (p >= 1) return 'Ready to harvest';
    if (p >= 0.75) return 'Maturing';
    if (p >= 0.4) return 'Flowering';
    if (p >= 0.15) return 'Growing';
    return 'Sprouting';
  }

  int? daysToHarvest(DateTime now) {
    final h = expectedHarvest;
    if (h == null) return null;
    final d = h.difference(DateTime(now.year, now.month, now.day)).inDays;
    return d < 0 ? 0 : d;
  }

  FarmPlot copyWith({
    String? crop,
    DateTime? sownOn,
    int? cropDays,
    bool clearCrop = false,
  }) => FarmPlot(
    id: id,
    ownerId: ownerId,
    name: name,
    acres: acres,
    village: village,
    district: district,
    soil: soil,
    irrigation: irrigation,
    createdAt: createdAt,
    crop: clearCrop ? null : (crop ?? this.crop),
    sownOn: clearCrop ? null : (sownOn ?? this.sownOn),
    cropDays: clearCrop ? 0 : (cropDays ?? this.cropDays),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'name': name,
    'acres': acres,
    'village': village,
    'district': district,
    'soil': soil,
    'irrigation': irrigation,
    'crop': crop,
    'sown_on': sownOn?.toIso8601String(),
    'crop_days': cropDays,
    'created_at': createdAt.toIso8601String(),
  };

  factory FarmPlot.fromMap(Map<dynamic, dynamic> m) => FarmPlot(
    id: m['id'] as String? ?? '',
    ownerId: m['owner_id'] as String? ?? '',
    name: m['name'] as String? ?? 'Plot',
    acres: (m['acres'] as num?)?.toDouble() ?? 0,
    village: m['village'] as String? ?? '',
    district: m['district'] as String? ?? '',
    soil: m['soil'] as String? ?? '',
    irrigation: m['irrigation'] as String? ?? '',
    crop: m['crop'] as String?,
    sownOn: DateTime.tryParse(m['sown_on'] as String? ?? ''),
    cropDays: (m['crop_days'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
