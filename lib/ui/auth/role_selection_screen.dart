import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/gazetteer.dart';
import '../../data/models/enums.dart';
import '../../data/models/learning.dart';
import '../../data/models/role_subtype.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../shell/track_router.dart';
import '../widgets/common.dart';
import '../widgets/location_picker.dart';
import 'student_details_screen.dart';

class RoleMeta {
  final UserRole role;
  final IconData icon;
  final String summary;
  const RoleMeta(this.role, this.icon, this.summary);
}

const kRoleMeta = <RoleMeta>[
  RoleMeta(
    UserRole.landowner,
    Icons.agriculture,
    'Sell your crops, hire workers, find investors',
  ),
  RoleMeta(
    UserRole.buyer,
    Icons.shopping_basket,
    'Buy from farmers, resell to exporters, hire crews',
  ),
  RoleMeta(
    UserRole.shopkeeper,
    Icons.store_mall_directory,
    'Run your shop: stock, customer orders and payments',
  ),
  RoleMeta(
    UserRole.laborer,
    Icons.engineering,
    'Find work — alone or as a group',
  ),
  RoleMeta(
    UserRole.broker,
    Icons.handshake,
    'Facilitate deals and earn commission',
  ),
  RoleMeta(
    UserRole.transport,
    Icons.local_shipping,
    'Move harvest and goods with pickups or heavy trucks',
  ),
  RoleMeta(
    UserRole.foreignInvestor,
    Icons.trending_up,
    'Invest in local agricultural projects',
  ),
  RoleMeta(
    UserRole.globalExporter,
    Icons.public,
    'Registered company buying and shipping produce',
  ),
  RoleMeta(
    UserRole.taxiService,
    Icons.local_taxi,
    'Run autos, cabs or traveller buses for passengers',
  ),
  RoleMeta(
    UserRole.vehicleRental,
    Icons.vpn_key,
    'Rent out cars, jeeps, SUVs, bikes and scooters',
  ),
  RoleMeta(
    UserRole.propertyOwner,
    Icons.home_work,
    'Lease farm land, commercial space or housing',
  ),
];

/// Whether this screen is part of signup or is changing an existing account.
enum RoleSelectionMode {
  /// Signup: a new account is created at the end.
  register,

  /// An existing account is being converted to the marketplace track, so the
  /// user record is updated in place and their id, phone,
  /// verification, points, streak and history are all preserved.
  switchExisting,
}

class RoleSelectionScreen extends StatefulWidget {
  /// Learning track chosen in Step 2. Carried through so the account is
  /// created with it in a single write.
  final UserCategory? category;

  /// Pending student details from Step 3, saved once the account exists
  /// (the profile is keyed by user id, which does not exist until then).
  final PendingStudentDetails? studentDetails;

  final RoleSelectionMode mode;

