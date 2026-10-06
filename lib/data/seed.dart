import '../core/utils/crop_images.dart';
import 'local_db.dart';
import 'models/app_user.dart';
import 'models/enums.dart';
import 'models/farm.dart';
import 'models/job.dart';
import 'edu_content.dart';
import 'learning_content.dart';
import 'models/learning.dart';
import 'models/ledger.dart';
import 'models/listing.dart';
import 'models/property.dart';
import 'models/role_subtype.dart';
import 'models/shop.dart';
import 'models/vehicle.dart';

/// Seeds demo marketplace data on first launch so every role dashboard
/// has realistic content. Karnataka districts, INR pricing.
class Seed {
  Seed._();

  // Bumped to v5: adds learning-platform accounts, student profiles, daily
  // progress and activity history, so existing installs must re-seed to pick
  // up a populated leaderboard.
  // v6: students moved onto UserRole.student. Existing installs seeded at v5
  // hold students on marketplace roles, which would put them in the wrong app,
  // so the bump forces a re-seed.
  // v7: seeded video history is now per-track. v6 installs recorded an agri
  // lesson title for students, surfacing agri-market content in the education
  // app's Progress tab, so the bump forces a re-seed.
  // v8: peer-to-peer vehicle rental. Existing installs have no member-listed
  // vehicles at all, so the Rent tab would open empty and read as broken
  // rather than as a new feature — the bump forces a re-seed.
  // v9: multi-role accounts with a header role switcher. Ramesh Gowda now
  // holds Landowner, Driver and Shopkeeper, and the new Landowner / Driver /
  // Shopkeeper dashboards need plots, trips, shop stock and orders, so the
  // bump forces a re-seed.
  static const _kSeeded = 'seed_v9';

