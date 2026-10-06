/// BLOB domain enumerations.
library;

enum UserRole {
  buyer,
  landowner,
  broker,
  laborer,
  transport,
  foreignInvestor,
  globalExporter,
  taxiService,
  vehicleRental,
  propertyOwner,

  /// Village/town shop: keeps stock, takes customer orders, buys from
  /// farmers and suppliers on the market.
  shopkeeper,

  /// Education track. Deliberately a first-class role rather than reusing a
  /// marketplace role: a student must hold NO marketplace capability at all
  /// (see `Rbac._matrix`, where this role maps to an empty set), so no crop,
  /// job, transport or payment surface can ever leak into their app.
  student,
  admin,
}

extension UserRoleX on UserRole {
  String get id => name;

  String get label => switch (this) {
    UserRole.buyer => 'Buyer',
    UserRole.landowner => 'Landowner',
    UserRole.broker => 'Broker',
    UserRole.laborer => 'Labourer',
    // Shown as "Driver": the goods-transport role is the one that runs
    // trips, routes and hauls. The id stays `transport` so existing
    // accounts, vehicles and bookings carry over untouched.
    UserRole.transport => 'Driver',
    UserRole.foreignInvestor => 'Foreign Investor',
    UserRole.globalExporter => 'Global Exporter',
    UserRole.taxiService => 'Taxi Service',
    UserRole.vehicleRental => 'Vehicle Rent',
    UserRole.propertyOwner => 'Property & Land Rental',
    UserRole.shopkeeper => 'Shopkeeper',
    UserRole.student => 'Student',
    UserRole.admin => 'Administrator',
  };

  /// Short label used where space is tight (badges, pills).
  String get shortLabel => switch (this) {
    UserRole.propertyOwner => 'Property',
    UserRole.vehicleRental => 'Vehicle Rent',
    _ => label,
  };

  /// Roles that must be approved by an admin before gaining full access.
  /// Commercial vehicle operators are included because they carry
  /// permit / licensing obligations.
  bool get requiresApproval => const {
    UserRole.broker,
    UserRole.globalExporter,
    UserRole.taxiService,
    UserRole.vehicleRental,
  }.contains(this);

  /// Shown next to the role in the header switcher and its list.
  String get emoji => switch (this) {
    UserRole.landowner => '\u{1F33E}', // 🌾
    UserRole.transport => '\u{1F69B}', // 🚛
    UserRole.shopkeeper => '\u{1F6D2}', // 🛒
    UserRole.buyer => '\u{1F9FA}', // 🧺
    UserRole.laborer => '\u{1F9D1}\u{200D}\u{1F33E}', // 🧑‍🌾
    UserRole.broker => '\u{1F91D}', // 🤝
    UserRole.foreignInvestor => '\u{1F4C8}', // 📈
    UserRole.globalExporter => '\u{1F30D}', // 🌍
    UserRole.taxiService => '\u{1F695}', // 🚕
    UserRole.vehicleRental => '\u{1F511}', // 🔑
    UserRole.propertyOwner => '\u{1F3E1}', // 🏡
    UserRole.student => '\u{1F393}', // 🎓
    UserRole.admin => '\u{1F6E1}\u{FE0F}', // 🛡️
  };

  /// One line under the role name in the switcher list.
  String get switcherHint => switch (this) {
    UserRole.landowner => 'Plots, crops, labour and truck booking',
    UserRole.transport => 'Trips, routes, active hauls and earnings',
    UserRole.shopkeeper => 'Stock, customer orders, suppliers, payments',
    UserRole.buyer => 'Buy from farmers and resell',
    UserRole.laborer => 'Find farm and town work',
    UserRole.broker => 'Facilitate deals for commission',
    UserRole.foreignInvestor => 'Invest in farm projects',
    UserRole.globalExporter => 'Buy and ship produce',
    UserRole.taxiService => 'Run taxi rides',
    UserRole.vehicleRental => 'Rent out vehicles',
    UserRole.propertyOwner => 'Let land and buildings',
    UserRole.student => 'Learning app',
    UserRole.admin => 'Approve accounts',
  };

  /// Roles a member can add to their own account from the switcher with no
  /// extra paperwork. Roles that need admin vetting (broker, exporter,
  /// licensed taxi/rental operators) or company details still go through
  /// the full signup form, so adding a role can never skip a review.
  bool get selfAssignable => const {
    UserRole.landowner,
    UserRole.transport,
    UserRole.shopkeeper,
    UserRole.buyer,
    UserRole.laborer,
    UserRole.propertyOwner,
  }.contains(this);

  static UserRole fromId(String value) => UserRole.values.firstWhere(
    (e) => e.name == value,
    orElse: () => UserRole.buyer,
  );
}

enum LaborerType { singleWorker, groupWork }

extension LaborerTypeX on LaborerType {
  String get label => switch (this) {
    LaborerType.singleWorker => 'Single Worker',
    LaborerType.groupWork => 'Group Work',
  };

  String get description => switch (this) {
    LaborerType.singleWorker =>
      'Individual services — shops, hotels, domestic help',
    LaborerType.groupWork => 'Team labor — harvesting, factory shifts',
  };

  static LaborerType fromId(String value) => LaborerType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => LaborerType.singleWorker,
  );
}

enum VerificationStatus { pending, approved, rejected }

