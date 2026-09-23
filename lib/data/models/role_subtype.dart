import 'package:flutter/material.dart';

import 'enums.dart';

/// A single, unified sub-type taxonomy for every role on BLOB.
///
/// Deliberately ONE enum rather than eight per-role enums: screens ask
/// [RoleSubtypeX.forRole] and render whatever comes back, so adding a
/// specialisation to any role is a one-line change with zero UI edits and
/// no per-role branching anywhere in the app.
enum RoleSubtype {
  // ---- Buyer ----
  wholesaleHarvestBuyer,
  retailMarketBuyer,

  // ---- Labourer ----
  singleAndGroup,
  dailyHarvestWork,
  skilledFieldOperator,

  // ---- Broker ----
  cropCommissionDeal,
  labourAgentContract,

  // ---- Transport goods ----
  pickupLightCommercial,
  heavyTransportTruck,

  // ---- Foreign investor ----
  farmInfrastructureEquity,
  agriTechExpansion,
  structuralCapital,

  // ---- Global exporter ----
  internationalExportBatch,
  interStateWholesaleExport,

  // ---- Taxi service ----
  localAutoCab,
  outstationCab,
  travellerBus,

  // ---- Vehicle rent ----
  carRental,
  jeepSuvRental,
  bikeScooterRental,

  /// Farm machinery let out by the day. Added for peer-to-peer rental: an
  /// idle tractor or tiller is the single most valuable thing one farmer can
  /// lend another, and it fits none of the car/bike kinds above.
  tractorImplementRental,

  // ---- Property, land & rental ----
  agricultureLandLease,
  commercialBuilding,
  residentialQuarters,
}

extension RoleSubtypeX on RoleSubtype {
  String get id => name;

  /// The role this specialisation belongs to.
  UserRole get role => switch (this) {
    RoleSubtype.wholesaleHarvestBuyer ||
    RoleSubtype.retailMarketBuyer => UserRole.buyer,
    RoleSubtype.singleAndGroup ||
    RoleSubtype.dailyHarvestWork ||
    RoleSubtype.skilledFieldOperator => UserRole.laborer,
    RoleSubtype.cropCommissionDeal ||
    RoleSubtype.labourAgentContract => UserRole.broker,
    RoleSubtype.pickupLightCommercial ||
    RoleSubtype.heavyTransportTruck => UserRole.transport,
    RoleSubtype.farmInfrastructureEquity ||
    RoleSubtype.agriTechExpansion ||
    RoleSubtype.structuralCapital => UserRole.foreignInvestor,
    RoleSubtype.internationalExportBatch ||
    RoleSubtype.interStateWholesaleExport => UserRole.globalExporter,
    RoleSubtype.localAutoCab ||
    RoleSubtype.outstationCab ||
    RoleSubtype.travellerBus => UserRole.taxiService,
    RoleSubtype.carRental ||
    RoleSubtype.jeepSuvRental ||
    RoleSubtype.bikeScooterRental ||
    RoleSubtype.tractorImplementRental => UserRole.vehicleRental,
    RoleSubtype.agricultureLandLease ||
    RoleSubtype.commercialBuilding ||
    RoleSubtype.residentialQuarters => UserRole.propertyOwner,
  };

  String get label => switch (this) {
    RoleSubtype.wholesaleHarvestBuyer => 'Wholesale Harvest Buyer',
    RoleSubtype.retailMarketBuyer => 'Retail Market Buyer',
    RoleSubtype.singleAndGroup => 'Single & Group',
    RoleSubtype.dailyHarvestWork => 'Daily Harvest Works',
    RoleSubtype.skilledFieldOperator => 'Skilled Field Operator',
    RoleSubtype.cropCommissionDeal => 'Crop Commission Deal',
    RoleSubtype.labourAgentContract => 'Labour Agent Contract',
    RoleSubtype.pickupLightCommercial => 'Pickup / Light Commercial',
    RoleSubtype.heavyTransportTruck => 'Heavy Transport Trucks',
    RoleSubtype.farmInfrastructureEquity => 'Farm Infrastructure Equity',
    RoleSubtype.agriTechExpansion => 'Agri-Tech Expansion',
    RoleSubtype.structuralCapital => 'Structural Capital',
    RoleSubtype.internationalExportBatch => 'International Export Batch',
    RoleSubtype.interStateWholesaleExport => 'Inter-State Wholesale Export',
    RoleSubtype.localAutoCab => 'Local Auto / Cab',
    RoleSubtype.outstationCab => 'Outstation Cab',
    RoleSubtype.travellerBus => 'Traveller / Bus',
    RoleSubtype.carRental => 'Car Rental',
    RoleSubtype.jeepSuvRental => 'Jeep / SUV',
    RoleSubtype.bikeScooterRental => 'Bike / Scooter',
    RoleSubtype.tractorImplementRental => 'Tractor / Farm Equipment',
    RoleSubtype.agricultureLandLease => 'Agriculture Land Lease',
    RoleSubtype.commercialBuilding => 'Commercial Building',
    RoleSubtype.residentialQuarters => 'Residential House / Quarters',
  };