  static Future<void> ensure() async {
    final db = LocalDb.instance;
    if (db.setting<bool>(_kSeeded, false)) return;

    final now = DateTime.now();

    final people = <AppUser>[
      AppUser(
        id: 'u_landowner_1',
        phone: '+919845010001',
        countryCode: '+91',
        name: 'Ramesh Gowda',
        role: UserRole.landowner,
        // Farms, drives his own pickup in the off-season and runs the family
        // provision store — the three roles the header switcher demonstrates.
        roles: [UserRole.landowner, UserRole.transport, UserRole.shopkeeper],
        district: 'Mandya',
        city: 'Maddur',
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      AppUser(
        id: 'u_landowner_2',
        phone: '+919845010002',
        countryCode: '+91',
        name: 'Lakshmamma B',
        role: UserRole.landowner,
        district: 'Hassan',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      AppUser(
        id: 'u_buyer_1',
        phone: '+919845020001',
        countryCode: '+91',
        name: 'Suresh Traders',
        role: UserRole.buyer,
        subtype: RoleSubtype.wholesaleHarvestBuyer,
        district: 'Bengaluru Rural',
        createdAt: now.subtract(const Duration(days: 75)),
      ),
      AppUser(
        id: 'u_buyer_2',
        phone: '+919845020002',
        countryCode: '+91',
        name: 'Geetha Provisions',
        role: UserRole.buyer,
        subtype: RoleSubtype.retailMarketBuyer,
        district: 'Mysuru',
        createdAt: now.subtract(const Duration(days: 44)),
      ),
      AppUser(
        id: 'u_broker_1',
        phone: '+919845030001',
        countryCode: '+91',
        name: 'Kiran Shetty',
        role: UserRole.broker,
        subtype: RoleSubtype.cropCommissionDeal,
        district: 'Mysuru',
        verificationStatus: VerificationStatus.approved,
        createdAt: now.subtract(const Duration(days: 50)),
      ),
      AppUser(
        id: 'u_broker_2',
        phone: '+919845030002',
        countryCode: '+91',
        name: 'Anitha Rao',
        role: UserRole.broker,
        subtype: RoleSubtype.labourAgentContract,
        district: 'Tumakuru',
        verificationStatus: VerificationStatus.pending,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      AppUser(
        id: 'u_laborer_1',
        phone: '+919845040001',
        countryCode: '+91',
        name: 'Manjunath K',
        role: UserRole.laborer,
        subtype: RoleSubtype.singleAndGroup,
        laborerType: LaborerType.singleWorker,
        district: 'Mandya',
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      AppUser(
        id: 'u_laborer_2',
        phone: '+919845040002',
        countryCode: '+91',
        name: 'Shivamma Group',
        role: UserRole.laborer,
        subtype: RoleSubtype.singleAndGroup,
        laborerType: LaborerType.groupWork,
        district: 'Mandya',
        createdAt: now.subtract(const Duration(days: 35)),
      ),
      AppUser(
        id: 'u_laborer_3',
        phone: '+919845040003',
        countryCode: '+91',
        name: 'Basavaraju N',
        role: UserRole.laborer,
        subtype: RoleSubtype.dailyHarvestWork,
        laborerType: LaborerType.groupWork,
        district: 'Hassan',
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      AppUser(
        id: 'u_laborer_4',
        phone: '+919845040004',
        countryCode: '+91',
        name: 'Prakash Tractor Works',
        role: UserRole.laborer,
        subtype: RoleSubtype.skilledFieldOperator,
        laborerType: LaborerType.singleWorker,
        district: 'Mandya',
        createdAt: now.subtract(const Duration(days: 22)),
      ),
      AppUser(
        id: 'u_transport_1',
        phone: '+919845050001',
        countryCode: '+91',
        name: 'Vinayaka Logistics',
        role: UserRole.transport,
        subtype: RoleSubtype.heavyTransportTruck,
        district: 'Mysuru',
        createdAt: now.subtract(const Duration(days: 55)),
      ),
      AppUser(
        id: 'u_transport_2',
        phone: '+919845050002',
        countryCode: '+91',
        name: 'Chamundi Pickup Service',
        role: UserRole.transport,
        subtype: RoleSubtype.pickupLightCommercial,
        district: 'Mandya',
        createdAt: now.subtract(const Duration(days: 26)),
      ),
      AppUser(
        id: 'u_taxi_1',
        phone: '+919845060001',
        countryCode: '+91',
        name: 'Mysuru City Cabs',
        role: UserRole.taxiService,
        subtype: RoleSubtype.localAutoCab,
        district: 'Mysuru',
        verificationStatus: VerificationStatus.approved,
        createdAt: now.subtract(const Duration(days: 33)),
      ),
      AppUser(
        id: 'u_taxi_2',
        phone: '+919845060002',
        countryCode: '+91',
        name: 'Kaveri Travels',
        role: UserRole.taxiService,
        subtype: RoleSubtype.travellerBus,
        district: 'Mandya',
        verificationStatus: VerificationStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppUser(
        id: 'u_rental_1',
        phone: '+919845070001',
        countryCode: '+91',
        name: 'Hassan Wheels Rentals',
        role: UserRole.vehicleRental,
        subtype: RoleSubtype.carRental,
        district: 'Hassan',
        verificationStatus: VerificationStatus.approved,
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      AppUser(
        id: 'u_property_1',
        phone: '+919845080001',
        countryCode: '+91',
        name: 'Nanjundaswamy Estates',
        role: UserRole.propertyOwner,
        subtype: RoleSubtype.agricultureLandLease,
        district: 'Mandya',
        createdAt: now.subtract(const Duration(days: 47)),
      ),
      AppUser(
        id: 'u_investor_1',
        phone: '+6591230001',
        countryCode: '+65',
        name: 'Daniel Tan',
        role: UserRole.foreignInvestor,
        subtype: RoleSubtype.farmInfrastructureEquity,
        companyName: 'GreenAsia Capital',
        country: 'Singapore',
        district: 'Bengaluru Urban',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      AppUser(
        id: 'u_exporter_1',
        phone: '+9715012345',
        countryCode: '+971',
        name: 'Al Noor Foods',
        role: UserRole.globalExporter,
        subtype: RoleSubtype.internationalExportBatch,
        companyName: 'Al Noor Foods FZE',
        registrationNo: 'FZE-88213',
        country: 'United Arab Emirates',
        district: 'Bengaluru Urban',
        verificationStatus: VerificationStatus.approved,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      AppUser(
        id: 'u_exporter_2',
        phone: '+4477001234',
        countryCode: '+44',
        name: 'Britannia Produce',
        role: UserRole.globalExporter,
        subtype: RoleSubtype.interStateWholesaleExport,
        companyName: 'Britannia Produce Ltd',
        registrationNo: 'UK-4471902',
        country: 'United Kingdom',
        district: 'Bengaluru Urban',
        verificationStatus: VerificationStatus.pending,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppUser(
        id: 'u_admin_1',
        phone: '+919000000000',
        countryCode: '+91',
        name: 'BLOB Operations',
        role: UserRole.admin,
        district: 'Bengaluru Urban',
        createdAt: now.subtract(const Duration(days: 120)),
      ),

      // --- Learning platform accounts ---
      // These carry a UserCategory, which is what unlocks the Learn tab and
      // puts them on the leaderboard. Sign in as +919845050001 to land on a
      // student account with an existing streak and history.
      //
      // Students hold UserRole.student, which maps to an empty permission set,
      // so no marketplace surface is reachable from their app at all. They
      // deliberately carry no subtype or laborerType: those are marketplace
      // specialisations and mean nothing on the education track.
      AppUser(
        id: 'u_student_1',
        phone: '+919845050001',
        countryCode: '+91',
        name: 'Divya S',
        role: UserRole.student,
        district: 'Mandya',
        category: UserCategory.student,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      AppUser(
        id: 'u_student_2',
        phone: '+919845050002',
        countryCode: '+91',
        name: 'Arjun Patil',
        role: UserRole.student,
        district: 'Belagavi',
        category: UserCategory.student,
        createdAt: now.subtract(const Duration(days: 26)),
      ),
      AppUser(
        id: 'u_student_3',
        phone: '+919845050003',
        countryCode: '+91',
        name: 'Fathima Noor',
        role: UserRole.student,
        district: 'Mysuru',
        category: UserCategory.student,
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      AppUser(
        id: 'u_seeker_1',
        phone: '+919845050004',
        countryCode: '+91',
        name: 'Ravi Kumar',
        role: UserRole.laborer,
        subtype: RoleSubtype.singleAndGroup,
        laborerType: LaborerType.singleWorker,
        district: 'Hassan',
        category: UserCategory.jobSeeker,
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      AppUser(
        id: 'u_seeker_2',
        phone: '+919845050005',
        countryCode: '+91',
        name: 'Sneha Raikar',
        role: UserRole.laborer,
        subtype: RoleSubtype.dailyHarvestWork,
        laborerType: LaborerType.groupWork,
        district: 'Tumakuru',
        category: UserCategory.jobSeeker,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
    ];

    for (final u in people) {
      await db.put(LocalDb.users, u.id, u.toMap());
    }

    final listings = <Listing>[
      Listing(
        id: 'l_1',
        ownerId: 'u_landowner_1',
        ownerName: 'Ramesh Gowda',
        ownerRole: UserRole.landowner,
        cropName: 'Paddy (Sona Masuri)',
        description: 'Freshly harvested, sun-dried, moisture below 14%.',
        imageAsset: CropImages.paddy,
        quantityQuintal: 120,
        pricePerQuintalPaise: 230000,
        district: 'Mandya',
        channel: ListingChannel.toBuyers,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Listing(
        id: 'l_2',
        ownerId: 'u_landowner_1',
        ownerName: 'Ramesh Gowda',
        ownerRole: UserRole.landowner,
        cropName: 'Sugarcane',
        description: 'Ready for mill delivery, 10 acre yield.',
        imageAsset: CropImages.sugarcane,
        quantityQuintal: 800,
        pricePerQuintalPaise: 34000,
        district: 'Mandya',
        channel: ListingChannel.toBuyers,
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      Listing(
        id: 'l_7',
        ownerId: 'u_landowner_1',
        ownerName: 'Ramesh Gowda',
        ownerRole: UserRole.landowner,
        cropName: 'Turmeric Fingers',
        description: 'Polished fingers, high curcumin, double boiled.',
        imageAsset: CropImages.turmeric,
        quantityQuintal: 60,
        pricePerQuintalPaise: 890000,
        district: 'Mandya',
        channel: ListingChannel.toBuyers,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      Listing(
        id: 'l_3',
        ownerId: 'u_landowner_2',
        ownerName: 'Lakshmamma B',
        ownerRole: UserRole.landowner,
        cropName: 'Arabica Coffee Parchment',
        description: 'Shade grown, hand picked, Grade A beans.',
        imageAsset: CropImages.coffee,
        quantityQuintal: 45,
        pricePerQuintalPaise: 1850000,
        district: 'Hassan',
        channel: ListingChannel.toBuyers,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Listing(
        id: 'l_4',
        ownerId: 'u_landowner_2',
        ownerName: 'Lakshmamma B',
        ownerRole: UserRole.landowner,
        cropName: 'Ragi (Finger Millet)',
        description: 'Organic, no chemical fertiliser used.',
        imageAsset: CropImages.ragi,
        quantityQuintal: 60,
        pricePerQuintalPaise: 380000,
        district: 'Hassan',
        channel: ListingChannel.toBuyers,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      Listing(
        id: 'l_5',
        ownerId: 'u_buyer_1',
        ownerName: 'Suresh Traders',
        ownerRole: UserRole.buyer,
        cropName: 'Byadagi Red Chilli',
        description: 'Graded and packed, export ready in 50kg bales.',
        imageAsset: CropImages.chilli,
        quantityQuintal: 200,
        pricePerQuintalPaise: 1420000,
        district: 'Bengaluru Rural',
        channel: ListingChannel.toExporters,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Listing(
        id: 'l_6',
        ownerId: 'u_buyer_1',
        ownerName: 'Suresh Traders',
        ownerRole: UserRole.buyer,
        cropName: 'Turmeric Fingers',
        description: 'Polished, curcumin 3.2%, fumigation certified.',
        imageAsset: CropImages.turmeric,
        quantityQuintal: 150,
        pricePerQuintalPaise: 960000,
        district: 'Bengaluru Rural',
        channel: ListingChannel.toExporters,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    for (final l in listings) {
      await db.put(LocalDb.listings, l.id, l.toMap());
    }

    final jobs = <Job>[
      Job(
        id: 'j_1',
        posterId: 'u_landowner_1',
        posterName: 'Ramesh Gowda',
        posterRole: UserRole.landowner,
        title: 'Paddy harvesting crew needed',
        description:
            'Need experienced harvesting team for 10 acres. Food provided.',
        jobType: JobType.group,
        workersNeeded: 12,
        wagePerWorkerPaise: 65000,
        district: 'Mandya',
        workDate: now.add(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Job(
        id: 'j_2',
        posterId: 'u_buyer_1',
        posterName: 'Suresh Traders',
        posterRole: UserRole.buyer,
        title: 'Warehouse loading helpers',
        description: 'Loading chilli bales onto containers. 8 hour shift.',
        jobType: JobType.group,
        workersNeeded: 6,
        wagePerWorkerPaise: 80000,
        district: 'Bengaluru Rural',
        workDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Job(
        id: 'j_3',
        posterId: 'u_landowner_2',
        posterName: 'Lakshmamma B',
        posterRole: UserRole.landowner,
        title: 'Coffee estate caretaker',
        description: 'Single worker for daily estate upkeep and irrigation.',
        jobType: JobType.single,
        workersNeeded: 1,
        wagePerWorkerPaise: 55000,
        district: 'Hassan',
        workDate: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    for (final j in jobs) {
      await db.put(LocalDb.jobs, j.id, j.toMap());
    }

    final vehicles = <Vehicle>[
      // ---- Transport goods: pickup / light commercial ----
      Vehicle(
        id: 'v_1',
        ownerId: 'u_transport_2',
        ownerName: 'Chamundi Pickup Service',
        category: VehicleCategory.goods,
        subtype: RoleSubtype.pickupLightCommercial,
        vehicleType: 'Tata 407 Mini Truck',
        registrationNumber: 'KA 11 C 1234',
        capacityValue: 2.5,
        ratePerKmPaise: 2800,
        district: 'Mandya',
      ),
      Vehicle(
        id: 'v_2',
        ownerId: 'u_transport_2',
        ownerName: 'Chamundi Pickup Service',
        category: VehicleCategory.goods,
        subtype: RoleSubtype.pickupLightCommercial,
        vehicleType: 'Mahindra Bolero Pickup',
        registrationNumber: 'KA 11 C 7788',
        capacityValue: 1.5,
        ratePerKmPaise: 2100,
        district: 'Mandya',
      ),
      // ---- Transport goods: heavy trucks ----
      Vehicle(
        id: 'v_3',
        ownerId: 'u_transport_1',
        ownerName: 'Vinayaka Logistics',
        category: VehicleCategory.goods,
        subtype: RoleSubtype.heavyTransportTruck,
        vehicleType: 'Ashok Leyland 10-Wheeler',
        registrationNumber: 'KA 09 D 8890',
        capacityValue: 16,
        ratePerKmPaise: 6500,
        district: 'Mysuru',
      ),
      Vehicle(
        id: 'v_4',
        ownerId: 'u_transport_1',
        ownerName: 'Vinayaka Logistics',
        category: VehicleCategory.goods,
        subtype: RoleSubtype.heavyTransportTruck,
        vehicleType: 'Tata Signa Trailer',
        registrationNumber: 'KA 09 D 9921',
        capacityValue: 28,
        ratePerKmPaise: 9200,
        district: 'Mysuru',
      ),
      // ---- Taxi service ----
      Vehicle(
        id: 'v_5',
        ownerId: 'u_taxi_1',
        ownerName: 'Mysuru City Cabs',
        category: VehicleCategory.passenger,
        subtype: RoleSubtype.localAutoCab,
        vehicleType: 'Bajaj RE Auto Rickshaw',
        registrationNumber: 'KA 09 M 2201',
        capacityValue: 3,
        ratePerKmPaise: 1800,
        district: 'Mysuru',
      ),
      Vehicle(
        id: 'v_6',
        ownerId: 'u_taxi_1',
        ownerName: 'Mysuru City Cabs',
        category: VehicleCategory.passenger,
        subtype: RoleSubtype.outstationCab,
        vehicleType: 'Toyota Etios Sedan',
        registrationNumber: 'KA 09 N 5510',
        capacityValue: 4,
        ratePerKmPaise: 2400,
        district: 'Mysuru',
      ),
      Vehicle(
        id: 'v_7',
        ownerId: 'u_taxi_1',
        ownerName: 'Mysuru City Cabs',
        category: VehicleCategory.passenger,
        subtype: RoleSubtype.travellerBus,
        vehicleType: 'Force Traveller 26-Seater',
        registrationNumber: 'KA 09 E 4412',
        capacityValue: 26,
        ratePerKmPaise: 3600,
        district: 'Mysuru',
      ),
      // ---- Vehicle rent (self-drive, billed per day) ----
      Vehicle(
        id: 'v_8',
        ownerId: 'u_rental_1',
        ownerName: 'Hassan Wheels Rentals',
        category: VehicleCategory.rental,
        subtype: RoleSubtype.carRental,
        vehicleType: 'Maruti Swift Dzire',
        registrationNumber: 'KA 13 R 3390',
        capacityValue: 5,
        ratePerDayPaise: 180000,
        district: 'Hassan',
      ),
      Vehicle(
        id: 'v_9',
        ownerId: 'u_rental_1',
        ownerName: 'Hassan Wheels Rentals',
        category: VehicleCategory.rental,
        subtype: RoleSubtype.jeepSuvRental,
        vehicleType: 'Mahindra Bolero Neo',
        registrationNumber: 'KA 13 R 4412',
        capacityValue: 7,
        ratePerDayPaise: 250000,
        district: 'Hassan',
      ),
      Vehicle(
        id: 'v_10',
        ownerId: 'u_rental_1',
        ownerName: 'Hassan Wheels Rentals',
        category: VehicleCategory.rental,
        subtype: RoleSubtype.bikeScooterRental,
        vehicleType: 'Honda Activa 6G',
        registrationNumber: 'KA 13 S 9087',
        capacityValue: 2,
        ratePerDayPaise: 45000,
        district: 'Hassan',
      ),
      // Ramesh's own pickup, used when he is in his Driver role.
      Vehicle(
        id: 'v_ramesh_pickup',
        ownerId: 'u_landowner_1',
        ownerName: 'Ramesh Gowda',
        category: VehicleCategory.goods,
        subtype: RoleSubtype.pickupLightCommercial,
        vehicleType: 'Mahindra Bolero Maxi Truck',
        registrationNumber: 'KA 11 B 6610',
        capacityValue: 1.5,
        ratePerKmPaise: 2400,
        district: 'Mandya',
      ),
      // ---- Peer listings: ordinary members lending their own vehicles ----
      // Seeded from a landowner and a labourer, not a rental account, so the
      // Rent tab demonstrates from first launch that these listings come from
      // members rather than only from registered businesses.
      Vehicle(
        id: 'v_11',
        ownerId: 'u_landowner_1',
        ownerName: 'Ramesh Gowda',
        category: VehicleCategory.rental,
        subtype: RoleSubtype.tractorImplementRental,
        vehicleType: 'Mahindra 575 DI Tractor',
        registrationNumber: 'KA 11 T 2245',
        capacityValue: 1,
        ratePerDayPaise: 160000,
        district: 'Mandya',
        peerListed: true,
        notes:
            'Rotavator and trailer included. Renter fills diesel. '
            'Within Mandya district only.',
      ),
      Vehicle(
        id: 'v_12',
        ownerId: 'u_landowner_2',
        ownerName: 'Lakshmamma B',
        category: VehicleCategory.rental,
        subtype: RoleSubtype.bikeScooterRental,
        vehicleType: 'Bajaj Platina 110',
        registrationNumber: 'KA 13 W 7781',
        capacityValue: 2,
        ratePerDayPaise: 35000,
        district: 'Hassan',
        peerListed: true,
        notes: 'Free on weekdays. Helmet provided. \u20B91,000 deposit.',
      ),
    ];

    for (final v in vehicles) {
      await db.put(LocalDb.vehicles, v.id, v.toMap());
    }

    final properties = <PropertyListing>[
      PropertyListing(
        id: 'p_1',
        ownerId: 'u_property_1',
        ownerName: 'Nanjundaswamy Estates',
        kind: RoleSubtype.agricultureLandLease,
        title: '6 acre irrigated paddy land',
        description:
            'Canal fed with borewell backup, tractor accessible, fenced. '
            'Suitable for paddy, sugarcane or vegetables.',
        areaValue: 6,
        rentPerMonthPaise: 3500000,
        depositPaise: 10000000,
        locality: 'Keragodu Road',
        district: 'Mandya',
        leaseMonthsMin: 24,
        availableFrom: now.add(const Duration(days: 14)),
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      PropertyListing(
        id: 'p_2',
        ownerId: 'u_property_1',
        ownerName: 'Nanjundaswamy Estates',
        kind: RoleSubtype.commercialBuilding,
        title: 'Godown beside APMC yard',
        description:
            'RCC godown with loading ramp, 3-phase power and night security. '
            'Ideal for grading and short-term storage.',
        areaValue: 4000,
        rentPerMonthPaise: 4500000,
        depositPaise: 27000000,
        locality: 'APMC Yard',
        district: 'Mandya',
        leaseMonthsMin: 11,
        availableFrom: now.add(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      PropertyListing(
        id: 'p_3',
        ownerId: 'u_property_1',
        ownerName: 'Nanjundaswamy Estates',
        kind: RoleSubtype.residentialQuarters,
        title: 'Worker quarters — 4 rooms',
        description:
            'Four rooms with shared kitchen, bore water and toilet block. '
            'Walking distance from the fields.',
        areaValue: 1200,
        rentPerMonthPaise: 1200000,
        depositPaise: 2400000,
        locality: 'Duddagere',
        district: 'Mandya',
        leaseMonthsMin: 6,
        availableFrom: now,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      PropertyListing(
        id: 'p_4',
        ownerId: 'u_landowner_2',
        ownerName: 'Lakshmamma B',
        kind: RoleSubtype.agricultureLandLease,
        title: 'Coffee estate block on lease',
        description:
            'Shade grown Arabica block with existing plants, pulping shed '
            'and labour lines included.',
        areaValue: 3.5,
        rentPerMonthPaise: 5500000,
        depositPaise: 11000000,
        locality: 'Sakleshpur',
        district: 'Hassan',
        leaseMonthsMin: 36,
        availableFrom: now.add(const Duration(days: 30)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    for (final p in properties) {
      await db.put(LocalDb.properties, p.id, p.toMap());
    }

    // Payment history. Without this the dashboard money rings all read zero,
    // which makes the payment tracker look broken rather than empty.
    final ledger = <LedgerEntry>[
      // Landowner 1 — crop sales, one settled and one still awaited.
      LedgerEntry(
        id: 'led_1',
        payerId: 'u_buyer_1',
        payerName: 'Suresh Traders',
        payeeId: 'u_landowner_1',
        payeeName: 'Ramesh Gowda',
        amountPaise: 3450000,
        type: LedgerType.productPurchase,
        status: PaymentStatus.cleared,
        reference: 'l_1',
        note: 'Paddy 15 quintal advance lot',
        createdAt: now.subtract(const Duration(days: 12)),
        clearedAt: now.subtract(const Duration(days: 11)),
      ),
      LedgerEntry(
        id: 'led_2',
        payerId: 'u_buyer_2',
        payerName: 'Mysuru Retail Mart',
        payeeId: 'u_landowner_1',
        payeeName: 'Ramesh Gowda',
        amountPaise: 800000,
        type: LedgerType.productPurchase,
        status: PaymentStatus.pending,
        reference: 'l_2',
        note: 'Sugarcane part payment due on delivery',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      LedgerEntry(
        id: 'led_3',
        payerId: 'u_buyer_1',
        payerName: 'Suresh Traders',
        payeeId: 'u_landowner_1',
        payeeName: 'Ramesh Gowda',
        amountPaise: 800000,
        type: LedgerType.productPurchase,
        status: PaymentStatus.cleared,
        reference: 'l_1',
        note: 'Second paddy lot',
        createdAt: now.subtract(const Duration(days: 6)),
        clearedAt: now.subtract(const Duration(days: 5)),
      ),
      // Landowner 1 paying out wages.
      LedgerEntry(
        id: 'led_4',
        payerId: 'u_landowner_1',
        payerName: 'Ramesh Gowda',
        payeeId: 'u_laborer_2',
        payeeName: 'Manjunath Crew',
        amountPaise: 1200000,
        type: LedgerType.laborWage,
        status: PaymentStatus.cleared,
        reference: 'j_1',
        note: 'Paddy harvesting crew — 6 days',
        createdAt: now.subtract(const Duration(days: 8)),
        clearedAt: now.subtract(const Duration(days: 8)),
      ),
      // Landowner 2.
      LedgerEntry(
        id: 'led_5',
        payerId: 'u_exporter_1',
        payerName: 'Global Agri Exports',
        payeeId: 'u_landowner_2',
        payeeName: 'Lakshmamma B',
        amountPaise: 8325000,
        type: LedgerType.productPurchase,
        status: PaymentStatus.cleared,
        reference: 'l_3',
        note: 'Arabica parchment 4.5 quintal',
        createdAt: now.subtract(const Duration(days: 9)),
        clearedAt: now.subtract(const Duration(days: 7)),
      ),
      LedgerEntry(
        id: 'led_6',
        payerId: 'u_buyer_1',
        payerName: 'Suresh Traders',
        payeeId: 'u_landowner_2',
        payeeName: 'Lakshmamma B',
        amountPaise: 1900000,
        type: LedgerType.productPurchase,
        status: PaymentStatus.pending,
        reference: 'l_4',
        note: 'Ragi 5 quintal awaiting quality check',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      // Buyer outgoing + broker commission.
      LedgerEntry(
        id: 'led_7',
        payerId: 'u_buyer_1',
        payerName: 'Suresh Traders',
        payeeId: 'u_broker_1',
        payeeName: 'Kiran Deals',
        amountPaise: 86250,
        type: LedgerType.brokerCommission,
        status: PaymentStatus.cleared,
        reference: 'l_1',
        note: '2.5% commission on paddy deal',
        createdAt: now.subtract(const Duration(days: 11)),
        clearedAt: now.subtract(const Duration(days: 10)),
      ),
      LedgerEntry(
        id: 'led_8',
        payerId: 'u_exporter_1',
        payerName: 'Global Agri Exports',
        payeeId: 'u_broker_1',
        payeeName: 'Kiran Deals',
        amountPaise: 208125,
        type: LedgerType.brokerCommission,
        status: PaymentStatus.pending,
        reference: 'l_3',
        note: '2.5% commission on coffee export lot',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      // Transport, taxi, rental and property income.
      LedgerEntry(
        id: 'led_9',
        payerId: 'u_landowner_1',
        payerName: 'Ramesh Gowda',
        payeeId: 'u_transport_1',
        payeeName: 'Mandya Goods Carrier',
        amountPaise: 450000,
        type: LedgerType.transportFare,
        status: PaymentStatus.cleared,
        reference: 'b_1',
        note: 'Mandya to Bengaluru APMC, 1 trip',
        createdAt: now.subtract(const Duration(days: 7)),
        clearedAt: now.subtract(const Duration(days: 7)),
      ),
      LedgerEntry(
        id: 'led_10',
        payerId: 'u_landowner_2',
        payerName: 'Lakshmamma B',
        payeeId: 'u_taxi_1',
        payeeName: 'Mysuru City Cabs',
        amountPaise: 132000,
        type: LedgerType.taxiFare,
        status: PaymentStatus.cleared,
        reference: 'b_2',
        note: 'Hassan to Mysuru outstation drop',
        createdAt: now.subtract(const Duration(days: 4)),
        clearedAt: now.subtract(const Duration(days: 4)),
      ),
      LedgerEntry(
        id: 'led_11',
        payerId: 'u_landowner_1',
        payerName: 'Ramesh Gowda',
        payeeId: 'u_rental_1',
        payeeName: 'Hassan Wheels Rentals',
        amountPaise: 360000,
        type: LedgerType.vehicleRentFee,
        status: PaymentStatus.pending,
        reference: 'b_3',
        note: 'Jeep hire, 2 days',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      LedgerEntry(
        id: 'led_12',
        payerId: 'u_buyer_1',
        payerName: 'Suresh Traders',
        payeeId: 'u_property_1',
        payeeName: 'Nanjundaswamy Estates',
        amountPaise: 4500000,
        type: LedgerType.propertyRent,
        status: PaymentStatus.cleared,
        reference: 'p_1',
        note: 'Godown monthly rent',
        createdAt: now.subtract(const Duration(days: 5)),
        clearedAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    for (final e in ledger) {
      await db.put(LocalDb.ledger, e.id, e.toMap());
    }

    await _seedRoleDashboards(db, now);
    await _seedLearning(db, now);

    await db.setSetting(_kSeeded, true);
  }

  /// Data behind the Landowner, Driver and Shopkeeper dashboards for the
  /// multi-role demo account (Ramesh Gowda, Maddur, Mandya).
  static Future<void> _seedRoleDashboards(LocalDb db, DateTime now) async {
    const me = 'u_landowner_1';
    DateTime ago(int d) => now.subtract(Duration(days: d));
    DateTime ahead(int h) => now.add(Duration(hours: h));

    // ---- Landowner: plots ----
    final plots = <FarmPlot>[
      FarmPlot(
        id: 'plot_1',
        ownerId: me,
        name: 'Canal-side field',
        acres: 3.5,
        village: 'Maddur',
        district: 'Mandya',
        soil: 'Red loam',
        irrigation: 'Canal',
        crop: 'Sugarcane',
        sownOn: ago(240),
        cropDays: 330,
        createdAt: ago(400),
      ),
      FarmPlot(
        id: 'plot_2',
        ownerId: me,
        name: 'Survey 112/3',
        acres: 2,
        village: 'Maddur',
        district: 'Mandya',
        soil: 'Black clay',
        irrigation: 'Borewell',
        crop: 'Paddy',
        sownOn: ago(98),
        cropDays: 120,
        createdAt: ago(380),
      ),
      FarmPlot(
        id: 'plot_3',
        ownerId: me,
        name: 'Tank-bed plot',
        acres: 1.25,
        village: 'Malavalli',
        district: 'Mandya',
        soil: 'Sandy loam',
        irrigation: 'Rain-fed',
        createdAt: ago(200),
      ),
    ];
    for (final p in plots) {
      await db.put(LocalDb.farmPlots, p.id, p.toMap());
    }

    // ---- Driver: trips on Ramesh's pickup ----
    VehicleBooking trip(
      String id,
      String requesterId,
      String requesterName,
      String pickup,
      String drop,
      double km,
      DateTime when,
      BookingStatus status,
    ) => VehicleBooking(
      id: id,
      vehicleId: 'v_ramesh_pickup',
      vehicleLabel: 'Mahindra Bolero Maxi Truck',
      category: VehicleCategory.goods,
      requesterId: requesterId,
      requesterName: requesterName,
      providerId: me,
      pickup: pickup,
      drop: drop,
      distanceKm: km,
      farePaise: (km * 2400).round(),
      scheduledAt: when,
      status: status,
      createdAt: when.subtract(const Duration(hours: 20)),
    );
    final trips = <VehicleBooking>[
      trip('t_1', 'u_buyer_1', 'Suresh Traders', 'Maddur', 'Mandya', 18,
          ahead(5), BookingStatus.requested),
      trip('t_2', 'u_landowner_2', 'Lakshmamma B', 'Malavalli', 'Mysuru', 52,
          ahead(26), BookingStatus.requested),
      trip('t_3', 'u_buyer_1', 'Suresh Traders', 'Pandavapura', 'Bengaluru',
          110, ahead(50), BookingStatus.requested),
      trip('t_4', 'u_property_1', 'Nanjundaswamy Estates', 'Maddur',
          'Channapatna', 34, now.subtract(const Duration(minutes: 40)),
          BookingStatus.enRoute),
      trip('t_5', 'u_buyer_1', 'Suresh Traders', 'Mandya', 'Maddur', 18,
          ahead(3), BookingStatus.confirmed),
      trip('t_6', 'u_landowner_2', 'Lakshmamma B', 'Hassan', 'Mandya', 115,
          ago(1), BookingStatus.delivered),
      trip('t_7', 'u_buyer_1', 'Suresh Traders', 'Maddur', 'Ramanagara', 45,
          ago(3), BookingStatus.delivered),
      trip('t_8', 'u_property_1', 'Nanjundaswamy Estates', 'Krishnarajpet',
          'Mandya', 41, ago(9), BookingStatus.delivered),
    ];
    for (final t in trips) {
      await db.put(LocalDb.bookings, t.id, t.toMap());
    }

    // ---- Shopkeeper: Gowda Provision Stores ----
    ShopItem item(String id, String name, String unit, double qty,
            double reorder, int priceRupees, String supplier) =>
        ShopItem(
          id: id,
          shopId: me,
          name: name,
          unit: unit,
          quantity: qty,
          reorderLevel: reorder,
          pricePaise: priceRupees * 100,
          supplier: supplier,
          updatedAt: ago(1),
        );
    final stock = <ShopItem>[
      item('si_1', 'Sona Masoori rice', 'kg', 140, 50, 58, 'Suresh Traders'),
      item('si_2', 'Toor dal', 'kg', 12, 20, 145, 'Mandya APMC wholesale'),
      item('si_3', 'Jaggery (Mandya)', 'kg', 65, 25, 62, 'Ramesh Gowda farm'),
      item('si_4', 'Groundnut oil', 'litre', 0, 10, 185, 'Shree Oil Mills'),
      item('si_5', 'Ragi flour', 'kg', 30, 15, 48, 'Suresh Traders'),
      item('si_6', 'Sugar', 'kg', 8, 25, 44, 'Mandya APMC wholesale'),
      item('si_7', 'Urea fertiliser', 'bag', 22, 10, 270, 'Krishi Seva Kendra'),
      item('si_8', 'Tea powder', 'packet', 40, 12, 120, 'Shree Distributors'),
    ];
    for (final i in stock) {
      await db.put(LocalDb.shopItems, i.id, i.toMap());
    }

    final orders = <ShopOrder>[
      ShopOrder(
        id: 'so_1',
        shopId: me,
        customerName: 'Kavitha M',
        customerPhone: '+919845011221',
        itemsSummary: 'Rice 10 kg, Toor dal 2 kg, Sugar 2 kg',
        totalPaise: 96800,
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
      ShopOrder(
        id: 'so_2',
        shopId: me,
        customerName: 'Manjunath K',
        customerPhone: '+919845011876',
        itemsSummary: 'Urea 2 bags',
        totalPaise: 54000,
        status: ShopOrderStatus.packed,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      ShopOrder(
        id: 'so_3',
        shopId: me,
        customerName: 'Shobha R',
        customerPhone: '+919845012009',
        itemsSummary: 'Ragi flour 5 kg, Jaggery 2 kg, Tea 1 pkt',
        totalPaise: 48400,
        status: ShopOrderStatus.delivered,
        paid: true,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      ShopOrder(
        id: 'so_4',
        shopId: me,
        customerName: 'Basavaraju',
        customerPhone: '+919845013310',
        itemsSummary: 'Rice 25 kg, Groundnut oil 2 L',
        totalPaise: 182000,
        status: ShopOrderStatus.delivered,
        createdAt: ago(2),
      ),
      ShopOrder(
        id: 'so_5',
        shopId: me,
        customerName: 'Geetha S',
        customerPhone: '+919845014471',
        itemsSummary: 'Sugar 5 kg, Tea 2 pkt',
        totalPaise: 46000,
        status: ShopOrderStatus.delivered,
        paid: true,
        createdAt: ago(1),
      ),
    ];
    for (final o in orders) {
      await db.put(LocalDb.shopOrders, o.id, o.toMap());
    }
  }

  /// Seeds the learning platform: student profiles, a back-dated streak of
  /// daily progress, and the matching activity history.
  ///
  /// Without this, a fresh install shows an empty leaderboard and an empty
  /// history — the two screens that are meant to motivate the user look
  /// broken. Progress rows are written relative to *today*, so the streak is
  /// always live no matter when the app is first opened.
  static Future<void> _seedLearning(LocalDb db, DateTime now) async {
    // Student academic profiles (Step 3 of the signup flow).
    final profiles = <StudentProfile>[
      StudentProfile(
        userId: 'u_student_1',
        tenthMarksCardNumber: 'KSEEB/2021/884517',
        currentClass: 'Undergraduate — 2nd year',
        collegeName: 'PES College of Engineering, Mandya',
        goals:
            'Finish my B.E. in agricultural engineering and set up a soil '
            'testing service for farmers in my taluk.',
        updatedAt: now.subtract(const Duration(days: 29)),
      ),
      StudentProfile(
        userId: 'u_student_2',
        tenthMarksCardNumber: 'KSEEB/2022/701244',
        currentClass: 'Class 12',
        collegeName: 'Government PU College, Belagavi',
        goals:
            'Clear the CET exam and get an agriculture seat, then help run '
            'our family sugarcane land more scientifically.',
        updatedAt: now.subtract(const Duration(days: 25)),
      ),
      StudentProfile(
        userId: 'u_student_3',
        tenthMarksCardNumber: 'KSEEB/2020/553108',
        currentClass: 'ITI / Diploma',
        collegeName: 'Government ITI, Mysuru',
        goals:
            'Complete my diploma in food processing and start a small turmeric '
            'grading unit with two of my classmates.',
        updatedAt: now.subtract(const Duration(days: 20)),
      ),
    ];

    for (final p in profiles) {
      await db.put(LocalDb.studentProfiles, p.userId, p.toMap());
    }

    // Back-dated activity. `daysAgo` 0 is today; the streak logic walks
    // backwards from today-or-yesterday, so leaving a gap breaks the run on
    // purpose (u_seeker_2 below demonstrates a broken streak).
    //
    // Points must match DailyTaskType: video 30, games 30, quiz 40.
    final plans = <_LearningDay>[
      // Divya — 6-day unbroken run including today, all three tasks done.
      for (var d = 0; d < 6; d++)
        _LearningDay(
          'u_student_1',
          d,
          video: 15,
          games: 3,
          quiz: 10,
          correct: d.isEven ? 9 : 8,
        ),
      // Arjun — 4-day run, today only partly done so his card shows progress.
      _LearningDay('u_student_2', 0, video: 15, games: 1, quiz: 0, correct: 0),
      for (var d = 1; d < 4; d++)
        _LearningDay(
          'u_student_2',
          d,
          video: 15,
          games: 3,
          quiz: 10,
          correct: 7,
        ),
      // Fathima — started yesterday, strong quiz scores.
      for (var d = 1; d < 3; d++)
        _LearningDay(
          'u_student_3',
          d,
          video: 15,
          games: 3,
          quiz: 10,
          correct: 10,
        ),
      // Ravi — casual user, video only.
      for (var d = 0; d < 3; d++)
        _LearningDay('u_seeker_1', d, video: 15, games: 0, quiz: 0, correct: 0),
      // Sneha — lapsed: last active 5 days ago, so her streak reads 0 while
      // her points remain. This proves the streak reset path works.
      for (var d = 5; d < 8; d++)
        _LearningDay(
          'u_seeker_2',
          d,
          video: 15,
          games: 3,
          quiz: 10,
          correct: 6,
        ),
    ];

    var activitySeq = 0;
    for (final plan in plans) {
      final date = now.subtract(Duration(days: plan.daysAgo));
      final dayKey = DailyProgress.dayKeyOf(date);

      var points = 0;
      if (plan.video >= DailyTaskType.video.target) {
        points += DailyTaskType.video.points;
      }
      if (plan.games >= DailyTaskType.games.target) {
        points += DailyTaskType.games.points;
      }
      if (plan.quiz >= DailyTaskType.quiz.target) {
        points += DailyTaskType.quiz.points;
      }

      await db.put(
        LocalDb.dailyProgress,
        DailyProgress.keyFor(plan.userId, date),
        DailyProgress(
          userId: plan.userId,
          dayKey: dayKey,
          videoMinutes: plan.video,
          gamesPlayed: plan.games,
          quizAnswered: plan.quiz,
          quizCorrect: plan.correct,
          pointsEarned: points,
        ).toMap(),
      );

      // One history row per task actually completed, timed through the
      // evening so the history list reads in a believable order.
      final base = DateTime(date.year, date.month, date.day, 18);

      if (plan.video >= DailyTaskType.video.target) {
        activitySeq++;
        // Seeded history must match the track the user actually studies in.
        // A single hardcoded agri title put "Soil Health & Crop Rotation" in
        // the student Progress tab, i.e. agri-market content inside the
        // education app.
        final isStudent = plan.userId.startsWith('u_student_');
        final watched = isStudent
            ? EduContent.todaysVideo.title
            : LearningContent.todaysVideo.title;
        await db.put(
          LocalDb.activities,
          'act_seed_$activitySeq',
          ActivityRecord(
            id: 'act_seed_$activitySeq',
            userId: plan.userId,
            type: DailyTaskType.video,
            title: 'Watched: $watched',
            points: DailyTaskType.video.points,
            createdAt: base,
          ).toMap(),
        );
      }
      if (plan.games >= DailyTaskType.games.target) {
        activitySeq++;
        await db.put(
          LocalDb.activities,
          'act_seed_$activitySeq',
          ActivityRecord(
            id: 'act_seed_$activitySeq',
            userId: plan.userId,
            type: DailyTaskType.games,
            title: 'Completed 3 learning games',
            points: DailyTaskType.games.points,
            score: plan.games,
            outOf: DailyTaskType.games.target,
            createdAt: base.add(const Duration(minutes: 25)),
          ).toMap(),
        );
      }
      if (plan.quiz >= DailyTaskType.quiz.target) {
        activitySeq++;
        await db.put(
          LocalDb.activities,
          'act_seed_$activitySeq',
          ActivityRecord(
            id: 'act_seed_$activitySeq',
            userId: plan.userId,
            type: DailyTaskType.quiz,
            title: 'Daily quiz — ${plan.correct}/${plan.quiz} correct',
            points: DailyTaskType.quiz.points,
            score: plan.correct,
            outOf: plan.quiz,
            createdAt: base.add(const Duration(minutes: 50)),
          ).toMap(),
        );
      }
    }
  }
}

/// One seeded day of learning activity for one user.
class _LearningDay {
  const _LearningDay(
    this.userId,
    this.daysAgo, {
    required this.video,
    required this.games,
    required this.quiz,
    required this.correct,
  });

  final String userId;

  /// 0 = today.
  final int daysAgo;
  final int video;
  final int games;
  final int quiz;
  final int correct;
}