extension VerificationStatusX on VerificationStatus {
  String get label => switch (this) {
    VerificationStatus.pending => 'Pending Approval',
    VerificationStatus.approved => 'Verified',
    VerificationStatus.rejected => 'Rejected',
  };

  static VerificationStatus fromId(String value) =>
      VerificationStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => VerificationStatus.approved,
      );
}

enum JobType { single, group }

enum JobStatus { open, assigned, inProgress, completed, cancelled }

extension JobStatusX on JobStatus {
  String get label => switch (this) {
    JobStatus.open => 'Open',
    JobStatus.assigned => 'Assigned',
    JobStatus.inProgress => 'In Progress',
    JobStatus.completed => 'Completed',
    JobStatus.cancelled => 'Cancelled',
  };

  static JobStatus fromId(String value) => JobStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => JobStatus.open,
  );
}

enum ApplicationStatus { applied, assigned, accepted, completed, rejected }

extension ApplicationStatusX on ApplicationStatus {
  String get label => switch (this) {
    ApplicationStatus.applied => 'Applied',
    ApplicationStatus.assigned => 'Assigned',
    ApplicationStatus.accepted => 'Accepted',
    ApplicationStatus.completed => 'Completed',
    ApplicationStatus.rejected => 'Not Selected',
  };

  static ApplicationStatus fromId(String value) =>
      ApplicationStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ApplicationStatus.applied,
      );
}

enum ListingStatus { active, reserved, sold, withdrawn }

extension ListingStatusX on ListingStatus {
  String get label => switch (this) {
    ListingStatus.active => 'Active',
    ListingStatus.reserved => 'Reserved',
    ListingStatus.sold => 'Sold',
    ListingStatus.withdrawn => 'Withdrawn',
  };

  static ListingStatus fromId(String value) => ListingStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ListingStatus.active,
  );
}

/// Who the listing is offered to — drives the supply chain.
enum ListingChannel { toBuyers, toExporters }

extension ListingChannelX on ListingChannel {
  String get label => switch (this) {
    ListingChannel.toBuyers => 'Open to Buyers',
    ListingChannel.toExporters => 'Open to Exporters',
  };

  static ListingChannel fromId(String value) =>
      ListingChannel.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ListingChannel.toBuyers,
      );
}

enum PaymentStatus { pending, cleared, failed }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.pending => 'Pending',
    PaymentStatus.cleared => 'Cleared',
    PaymentStatus.failed => 'Failed',
  };

  static PaymentStatus fromId(String value) => PaymentStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => PaymentStatus.pending,
  );
}

/// Ledger entry classification.
enum LedgerType {
  laborWage,
  brokerCommission,
  productPurchase,
  transportFare,
  investment,
  jobPostingFee,
  taxiFare,
  vehicleRentFee,
  propertyRent,
}

extension LedgerTypeX on LedgerType {
  String get label => switch (this) {
    LedgerType.laborWage => 'Labor Wage',
    LedgerType.brokerCommission => 'Broker Commission',
    LedgerType.productPurchase => 'Product Purchase',
    LedgerType.transportFare => 'Transport Fare',
    LedgerType.investment => 'Investment',
    LedgerType.jobPostingFee => 'Job Posting Fee',
    LedgerType.taxiFare => 'Taxi Fare',
    LedgerType.vehicleRentFee => 'Vehicle Rent',
    LedgerType.propertyRent => 'Property Rent',
  };

  static LedgerType fromId(String value) => LedgerType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => LedgerType.laborWage,
  );
}

enum VehicleCategory { goods, passenger, rental }

extension VehicleCategoryX on VehicleCategory {
  String get label => switch (this) {
    VehicleCategory.goods => 'Goods Vehicle',
    VehicleCategory.passenger => 'Taxi / Passenger',
    VehicleCategory.rental => 'Self-Drive Rental',
  };

  String get description => switch (this) {
    VehicleCategory.goods => 'Commercial transport for agricultural goods',
    VehicleCategory.passenger => 'Auto, cab, outstation and bus travel',
    VehicleCategory.rental => 'Rented by the day, driven by the customer',
  };

  /// Rentals are billed per day; everything else is billed per kilometre.
  bool get isDailyRate => this == VehicleCategory.rental;

  static VehicleCategory fromId(String value) => VehicleCategory.values
      .firstWhere((e) => e.name == value, orElse: () => VehicleCategory.goods);
}

/// Lifecycle for a property lease enquiry.
enum EnquiryStatus { open, shortlisted, agreed, declined }

extension EnquiryStatusX on EnquiryStatus {
  String get label => switch (this) {
    EnquiryStatus.open => 'Open',
    EnquiryStatus.shortlisted => 'Shortlisted',
    EnquiryStatus.agreed => 'Agreed',
    EnquiryStatus.declined => 'Declined',
  };

  static EnquiryStatus fromId(String value) => EnquiryStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => EnquiryStatus.open,
  );
}

enum BookingStatus { requested, confirmed, enRoute, delivered, cancelled }

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
    BookingStatus.requested => 'Requested',
    BookingStatus.confirmed => 'Confirmed',
    BookingStatus.enRoute => 'En Route',
    BookingStatus.delivered => 'Completed',
    BookingStatus.cancelled => 'Cancelled',
  };

  static BookingStatus fromId(String value) => BookingStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => BookingStatus.requested,
  );
}
