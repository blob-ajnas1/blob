import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/i18n/strings.dart';
import '../data/local_db.dart';
import '../data/models/app_user.dart';
import '../data/models/enums.dart';
import '../data/models/learning.dart';
import '../data/models/role_subtype.dart';
import '../services/otp_service.dart';

/// Owns language preference, OTP flow state and the persistent session.
class SessionController extends ChangeNotifier {
  SessionController({OtpService? otpService})
    : _otp = otpService ?? OtpService();

  final OtpService _otp;
  final _db = LocalDb.instance;
  final _uuid = const Uuid();

  static const _kLanguage = 'language_code';
  static const _kSessionUserId = 'session_user_id';
  static const _kOnboarded = 'onboarding_complete';

  AppLanguage _language = AppLanguage.english;
  AppUser? _user;
  String _pendingPhone = '';
  String _pendingCountryCode = '+91';
  String? _devCode;
  bool _busy = false;

  AppLanguage get language => _language;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get hasOnboarded => _db.setting<bool>(_kOnboarded, false);
  String get pendingPhone => _pendingPhone;
  String get pendingCountryCode => _pendingCountryCode;
  String? get devCode => _devCode;
  bool get busy => _busy;

  String t(String key) => S.t(_language, key);

  void load() {
    _language = AppLanguageX.fromCode(_db.setting<String>(_kLanguage, 'en'));
    final sessionId = _db.setting<String>(_kSessionUserId, '');
    if (sessionId.isNotEmpty) {
      final raw = _db.get(LocalDb.users, sessionId);
      if (raw != null) _user = AppUser.fromMap(raw);
    }
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    await _db.setSetting(_kLanguage, lang.code);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _db.setSetting(_kOnboarded, true);
    notifyListeners();
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  // ---------------- OTP flow ----------------

  Future<OtpSendResult> requestOtp(
    String countryCode,
    String localNumber,
  ) async {
    _setBusy(true);
    _pendingCountryCode = countryCode;
    _pendingPhone = '$countryCode${localNumber.trim()}';
    final result = await _otp.requestOtp(_pendingPhone);
    _devCode = result.devCode;
    _setBusy(false);
    return result;
  }

  Future<OtpSendResult> resendOtp() async {
    _setBusy(true);
    final result = await _otp.requestOtp(_pendingPhone);
    _devCode = result.devCode;
    _setBusy(false);
    return result;
  }

  Duration? get resendCooldown => _otp.cooldownRemaining(_pendingPhone);

  /// True when codes go out as real SMS (dev banner is hidden in that case).
  bool get usesRealSms => _otp.usesRealSms;

  /// Verifies the code. Returns the existing user when the phone is already
  /// registered (straight to dashboard), or null when signup is required.
  ({bool ok, String message, AppUser? existing}) verifyOtp(String code) {
    final result = _otp.verify(_pendingPhone, code);
    if (!result.success) {
      return (ok: false, message: result.message, existing: null);
    }
    final existing = _findUserByPhone(_pendingPhone);
    if (existing != null) {
      _persistSession(existing);
    }
    return (ok: true, message: result.message, existing: existing);
  }

  AppUser? _findUserByPhone(String phone) {
    for (final raw in _db.all(LocalDb.users)) {
      if (raw['phone'] == phone) return AppUser.fromMap(raw);
    }
    return null;
  }

  // ---------------- Registration ----------------

  Future<AppUser> register({
    required String name,
    required UserRole role,
    required String district,
    String? stateName,
    String? city,
    RoleSubtype? subtype,
    LaborerType? laborerType,
    String? companyName,
    String? registrationNo,
    String? country,
    UserCategory? category,
  }) async {
    final needsApproval = role.requiresApproval;
    final user = AppUser(
      id: _uuid.v4(),
      phone: _pendingPhone,
      countryCode: _pendingCountryCode,
      name: name.trim(),
      role: role,
      subtype: subtype ?? RoleSubtypeX.defaultFor(role),
      district: district.trim(),
      stateName: stateName,
      city: city,
      laborerType: laborerType,
      companyName: companyName,
      registrationNo: registrationNo,
      country: country,
      verificationStatus: needsApproval
          ? VerificationStatus.pending
          : VerificationStatus.approved,
      category: category,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.users, user.id, user.toMap());
    await _persistSession(user);
    return user;
  }

  Future<void> _persistSession(AppUser user) async {
    _user = user;
    await _db.setSetting(_kSessionUserId, user.id);
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final id = _user?.id;
    if (id == null) return;
    final raw = _db.get(LocalDb.users, id);
    if (raw != null) {
      _user = AppUser.fromMap(raw);
      notifyListeners();
    }
  }

  Future<void> updateUser(AppUser updated) async {
    await _db.put(LocalDb.users, updated.id, updated.toMap());
    _user = updated;
    notifyListeners();
  }

  /// Switches the active session to another registered account.
  Future<void> switchTo(AppUser user) => _persistSession(user);

  Future<void> logout() async {
    if (_pendingPhone.isNotEmpty) _otp.clear(_pendingPhone);
    _user = null;
    _pendingPhone = '';
    _devCode = null;
    await _db.setSetting(_kSessionUserId, '');
    notifyListeners();
  }
}
