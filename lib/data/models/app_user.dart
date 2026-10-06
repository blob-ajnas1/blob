import '../../core/rbac/permissions.dart';
import 'enums.dart';
import 'learning.dart';
import 'role_subtype.dart';

/// users table/collection
class AppUser {
  final String id;
  final String phone; // full E.164, e.g. +919876543210
  final String countryCode; // e.g. +91
  final String name;
  final UserRole role;
  final RoleSubtype?
  subtype; // role specialisation, null for single-shape roles
  final LaborerType? laborerType; // only for UserRole.laborer
  final String? companyName; // exporter / investor entity
  final String? registrationNo; // exporter company registration
  final String? country; // for foreign investor / exporter
  final String district;

  /// State and city/town/village, both chosen from the [Gazetteer] at signup.
  /// Nullable because accounts created before location became a dropdown only
  /// recorded a district; `stateName` back-fills from the gazetteer on demand
  /// rather than being guessed at read time.
  final String? stateName;
  final String? city;
  final VerificationStatus verificationStatus;
  final int freeJobPostsUsed;

  /// Learning track chosen at signup. Null for accounts created before the
  /// learning module, and for marketplace-only roles.
  final UserCategory? category;

  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.phone,
    required this.countryCode,
    required this.name,
    required this.role,
    required this.district,
    required this.createdAt,
    this.stateName,
    this.city,
    this.subtype,
    this.laborerType,
    this.companyName,
    this.registrationNo,
    this.country,
    this.verificationStatus = VerificationStatus.approved,
    this.freeJobPostsUsed = 0,
    this.category,
  });

  bool get isApproved => verificationStatus == VerificationStatus.approved;
  bool get isPending => verificationStatus == VerificationStatus.pending;

  /// Capability check that accounts for the user's specialisation.
  bool can(Permission permission) =>
      Rbac.can(role, permission, subtype: subtype);

  Set<Permission> get permissions => Rbac.of(role, subtype: subtype);

  /// Role plus specialisation, e.g. "Buyer · Retail Market Buyer".
  String get roleLine =>
      subtype == null ? role.label : '${role.label} · ${subtype!.label}';

  bool get isStudent => category == UserCategory.student;

  AppUser copyWith({
    String? name,
    UserRole? role,
    RoleSubtype? subtype,
    LaborerType? laborerType,
    String? companyName,
    String? registrationNo,
    String? country,
    String? district,
    String? stateName,
    String? city,
    VerificationStatus? verificationStatus,
    int? freeJobPostsUsed,
    UserCategory? category,
    bool clearSubtype = false,
  }) {
    return AppUser(
      id: id,
      phone: phone,
      countryCode: countryCode,
      name: name ?? this.name,
      role: role ?? this.role,
      // A plain `subtype ?? this.subtype` cannot express "set this back to
      // null", which switching to the student track needs: marketplace
      // specialisations have no meaning there and would otherwise linger.
      subtype: clearSubtype ? null : (subtype ?? this.subtype),
      laborerType: laborerType ?? this.laborerType,
      companyName: companyName ?? this.companyName,
      registrationNo: registrationNo ?? this.registrationNo,
      country: country ?? this.country,
      district: district ?? this.district,
      stateName: stateName ?? this.stateName,
      city: city ?? this.city,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      freeJobPostsUsed: freeJobPostsUsed ?? this.freeJobPostsUsed,
      category: category ?? this.category,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'phone': phone,
    'country_code': countryCode,
    'name': name,
    'role': role.name,
    'subtype': subtype?.name,
    'laborer_type': laborerType?.name,
    'company_name': companyName,
    'registration_no': registrationNo,
    'country': country,
    'district': district,
    'state_name': stateName,
    'city': city,
    'verification_status': verificationStatus.name,
    'free_job_posts_used': freeJobPostsUsed,
    'category': category?.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory AppUser.fromMap(Map<dynamic, dynamic> m) => AppUser(
    id: m['id'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    countryCode: m['country_code'] as String? ?? '+91',
    name: m['name'] as String? ?? 'User',
    role: UserRoleX.fromId(m['role'] as String? ?? 'buyer'),
    subtype: RoleSubtypeX.tryFromId(m['subtype'] as String?),
    laborerType: m['laborer_type'] == null
        ? null
        : LaborerTypeX.fromId(m['laborer_type'] as String),
    companyName: m['company_name'] as String?,
    registrationNo: m['registration_no'] as String?,
    country: m['country'] as String?,
    district: m['district'] as String? ?? '',
    stateName: m['state_name'] as String?,
    city: m['city'] as String?,
    verificationStatus: VerificationStatusX.fromId(
      m['verification_status'] as String? ?? 'approved',
    ),
    freeJobPostsUsed: (m['free_job_posts_used'] as num?)?.toInt() ?? 0,
    category: UserCategoryX.tryFromId(m['category'] as String?),
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