  const RoleSelectionScreen({
    super.key,
    this.category,
    this.studentDetails,
    this.mode = RoleSelectionMode.register,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(title: Text(session.t('choose_role'))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  session.t('role_hint'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kRoleMeta.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final meta = kRoleMeta[index];
                  final selected = _selected == meta.role;
                  return InkWell(
                    onTap: () => setState(() => _selected = meta.role),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primarySoft
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              meta.icon,
                              color: selected
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        meta.role.label,
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (meta.role.requiresApproval) ...[
                                      const SizedBox(width: 8),
                                      const StatusPill(
                                        label: 'Verified',
                                        color: AppColors.warning,
                                        background: AppColors.pendingSoft,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  meta.summary,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.3,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProfileSetupScreen(
                            role: _selected!,
                            category: widget.category,
                            studentDetails: widget.studentDetails,
                            mode: widget.mode,
                          ),
                        ),
                      ),
                child: Text(session.t('continue_label')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collects role-specific profile details before creating the account.
class ProfileSetupScreen extends StatefulWidget {
  final UserRole role;
  final UserCategory? category;
  final PendingStudentDetails? studentDetails;
  final RoleSelectionMode mode;

  const ProfileSetupScreen({
    super.key,
    required this.role,
    this.category,
    this.studentDetails,
    this.mode = RoleSelectionMode.register,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _registration = TextEditingController();
  // Location is picked from the gazetteer, never typed, so these are plain
  // values rather than text controllers.
  String? _stateName;
  String? _district;
  String? _city;
  String? _country;
  LaborerType _laborerType = LaborerType.singleWorker;
  RoleSubtype? _subtype;
  bool _saving = false;

  bool get _isLaborer => widget.role == UserRole.laborer;
  bool get _isExporter => widget.role == UserRole.globalExporter;
  bool get _isInvestor => widget.role == UserRole.foreignInvestor;

  /// Taxi and self-drive rental operators need a commercial permit on file.
  bool get _isCommercialOperator =>
      widget.role == UserRole.taxiService ||
      widget.role == UserRole.vehicleRental;

  /// Single vs group only matters for the general labour specialisation.
  bool get _needsCrewSize =>
      _isLaborer && _subtype == RoleSubtype.singleAndGroup;

  bool get _isSwitching => widget.mode == RoleSelectionMode.switchExisting;

  @override
  void initState() {
    super.initState();
    _subtype = RoleSubtypeX.defaultFor(widget.role);
    // When converting an existing account, pre-fill from the current record so
    // the user is not retyping their own name and district.
    if (_isSwitching) {
      final user = context.read<SessionController>().user;
      if (user != null) {
        _name.text = user.name;
        _company.text = user.companyName ?? '';
        _registration.text = user.registrationNo ?? '';
        _country = user.country;
        _district = user.district.isEmpty ? null : user.district;
        _city = user.city;
        // Older accounts stored only a district. Recover the state from the
        // gazetteer so the dropdown chain opens already populated instead of
        // forcing the user to re-pick a district they already have.
        _stateName = user.stateName ?? Gazetteer.stateOfDistrict(user.district);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _registration.dispose();
    super.dispose();
  }

  /// Applies a cascading location change. Levels below the one the user touched
  /// arrive as null and are cleared, so the record can never hold a district
  /// that does not belong to its state.
  void _onLocationChanged({String? state, String? district, String? city}) {
    setState(() {
      _stateName = state;
      _district = district;
      _city = city;
    });
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final session = context.read<SessionController>();
    final learning = context.read<LearningController>();

    if (_isSwitching) {
      await _convertExisting(session);
      return;
    }

    final user = await session.register(
      name: _name.text,
      role: widget.role,
      subtype: _subtype,
      district: _district ?? '',
      stateName: _stateName,
      city: _city,
      laborerType: _needsCrewSize ? _laborerType : null,
      companyName: _company.text.trim().isEmpty ? null : _company.text.trim(),
      registrationNo: _registration.text.trim().isEmpty
          ? null
          : _registration.text.trim(),
      country: _country,
      category: widget.category,
    );

    // Student details were collected before the user id existed, so they are
    // persisted here against the new account.
    final details = widget.studentDetails;
    if (details != null) {
      await learning.saveProfile(details.toProfile(user.id));
    }
    if (!mounted) return;
    // Routed through TrackRouter, not AppShell, so a student signup lands in
    // the education app and a job seeker in the marketplace app.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const TrackRouter()),
      (route) => false,
    );
  }

  /// Converts the signed-in account to the marketplace track in place.
  ///
  /// Updates rather than re-registers, so the id, phone,
  /// points, streak and history all survive the switch. Pops `true` so the
  /// caller knows to rebuild from the track boundary.
  Future<void> _convertExisting(SessionController session) async {
    final current = session.user;
    if (current == null) return;
    await session.updateUser(
      current.copyWith(
        name: _name.text.trim(),
        role: widget.role,
        subtype: _subtype,
        clearSubtype: _subtype == null,
        district: _district ?? '',
        stateName: _stateName,
        city: _city,
        laborerType: _needsCrewSize ? _laborerType : null,
        companyName: _company.text.trim().isEmpty ? null : _company.text.trim(),
        registrationNo: _registration.text.trim().isEmpty
            ? null
            : _registration.text.trim(),
        country: _country,
        category: UserCategory.jobSeeker,
        // A role that needs vetting must go back to pending; silently keeping
        // an old "approved" status would grant verified access to a role that
        // was never reviewed.
        verificationStatus: widget.role.requiresApproval
            ? VerificationStatus.pending
            : VerificationStatus.approved,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.role.label)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.role.requiresApproval) ...[
                  const InfoBanner(
                    icon: Icons.verified_user_outlined,
                    message:
                        'This account type needs approval by the BLOB team. '
                        'You can sign in immediately, with full access unlocked once approved.',
                    color: AppColors.warning,
                    background: AppColors.pendingSoft,
                  ),
                  const SizedBox(height: 18),
                ],
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: session.t('your_name'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 18),
                LocationPicker(
                  state: _stateName,
                  district: _district,
                  city: _city,
                  onChanged: _onLocationChanged,
                ),
                if (RoleSubtypeX.hasSubtypes(widget.role)) ...[
                  const SizedBox(height: 22),
                  Text(
                    session.t('choose_specialisation'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.t('specialisation_hint'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...RoleSubtypeX.forRole(widget.role).map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SubtypeTile(
                        subtype: s,
                        selected: _subtype == s,
                        onTap: () => setState(() => _subtype = s),
                      ),
                    ),
                  ),
                ],
                if (_needsCrewSize) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Do you work alone or as a group?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...LaborerType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => setState(() => _laborerType = type),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _laborerType == type
                                ? AppColors.primarySoft
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _laborerType == type
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: _laborerType == type ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                type == LaborerType.singleWorker
                                    ? Icons.person
                                    : Icons.groups,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      type.description,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _laborerType == type
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _laborerType == type
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (_isExporter || _isInvestor || _isCommercialOperator) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _company,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: _isExporter
                          ? 'Registered company name'
                          : _isCommercialOperator
                          ? 'Business / travels name'
                          : 'Entity / fund name (optional)',
                      prefixIcon: const Icon(Icons.business_outlined),
                    ),
                    validator: (v) {
                      if ((_isExporter || _isCommercialOperator) &&
                          (v?.trim().isEmpty ?? true)) {
                        return 'Business name is required';
                      }
                      return null;
                    },
                  ),
                ],
                if (_isExporter || _isInvestor) ...[
                  const SizedBox(height: 18),
                  CountryPicker(
                    country: _country,
                    onChanged: (v) => setState(() => _country = v),
                  ),
                ],
                if (_isExporter || _isCommercialOperator) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _registration,
                    decoration: InputDecoration(
                      labelText: _isExporter
                          ? 'Company registration number'
                          : 'Transport permit / licence number',
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'This number is required'
                        : null,
                  ),
                ],
                if (_isInvestor || _isExporter) ...[
                  const SizedBox(height: 18),
                  const InfoBanner(
                    icon: Icons.currency_rupee,
                    message:
                        'All transactions on BLOB are conducted in Indian Rupees (INR) only.',
                  ),
                ],
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: _saving ? null : _create,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(session.t('create_account')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Radio-style card used to pick a role specialisation during signup.
/// Rendering is driven entirely by [RoleSubtypeX], so no role needs its own
/// branch here — adding a subtype to the enum makes it appear automatically.
class _SubtypeTile extends StatelessWidget {
  final RoleSubtype subtype;
  final bool selected;
  final VoidCallback onTap;

  const _SubtypeTile({
    required this.subtype,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(subtype.icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtype.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtype.description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}