  String get description => switch (this) {
    RoleSubtype.wholesaleHarvestBuyer =>
      'Bulk lots straight off the field, quintal pricing',
    RoleSubtype.retailMarketBuyer =>
      'Smaller graded lots for shops and mandi resale',
    RoleSubtype.singleAndGroup =>
      'Individual work or a team you bring with you',
    RoleSubtype.dailyHarvestWork => 'Day-wage harvesting, sorting and loading',
    RoleSubtype.skilledFieldOperator =>
      'Tractor, tiller, sprayer and machinery operators',
    RoleSubtype.cropCommissionDeal =>
      'Match crops to buyers, earn 2.5% on the deal',
    RoleSubtype.labourAgentContract => 'Supply work crews on contract to farms',
    RoleSubtype.pickupLightCommercial =>
      'Tempo, pickup and mini truck under 3 tonnes',
    RoleSubtype.heavyTransportTruck =>
      'Multi-axle trucks and trailers for long haul',
    RoleSubtype.farmInfrastructureEquity =>
      'Cold storage, irrigation, warehousing equity',
    RoleSubtype.agriTechExpansion =>
      'Machinery, sensors and processing technology',
    RoleSubtype.structuralCapital =>
      'Long-horizon capital across the supply chain',
    RoleSubtype.internationalExportBatch =>
      'Container batches shipped outside India',
    RoleSubtype.interStateWholesaleExport =>
      'Bulk movement between Indian states',
    RoleSubtype.localAutoCab => 'In-town auto and cab trips',
    RoleSubtype.outstationCab => 'District-to-district and long-distance cabs',
    RoleSubtype.travellerBus => 'Traveller vans and buses for groups',
    RoleSubtype.carRental => 'Self-drive hatchbacks and sedans by the day',
    RoleSubtype.jeepSuvRental => 'Jeeps and SUVs for rough farm roads',
    RoleSubtype.bikeScooterRental => 'Two-wheelers for short local runs',
    RoleSubtype.tractorImplementRental =>
      'Tractors, tillers and implements by the day',
    RoleSubtype.agricultureLandLease =>
      'Farmland leased by the acre for cultivation',
    RoleSubtype.commercialBuilding =>
      'Godowns, shops and processing units on rent',
    RoleSubtype.residentialQuarters =>
      'Houses and worker quarters on monthly rent',
  };

  IconData get icon => switch (this) {
    RoleSubtype.wholesaleHarvestBuyer => Icons.warehouse_outlined,
    RoleSubtype.retailMarketBuyer => Icons.storefront_outlined,
    RoleSubtype.singleAndGroup => Icons.groups_outlined,
    RoleSubtype.dailyHarvestWork => Icons.agriculture_outlined,
    RoleSubtype.skilledFieldOperator => Icons.build_outlined,
    RoleSubtype.cropCommissionDeal => Icons.handshake_outlined,
    RoleSubtype.labourAgentContract => Icons.assignment_ind_outlined,
    RoleSubtype.pickupLightCommercial => Icons.local_shipping_outlined,
    RoleSubtype.heavyTransportTruck => Icons.fire_truck_outlined,
    RoleSubtype.farmInfrastructureEquity => Icons.foundation_outlined,
    RoleSubtype.agriTechExpansion => Icons.precision_manufacturing_outlined,
    RoleSubtype.structuralCapital => Icons.account_balance_outlined,
    RoleSubtype.internationalExportBatch => Icons.public,
    RoleSubtype.interStateWholesaleExport => Icons.alt_route_outlined,
    RoleSubtype.localAutoCab => Icons.local_taxi_outlined,
    RoleSubtype.outstationCab => Icons.airport_shuttle_outlined,
    RoleSubtype.travellerBus => Icons.directions_bus_outlined,
    RoleSubtype.carRental => Icons.directions_car_outlined,
    RoleSubtype.jeepSuvRental => Icons.airport_shuttle,
    RoleSubtype.bikeScooterRental => Icons.two_wheeler_outlined,
    RoleSubtype.tractorImplementRental => Icons.agriculture,
    RoleSubtype.agricultureLandLease => Icons.grass_outlined,
    RoleSubtype.commercialBuilding => Icons.store_mall_directory_outlined,
    RoleSubtype.residentialQuarters => Icons.house_outlined,
  };

  /// Which fleet bucket a provider sub-type sells from, when relevant.
  VehicleCategory? get vehicleCategory => switch (role) {
    UserRole.transport => VehicleCategory.goods,
    UserRole.taxiService => VehicleCategory.passenger,
    UserRole.vehicleRental => VehicleCategory.rental,
    _ => null,
  };

  /// Unit a property sub-type is measured in.
  String get areaUnit =>
      this == RoleSubtype.agricultureLandLease ? 'acre' : 'sq ft';

  /// All specialisations offered for [role] — empty when the role has none
  /// (Landowner and Administrator are single-shape roles).
  static List<RoleSubtype> forRole(UserRole role) =>
      RoleSubtype.values.where((s) => s.role == role).toList(growable: false);

  static bool hasSubtypes(UserRole role) => forRole(role).isNotEmpty;

  /// The default selection presented for a role, or null when it has none.
  static RoleSubtype? defaultFor(UserRole role) {
    final options = forRole(role);
    return options.isEmpty ? null : options.first;
  }

  static RoleSubtype? tryFromId(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final s in RoleSubtype.values) {
      if (s.name == value) return s;
    }
    return null;
  }

  /// Sub-types that describe a rentable property.
  static List<RoleSubtype> get propertyKinds => forRole(UserRole.propertyOwner);

  /// Kinds of vehicle anyone may put up for rent. Derived from the rental
  /// role's list rather than written out again, so a kind added above appears
  /// in the peer-listing form automatically and the two can never disagree.
  static List<RoleSubtype> get rentalKinds => forRole(UserRole.vehicleRental);
}
