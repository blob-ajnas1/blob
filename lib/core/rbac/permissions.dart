import '../../data/models/enums.dart';
import '../../data/models/role_subtype.dart';

/// Capability-based RBAC. Screens and widgets ask
/// `Rbac.can(role, Permission.x)` instead of hardcoding role checks.
///
/// Two layers:
///  * [Rbac._matrix]       — what every account of a role can do.
///  * [Rbac._subtypeGrants] — extra capabilities unlocked by the account's
///    chosen specialisation, so sub-types change real behaviour instead of
///    being a cosmetic label.
enum Permission {
  listCrops,
  browseMarket,
  buyProducts,
  resellToExporters,
  postJobs,
  applyToJobs,
  assignLaborers,
  discoverInvestors,
  investInProjects,
  bookGoodsVehicle,
  bookTaxi,
  rentVehicle,

  /// Put a vehicle up for rent as an ordinary member, not as a licensed
  /// operator. Held by every marketplace role on purpose — see
  /// [Rbac.peerRentalRoles] for why this one is granted so widely.
  listVehicleForRent,

  manageFleet,
  manageRentals,
  provideTaxi,
  listProperty,
  browseProperty,
  facilitateDeals,
  earnCommission,
  expediteShipping,
  viewPaymentTracker,
  approveAccounts,
}

class Rbac {
  Rbac._();

  static const Map<UserRole, Set<Permission>> _matrix = {
    UserRole.landowner: {
      Permission.listCrops,
      Permission.browseMarket,
      Permission.postJobs,
      Permission.assignLaborers,
      Permission.discoverInvestors,
      Permission.bookGoodsVehicle,
      Permission.bookTaxi,
      // rentVehicle and listVehicleForRent are not listed here or anywhere
      // below: peer rental is granted to every role from [_peerRental].
      Permission.browseProperty,
      Permission.listProperty,
      Permission.viewPaymentTracker,
    },
    UserRole.buyer: {
      Permission.browseMarket,
      Permission.buyProducts,
      Permission.postJobs,
      Permission.assignLaborers,
      Permission.bookGoodsVehicle,
      Permission.bookTaxi,
      Permission.browseProperty,
      Permission.viewPaymentTracker,
    },
    UserRole.broker: {
      Permission.browseMarket,
      Permission.facilitateDeals,
      Permission.earnCommission,
      Permission.browseProperty,
      Permission.viewPaymentTracker,
    },
    UserRole.laborer: {
      Permission.applyToJobs,
      Permission.bookTaxi,
      Permission.viewPaymentTracker,
    },
    UserRole.transport: {
      Permission.manageFleet,
      Permission.browseMarket,
      Permission.viewPaymentTracker,
    },
    UserRole.foreignInvestor: {
      Permission.browseMarket,
      Permission.investInProjects,
      Permission.browseProperty,
      Permission.bookTaxi,
      Permission.viewPaymentTracker,
    },
    UserRole.globalExporter: {
      Permission.browseMarket,
      Permission.buyProducts,
      Permission.expediteShipping,
      Permission.bookGoodsVehicle,
      Permission.bookTaxi,
      Permission.viewPaymentTracker,
    },
    UserRole.taxiService: {
      Permission.provideTaxi,
      Permission.manageFleet,
      Permission.viewPaymentTracker,
    },
    UserRole.vehicleRental: {
      Permission.manageRentals,
      Permission.manageFleet,
      Permission.viewPaymentTracker,
    },
    UserRole.propertyOwner: {
      Permission.listProperty,
      Permission.browseProperty,
      Permission.bookTaxi,
      Permission.viewPaymentTracker,
    },
    UserRole.shopkeeper: {
      Permission.browseMarket,
      Permission.buyProducts,
      Permission.bookGoodsVehicle,
      Permission.postJobs,
      Permission.assignLaborers,
      Permission.browseProperty,
      Permission.viewPaymentTracker,
    },
    // Students hold NO marketplace capability. This empty set is the single
    // enforcement point that keeps crops, jobs, transport, property and
    // payments out of the education app: every marketplace tab and action is
    // gated on a permission, so there is nothing to individually hide.
    UserRole.student: <Permission>{},
    UserRole.admin: {
      Permission.approveAccounts,
      Permission.browseMarket,
      Permission.browseProperty,
      Permission.viewPaymentTracker,
    },
  };

  /// Peer-to-peer vehicle rental is open to everybody: any member may put a
  /// vehicle up for rent, and any member may rent one. It is granted here
  /// rather than by repeating two lines in every role above, because that
  /// repetition would invite one role being quietly forgotten later — which is
  /// exactly the bug this vertical must not have.
  ///
  /// This is a different thing from [Permission.manageRentals], which stays
  /// with licensed rental businesses: they run a commercial fleet with permit
  /// obligations and get the fleet workspace. A farmer lending out an idle
  /// tractor for a fortnight is not that, and should not have to register as
  /// an operator to do it.
  static const Set<Permission> _peerRental = {
    Permission.listVehicleForRent,
    Permission.rentVehicle,
  };

  /// Every role except [UserRole.student]. Students hold no marketplace
  /// capability at all (see [_matrix]), and renting out a vehicle is squarely
  /// a marketplace act, so "anyone" means anyone on the marketplace side.
  static Set<UserRole> get peerRentalRoles =>
      UserRole.values.where((r) => r != UserRole.student).toSet();

  static bool _hasPeerRental(UserRole role) => role != UserRole.student;

  /// Capabilities added on top of the role baseline by a specialisation.
  static const Map<RoleSubtype, Set<Permission>> _subtypeGrants = {
    // Only wholesale buyers move stock onward to exporters; retail buyers
    // sell into local shops and mandis instead.
    RoleSubtype.wholesaleHarvestBuyer: {Permission.resellToExporters},
    // A labour agent supplies crews, so they need the hiring side too.
    RoleSubtype.labourAgentContract: {
      Permission.postJobs,
      Permission.assignLaborers,
    },
    // Agri-tech and infrastructure investors evaluate physical assets.
    RoleSubtype.farmInfrastructureEquity: {Permission.browseProperty},
    RoleSubtype.agriTechExpansion: {Permission.browseProperty},
    // Inter-state wholesale exporters book domestic freight directly.
    RoleSubtype.interStateWholesaleExport: {Permission.bookGoodsVehicle},
    // Land lessors are usually cultivators too.
    RoleSubtype.agricultureLandLease: {
      Permission.browseMarket,
      Permission.listCrops,
    },
  };

  static Set<Permission> of(UserRole role, {RoleSubtype? subtype}) {
    final base = _matrix[role] ?? const <Permission>{};
    final extra = subtype == null
        ? const <Permission>{}
        : (_subtypeGrants[subtype] ?? const <Permission>{});
    final peer = _hasPeerRental(role) ? _peerRental : const <Permission>{};
    if (extra.isEmpty && peer.isEmpty) return base;
    return {...base, ...extra, ...peer};
  }

  static bool can(
    UserRole role,
    Permission permission, {
    RoleSubtype? subtype,
  }) {
    if (_matrix[role]?.contains(permission) ?? false) return true;
    if (_peerRental.contains(permission) && _hasPeerRental(role)) return true;
    if (subtype == null) return false;
    return _subtypeGrants[subtype]?.contains(permission) ?? false;
  }
}
