import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed persistence. Every write goes to disk immediately so the
/// app works fully offline — a hard requirement for rural connectivity.
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  static const String users = 'users';
  static const String listings = 'listings';
  static const String jobs = 'jobs';
  static const String applications = 'applications';
  static const String ledger = 'ledger';
  static const String vehicles = 'vehicles';
  static const String bookings = 'bookings';
  static const String investments = 'investments';
  static const String properties = 'properties';
  static const String enquiries = 'enquiries';
  static const String studentProfiles = 'student_profiles';
  static const String dailyProgress = 'daily_progress';
  static const String activities = 'activities';
  static const String settings = 'settings';

  static const List<String> _boxes = [
    users,
    listings,
    jobs,
    applications,
    ledger,
    vehicles,
    bookings,
    investments,
    properties,
    enquiries,
    studentProfiles,
    dailyProgress,
    activities,
    settings,
  ];

  Future<void> init() async {
    await Hive.initFlutter();
    for (final name in _boxes) {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox(name);
      }
    }
  }

  Box box(String name) => Hive.box(name);

  List<Map<dynamic, dynamic>> all(String boxName) => box(
    boxName,
  ).values.whereType<Map<dynamic, dynamic>>().toList(growable: false);

  Future<void> put(String boxName, String id, Map<String, dynamic> value) =>
      box(boxName).put(id, value);

  Map<dynamic, dynamic>? get(String boxName, String id) {
    final v = box(boxName).get(id);
    return v is Map ? v : null;
  }

  Future<void> delete(String boxName, String id) => box(boxName).delete(id);

  T setting<T>(String key, T fallback) {
    final v = box(settings).get(key);
    return v is T ? v : fallback;
  }

  Future<void> setSetting(String key, dynamic value) =>
      box(settings).put(key, value);

  Future<void> wipeAll() async {
    for (final name in _boxes) {
      await box(name).clear();
    }
  }
}
