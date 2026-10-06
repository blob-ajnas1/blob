import 'dart:io';
import 'dart:math';

import 'package:blob/core/i18n/strings.dart';
import 'package:blob/core/rbac/permissions.dart';
import 'package:blob/core/theme/app_colors.dart';
import 'package:blob/core/utils/money.dart';
import 'package:blob/data/edu_content.dart';
import 'package:blob/data/gazetteer.dart';
import 'package:blob/data/learning_content.dart';
import 'package:blob/data/models/app_user.dart';
import 'package:blob/data/models/enums.dart';
import 'package:blob/data/models/learning.dart';
import 'package:blob/data/models/role_subtype.dart';
import 'package:blob/data/models/vehicle.dart';
import 'package:blob/data/task_content_pack.dart';
import 'package:blob/ui/auth/student_details_screen.dart';
import 'package:blob/ui/shell/track_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('INR money formatting', () {
    test('formats paise into Indian rupee notation', () {
      expect(Money.format(250000), '\u20B92,500');
      expect(Money.format(5000), '\u20B950');
    });

    test('job posting fee is fifty rupees', () {
      expect(Money.jobPostingFeePaise, 5000);
      expect(Money.format(Money.jobPostingFeePaise), '\u20B950');
    });

    test('first two posts are free', () {
      expect(Money.freeJobPostLimit, 2);
    });

    test('launch period: job posting is free, fees switched off', () {
      // Flipping this back on is a deliberate business decision; this test
      // makes sure it can't happen by accident during the free period.
      expect(Money.jobPostingFeesEnabled, isFalse);
    });

    test('broker commission is 2.5 percent', () {
      expect(Money.brokerCommissionOn(1000000), 25000);
    });

    test('rupee to paise conversion avoids float drift', () {
      expect(Money.rupeesToPaise(2300.55), 230055);
    });
  });

  group('Role sub-types', () {
    test('every sub-type maps back to exactly one role', () {
      for (final subtype in RoleSubtype.values) {
        expect(
          RoleSubtypeX.forRole(subtype.role),
          contains(subtype),
          reason: '${subtype.name} is not listed under ${subtype.role.name}',
        );
      }
    });

    test('every sub-type has a label, description and icon', () {
      for (final subtype in RoleSubtype.values) {
        expect(subtype.label, isNotEmpty);
        expect(subtype.description, isNotEmpty);
        expect(subtype.icon, isNotNull);
      }
    });

    test('roles requiring a choice expose at least two options', () {
      for (final role in UserRole.values) {
        final options = RoleSubtypeX.forRole(role);
        if (RoleSubtypeX.hasSubtypes(role)) {
          expect(options.length, greaterThanOrEqualTo(2));
          expect(RoleSubtypeX.defaultFor(role), options.first);
        } else {
          expect(options, isEmpty);
        }
      }
    });

    test('landowner and admin deliberately have no sub-types', () {
      expect(RoleSubtypeX.hasSubtypes(UserRole.landowner), isFalse);
      expect(RoleSubtypeX.hasSubtypes(UserRole.admin), isFalse);
    });

    test('id round-trips and unknown ids fall back to null', () {
      for (final subtype in RoleSubtype.values) {
        expect(RoleSubtypeX.tryFromId(subtype.id), subtype);
      }
      expect(RoleSubtypeX.tryFromId('not_a_subtype'), isNull);
      expect(RoleSubtypeX.tryFromId(null), isNull);
    });

    test('vehicle categories are wired to the right verticals', () {
      expect(
        RoleSubtype.heavyTransportTruck.vehicleCategory,
        VehicleCategory.goods,
      );
      expect(
        RoleSubtype.travellerBus.vehicleCategory,
        VehicleCategory.passenger,
      );
      expect(
        RoleSubtype.bikeScooterRental.vehicleCategory,
        VehicleCategory.rental,
      );
      expect(RoleSubtype.retailMarketBuyer.vehicleCategory, isNull);
    });

    test('only rentals are billed per day', () {
      expect(VehicleCategory.rental.isDailyRate, isTrue);
      expect(VehicleCategory.goods.isDailyRate, isFalse);
      expect(VehicleCategory.passenger.isDailyRate, isFalse);
    });

    test('land is measured in acres, buildings in square feet', () {
      expect(RoleSubtype.agricultureLandLease.areaUnit, 'acre');
      expect(RoleSubtype.commercialBuilding.areaUnit, 'sq ft');
      expect(RoleSubtype.residentialQuarters.areaUnit, 'sq ft');
    });

    test('property kinds are exactly the property owner sub-types', () {
      expect(
        RoleSubtypeX.propertyKinds,
        RoleSubtypeX.forRole(UserRole.propertyOwner),
      );
      expect(RoleSubtypeX.propertyKinds.length, 3);
    });
  });

  group('Capability RBAC', () {
    test('every marketplace role has a permission set', () {
      for (final role in UserRole.values) {
        if (role == UserRole.student) continue;
        expect(Rbac.of(role), isNotEmpty, reason: 'role ${role.name}');
      }
    });

    test('students hold no marketplace capability at all', () {
      // This empty set is the enforcement point that keeps the education app
      // free of crops, jobs, transport, property and payments: every
      // marketplace tab and action is gated on a permission, so there is
      // nothing to individually hide. Asserted explicitly because an
      // accidental grant here would silently leak marketplace surfaces into a
      // student's app.
      expect(Rbac.of(UserRole.student), isEmpty);
      for (final permission in Permission.values) {
        expect(
          Rbac.can(UserRole.student, permission),
          isFalse,
          reason: 'student must not hold ${permission.name}',
        );
      }
    });

    test('sub-types change behaviour, not just labels', () {
      // Only wholesale buyers may resell into the export channel.
      expect(
        Rbac.can(
          UserRole.buyer,
          Permission.resellToExporters,
          subtype: RoleSubtype.wholesaleHarvestBuyer,
        ),
        isTrue,
      );
      expect(
        Rbac.can(
          UserRole.buyer,
          Permission.resellToExporters,
          subtype: RoleSubtype.retailMarketBuyer,
        ),
        isFalse,
      );

      // Labour-agent brokers can hire crews; crop-commission brokers cannot.
      expect(
        Rbac.can(
          UserRole.broker,
          Permission.postJobs,
          subtype: RoleSubtype.labourAgentContract,
        ),
        isTrue,
      );
      expect(
        Rbac.can(
          UserRole.broker,
          Permission.postJobs,
          subtype: RoleSubtype.cropCommissionDeal,
        ),
        isFalse,
      );
    });

    test('a sub-type only ever adds capability, never removes it', () {
      for (final subtype in RoleSubtype.values) {
        final base = Rbac.of(subtype.role);
        final withSubtype = Rbac.of(subtype.role, subtype: subtype);
        expect(withSubtype, containsAll(base), reason: subtype.name);
      }
    });

    test('service providers own their vertical', () {
      expect(Rbac.can(UserRole.taxiService, Permission.provideTaxi), isTrue);
      expect(
        Rbac.can(UserRole.vehicleRental, Permission.manageRentals),
        isTrue,
      );
      expect(Rbac.can(UserRole.propertyOwner, Permission.listProperty), isTrue);
      // Goods transport must not be able to run a taxi business.
      expect(Rbac.can(UserRole.transport, Permission.provideTaxi), isFalse);
    });

    test('landowners can list land without switching roles', () {
      expect(Rbac.can(UserRole.landowner, Permission.listProperty), isTrue);
      expect(Rbac.can(UserRole.landowner, Permission.browseProperty), isTrue);
    });

    test('only admins can approve accounts', () {
      for (final role in UserRole.values) {
        expect(
          Rbac.can(role, Permission.approveAccounts),
          role == UserRole.admin,
          reason: 'role ${role.name}',
        );
      }
    });

    test('commercial permits gate the right roles', () {
      expect(UserRole.taxiService.requiresApproval, isTrue);
      expect(UserRole.vehicleRental.requiresApproval, isTrue);
      expect(UserRole.broker.requiresApproval, isTrue);
      expect(UserRole.globalExporter.requiresApproval, isTrue);
      expect(UserRole.landowner.requiresApproval, isFalse);
      expect(UserRole.propertyOwner.requiresApproval, isFalse);
    });
  });

  group('Localisation', () {
    test('English plus all 22 Eighth Schedule languages are available', () {
      expect(AppLanguage.values.length, 23);
      expect(AppLanguage.values.first, AppLanguage.english);
      // Every Eighth Schedule language must be present.
      const eighthSchedule = [
        'as',
        'bn',
        'brx',
        'doi',
        'gu',
        'hi',
        'kn',
        'ks',
        'kok',
        'mai',
        'ml',
        'mni',
        'mr',
        'ne',
        'or',
        'pa',
        'sa',
        'sat',
        'sd',
        'ta',
        'te',
        'ur',
      ];
      final codes = AppLanguage.values.map((l) => l.code).toSet();
      for (final code in eighthSchedule) {
        expect(codes, contains(code), reason: 'missing $code');
      }
    });

    test('language codes are unique', () {
      final codes = AppLanguage.values.map((l) => l.code).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('every language has a native and english display name', () {
      for (final lang in AppLanguage.values) {
        expect(lang.nativeName, isNotEmpty, reason: lang.code);
        expect(lang.englishName, isNotEmpty, reason: lang.code);
      }
    });

    test('right-to-left scripts are flagged', () {
      expect(AppLanguage.urdu.isRtl, isTrue);
      expect(AppLanguage.kashmiri.isRtl, isTrue);
      expect(AppLanguage.sindhi.isRtl, isTrue);
      expect(AppLanguage.hindi.isRtl, isFalse);
      expect(AppLanguage.english.isRtl, isFalse);
    });

    test('untranslated languages still resolve to readable English', () {
      // Bodo has no translation map yet; it must not leak raw keys.
      expect(S.t(AppLanguage.bodo, 'home'), S.t(AppLanguage.english, 'home'));
      expect(S.t(AppLanguage.bodo, 'home'), isNot('home'));
    });

    test('no translation key falls back to a raw key name', () {
      const keys = [
        'app_tagline',
        'welcome_title',
        'get_started',
        'choose_language',
        'continue_label',
        'login_title',
        'phone_number',
        'send_code',
        'otp_title',
        'verify',
        'choose_role',
        'role_hint',
        'choose_specialisation',
        'specialisation_hint',
        'your_name',
        'district',
        'create_account',
        'home',
        'market',
        'jobs',
        'payments',
        'profile',
        'property',
        'rides',
        'rentals',
        'fleet',
        'approvals',
        'cleared',
        'pending',
        'logout',
      ];
      for (final lang in AppLanguage.values) {
        for (final key in keys) {
          final value = S.t(lang, key);
          expect(value, isNotEmpty, reason: '${lang.code}/$key');
          expect(value, isNot(key), reason: 'missing ${lang.code}/$key');
        }
      }
    });
  });

  group('Daily learning tasks', () {
    test(
      'targets match the spec: 15 min video, 3 maths rounds, 10 questions',
      () {
        expect(DailyTaskType.video.target, 15);
        expect(DailyTaskType.games.target, 3);
        expect(DailyTaskType.quiz.target, 10);
      },
    );

    test('every task type has a label, subtitle, unit and icon', () {
      for (final type in DailyTaskType.values) {
        expect(type.label, isNotEmpty, reason: type.name);
        expect(type.subtitle, isNotEmpty, reason: type.name);
        expect(type.unitLabel, isNotEmpty, reason: type.name);
        expect(type.points, greaterThan(0), reason: type.name);
      }
    });

    test('the daily quiz really holds ten questions', () {
      expect(LearningContent.dailyQuiz.length, DailyTaskType.quiz.target);
    });

    test('every quiz question has a reachable, in-range answer', () {
      for (final q in LearningContent.dailyQuiz) {
        expect(q.question, isNotEmpty);
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(
          q.correctIndex,
          lessThan(q.options.length),
          reason: 'out-of-range answer for "${q.question}"',
        );
        expect(
          q.options.toSet().length,
          q.options.length,
          reason: 'duplicate options for "${q.question}"',
        );
      }
    });

    test('shuffling moves the answer without corrupting it', () {
      // Regression guard: every question is *authored* with the answer at
      // index 0, so an unshuffled quiz can be aced by tapping A ten times.
      // shuffled() must relocate the answer while keeping correctIndex
      // pointing at the same option text.
      final rng = Random(20250811);
      var moved = 0;
      for (final q in LearningContent.dailyQuiz) {
        final answer = q.options[q.correctIndex];
        for (var attempt = 0; attempt < 8; attempt++) {
          final s = q.shuffled(rng);
          expect(s.question, q.question);
          expect(
            s.options.toSet(),
            q.options.toSet(),
            reason: 'shuffle dropped or invented an option',
          );
          expect(s.options.length, q.options.length);
          expect(
            s.options[s.correctIndex],
            answer,
            reason: 'shuffle broke the answer mapping',
          );
          if (s.correctIndex != 0) moved++;
        }
      }
      // Across 80 shuffles the answer must land off slot A most of the time.
      expect(
        moved,
        greaterThan(40),
        reason: 'answers are not actually being redistributed',
      );
    });

    test('a shuffled quiz cannot be aced by always picking option A', () {
      final rng = Random(7);
      final quiz = [for (final q in LearningContent.dailyQuiz) q.shuffled(rng)];
      final alwaysA = quiz.where((q) => q.correctIndex == 0).length;
      expect(
        alwaysA,
        lessThan(quiz.length),
        reason: 'tapping A every time still scores full marks',
      );
    });

    test('the video lesson is exactly the advertised fifteen minutes', () {
      expect(LearningContent.todaysVideo.minutes, DailyTaskType.video.target);
    });

    test('the games hub has enough content for a full round', () {
      expect(LearningContent.mathRounds, isNotEmpty);
      expect(
        LearningContent.termPairs.length,
        greaterThanOrEqualTo(DailyTaskType.games.target),
      );
      for (final round in LearningContent.mathRounds) {
        expect(
          round.options,
          contains(round.answer),
          reason: 'unanswerable round: ${round.prompt}',
        );
      }
    });
  });

  group('Daily progress arithmetic', () {
    DailyProgress progress({int video = 0, int games = 0, int quiz = 0}) =>
        DailyProgress(
          userId: 'u',
          dayKey: '2025-01-01',
          videoMinutes: video,
          gamesPlayed: games,
          quizAnswered: quiz,
        );

    test('a task completes only on reaching its target', () {
      expect(progress(video: 14).isComplete(DailyTaskType.video), isFalse);
      expect(progress(video: 15).isComplete(DailyTaskType.video), isTrue);
      // Overshooting still counts as complete, never as an error.
      expect(progress(video: 40).isComplete(DailyTaskType.video), isTrue);
      expect(progress(games: 2).isComplete(DailyTaskType.games), isFalse);
      expect(progress(games: 3).isComplete(DailyTaskType.games), isTrue);
      expect(progress(quiz: 9).isComplete(DailyTaskType.quiz), isFalse);
      expect(progress(quiz: 10).isComplete(DailyTaskType.quiz), isTrue);
    });

    test('allComplete requires all three, not just any one', () {
      expect(progress(video: 15, games: 3, quiz: 10).allComplete, isTrue);
      expect(progress(video: 15, games: 3, quiz: 9).allComplete, isFalse);
      expect(progress().allComplete, isFalse);
    });

    test('overall fraction is clamped, so overshooting cannot exceed 100%', () {
      expect(progress().overallFraction, 0.0);
      expect(progress(video: 15, games: 3, quiz: 10).overallFraction, 1.0);
      // 99 minutes of video is still only one task done.
      expect(progress(video: 99).overallFraction, closeTo(1 / 3, 0.0001));
    });

    test('completedCount counts finished tasks only', () {
      expect(progress(video: 15, games: 1).completedCount, 1);
      expect(progress(video: 15, games: 3).completedCount, 2);
      expect(progress(video: 15, games: 3, quiz: 10).completedCount, 3);
    });

    test('day keys are zero-padded and sort chronologically as strings', () {
      final jan = DailyProgress.dayKeyOf(DateTime(2025, 1, 9));
      final oct = DailyProgress.dayKeyOf(DateTime(2025, 10, 11));
      expect(jan, '2025-01-09');
      expect(oct, '2025-10-11');
      expect(jan.compareTo(oct), lessThan(0));
    });

    test('storage keys are unique per user and per day', () {
      final a = DailyProgress.keyFor('u_1', DateTime(2025, 3, 4));
      final b = DailyProgress.keyFor('u_2', DateTime(2025, 3, 4));
      final c = DailyProgress.keyFor('u_1', DateTime(2025, 3, 5));
      expect({a, b, c}.length, 3);
      expect(a, 'u_1_2025-03-04');
    });
  });

  group('User categories', () {
    test('only students are asked for academic details', () {
      expect(UserCategory.student.needsAcademicProfile, isTrue);
      expect(UserCategory.jobSeeker.needsAcademicProfile, isFalse);
    });

    test('every category is presentable in the UI', () {
      for (final c in UserCategory.values) {
        expect(c.label, isNotEmpty, reason: c.name);
        expect(c.subtitle, isNotEmpty, reason: c.name);
        expect(c.description, isNotEmpty, reason: c.name);
      }
    });

    test('ids round-trip and unknown ids fall back to null', () {
      for (final c in UserCategory.values) {
        expect(UserCategoryX.tryFromId(c.id), c);
      }
      expect(UserCategoryX.tryFromId('teacher'), isNull);
      expect(UserCategoryX.tryFromId(null), isNull);
    });
  });

  group('Two separate apps', () {
    AppUser userWith(UserCategory? category, UserRole role) => AppUser(
      id: 'u_test',
      phone: '+919000000000',
      countryCode: '+91',
      name: 'Test Person',
      role: role,
      district: 'Mandya',
      category: category,
      createdAt: DateTime(2024, 1, 1),
    );

    // A source-level guard, because the bug it catches is a wiring mistake no
    // unit test on AppTrack can see: a screen that pushes `AppShell()` itself
    // sends every user to the green marketplace, so a returning student
    // silently reopens the agri market. This was a real defect in
    // otp_screen.dart. Routing must always go through TrackRouter, which means
    // TrackRouter stays the only file allowed to name AppShell.
    test('TrackRouter is the only route into the marketplace shell', () {
      final offenders = <String>[];
      for (final entry in Directory('lib').listSync(recursive: true)) {
        if (entry is! File || !entry.path.endsWith('.dart')) continue;
        if (entry.path.endsWith('ui/shell/app_shell.dart')) continue;
        if (entry.path.endsWith('ui/shell/track_router.dart')) continue;
        if (entry.readAsStringSync().contains('AppShell(')) {
          offenders.add(entry.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'These files construct AppShell directly and would bypass the '
            'student/job-seeker split. Navigate to TrackRouter instead: '
            '$offenders',
      );
    });

    // The completion green (0xFF2E7D32) was byte-identical to
    // AgriPalette.primaryLight, so tick badges and progress bars in the shared
    // learning screens rendered agri brand green inside the blue student app.
    test('completion chrome never shows agri green in the education app', () {
      const agri = AgriPalette();
      const edu = EduPalette();
      expect(edu.success, isNot(agri.success));
      // Specifically, the edu "done" colour must not be any agri brand colour.
      expect(
        [agri.primary, agri.primaryLight, agri.primaryDark],
        isNot(contains(edu.success)),
        reason: 'edu success colour is reusing an agri brand green',
      );
      // And applyPalette must actually move it, or the leak returns at runtime.
      AppColors.applyPalette(edu);
      expect(AppColors.success, edu.success);
      AppColors.applyPalette(agri);
      expect(AppColors.success, agri.success);
    });

    test('category alone decides which app opens', () {
      expect(
        AppTrack.of(userWith(UserCategory.student, UserRole.student)),
        AppTrack.education,
      );
      expect(
        AppTrack.of(userWith(UserCategory.jobSeeker, UserRole.laborer)),
        AppTrack.marketplace,
      );
      // A user who never picked a category (e.g. seeded marketplace accounts)
      // must land in the marketplace app, not a half-configured edu app.
      expect(
        AppTrack.of(userWith(null, UserRole.landowner)),
        AppTrack.marketplace,
      );
    });

    test('the two tracks use visibly different brand colours', () {
      // The user asked for green for job seekers and blue for students; if
      // these ever collide the tracks stop being distinguishable at a glance.
      expect(
        AppTrack.education.palette.primary,
        isNot(AppTrack.marketplace.palette.primary),
      );
      expect(const EduPalette().primary, const Color(0xFF12468F));
      expect(const AgriPalette().primary, const Color(0xFF1B5E20));
    });

    test('applyPalette re-points the brand colours and is reversible', () {
      AppColors.applyPalette(const EduPalette());
      expect(AppColors.primary, const EduPalette().primary);
      expect(AppColors.background, const EduPalette().background);

      AppColors.applyPalette(const AgriPalette());
      expect(AppColors.primary, const AgriPalette().primary);
      expect(AppColors.background, const AgriPalette().background);
    });

    test('education content shares no material with the marketplace', () {
      // The whole point of the split: a student must never see crop, mandi,
      // commission or labour material.
      final eduQuiz = TaskContentPack.education.quiz
          .map((q) => q.question)
          .toList();
      final marketQuiz = TaskContentPack.marketplace.quiz
          .map((q) => q.question)
          .toList();
      for (final q in eduQuiz) {
        expect(marketQuiz, isNot(contains(q)));
      }
      expect(
        TaskContentPack.education.video.id,
        isNot(TaskContentPack.marketplace.video.id),
      );
      // Money formatting is a marketplace-only concern.
      expect(TaskContentPack.education.mathAnswersAreMoney, isFalse);
      expect(TaskContentPack.marketplace.mathAnswersAreMoney, isTrue);
    });

    test('education content carries no marketplace vocabulary', () {
      const banned = [
        'crop',
        'mandi',
        'commission',
        'harvest',
        'quintal',
        'fertiliser',
        'soil',
        'labour',
        'labourer',
        'export',
        'broker',
        'tractor',
      ];
      final pack = TaskContentPack.education;
      final corpus = [
        // The seeded history title is included because the content pack alone
        // was clean while the student Progress tab still showed "Watched: Soil
        // Health & Crop Rotation Basics" — the agri lesson was hardcoded in the
        // seeder, so scanning only the pack missed a visible leak.
        'Watched: ${EduContent.todaysVideo.title}',
        EduContent.todaysVideo.presenter,
        pack.video.title,
        pack.video.summary,
        pack.mathTitle,
        pack.mathSubtitle,
        pack.quizSubject,
        for (final q in pack.quiz) ...[q.question, ...q.options],
        for (final r in pack.mathRounds) r.prompt,
      ].join(' ').toLowerCase();

      for (final word in banned) {
        expect(
          RegExp(r'\b' + word + r'\b').hasMatch(corpus),
          isFalse,
          reason: 'education content must not mention "$word"',
        );
      }
    });

    test('every education game round is playable', () {
      final pack = TaskContentPack.education;
      expect(pack.quiz.length, 10);

      for (final r in pack.mathRounds) {
        expect(
          r.options,
          contains(r.answer),
          reason: 'unanswerable round: ${r.prompt}',
        );
        expect(
          r.options.toSet().length,
          r.options.length,
          reason: 'duplicate options: ${r.prompt}',
        );
      }
    });

    test('switching account type can clear a marketplace specialisation', () {
      // copyWith's `??` pattern cannot express "set back to null", which the
      // switch to the student track needs.
      final buyer = userWith(
        UserCategory.jobSeeker,
        UserRole.buyer,
      ).copyWith(subtype: RoleSubtype.retailMarketBuyer);
      expect(buyer.subtype, isNotNull);

      final student = buyer.copyWith(
        role: UserRole.student,
        category: UserCategory.student,
        clearSubtype: true,
      );
      expect(student.subtype, isNull);
      expect(student.isStudent, isTrue);
      expect(Rbac.of(student.role), isEmpty);
    });
  });

  group('Gazetteer', () {
    test('every district and city resolves to coordinates', () {
      // The gazetteer is the only source of selectable place names, so an
      // entry that cannot be looked up would be offered in a dropdown and
      // then refuse to open a map.
      for (final state in Gazetteer.states) {
        expect(
          Gazetteer.lookup(state.name),
          isNotNull,
          reason: 'state ${state.name} does not resolve',
        );
        for (final district in state.districts) {
          expect(
            Gazetteer.lookup(district.name),
            isNotNull,
            reason: 'district ${district.name} does not resolve',
          );
          for (final city in district.cities) {
            expect(
              Gazetteer.lookup(city.name),
              isNotNull,
              reason: 'city ${city.name} in ${district.name} does not resolve',
            );
          }
        }
      }
    });

    test('every Indian place sits inside India\'s bounding box', () {
      // Catches transposed or mistyped coordinates, which would otherwise
      // silently drop a pin in the sea and look plausible in code review.
      for (final state in Gazetteer.states) {
        final places = <Place>[
          state.place,
          for (final d in state.districts) ...[d.place, ...d.cities],
        ];
        for (final p in places) {
          expect(
            p.lat,
            inInclusiveRange(6.0, 37.5),
            reason: '${p.name} latitude ${p.lat} is outside India',
          );
          expect(
            p.lng,
            inInclusiveRange(68.0, 97.5),
            reason: '${p.name} longitude ${p.lng} is outside India',
          );
        }
      }
    });

    test('district names are unique, so a dropdown choice is unambiguous', () {
      // India really does have four district names used by two states each
      // (Aurangabad, Balrampur, Bilaspur, Raigarh). They are stored with the
      // state in brackets so no two entries collide — without that, one would
      // shadow the other in the name index and a Bilaspur user could be
      // pinned in the wrong state, ~1,500km away.
      final seen = <String>{};
      for (final state in Gazetteer.states) {
        for (final d in state.districts) {
          expect(
            seen.add(d.name.toLowerCase()),
            isTrue,
            reason: 'district ${d.name} is listed twice',
          );
        }
      }
    });

    test('a district name shared by two states is disambiguated', () {
      // Guards the mechanism above rather than the specific data: any name
      // occurring in more than one state must carry its state, and each
      // qualified entry must resolve to its own coordinates.
      final byBareName = <String, List<Place>>{};
      for (final state in Gazetteer.states) {
        for (final d in state.districts) {
          final bracket = d.name.indexOf(' (');
          final bare = bracket > 0 ? d.name.substring(0, bracket) : d.name;
          byBareName.putIfAbsent(bare.toLowerCase(), () => []).add(d.place);
        }
      }
      final shared = byBareName.entries.where((e) => e.value.length > 1);
      expect(
        shared,
        isNotEmpty,
        reason: 'India has duplicate district names; expected some qualified',
      );
      for (final entry in shared) {
        for (final place in entry.value) {
          expect(
            place.name,
            contains(' ('),
            reason: '${place.name} is ambiguous but not qualified by state',
          );
          expect(Gazetteer.lookup(place.name), isNotNull);
        }
        // The two same-named districts must be genuinely different places.
        final first = entry.value.first;
        final second = entry.value[1];
        expect(
          first.lat == second.lat && first.lng == second.lng,
          isFalse,
          reason: '${entry.key} duplicates share coordinates',
        );
      }
    });

    test('superseded spellings still resolve, ambiguous ones do not', () {
      // Accounts and seed rows written before a rename must keep their pin.
      expect(Gazetteer.lookup('Mysore')!.name, 'Mysuru');
      expect(Gazetteer.lookup('Gulbarga')!.name, 'Kalaburagi');
      expect(Gazetteer.lookup('Allahabad')!.name, 'Prayagraj');
      // "Bijapur" is Karnataka's former name for Vijayapura but also a
      // current, different district in Chhattisgarh. Aliasing it would move
      // a real Chhattisgarh user 900km, so the current place must win.
      final bijapur = Gazetteer.lookup('Bijapur');
      expect(bijapur, isNotNull);
      expect(Gazetteer.stateOfDistrict('Bijapur'), 'Chhattisgarh');
    });

    test('every state offers a full set of districts, not a token few', () {
      // The reason this matters: an earlier hand-written gazetteer gave most
      // states two or three districts, so a real user from Salem or Nashik
      // could not finish signing up. A closed dropdown is only acceptable
      // when the list actually contains the user.
      expect(Gazetteer.states.length, greaterThanOrEqualTo(36));
      var total = 0;
      for (final state in Gazetteer.states) {
        final districts = Gazetteer.districtsIn(state.name);
        total += districts.length;
        // Every district must offer at least one city, or the third dropdown
        // would sit permanently empty and read as a broken form.
        for (final d in districts) {
          expect(
            Gazetteer.citiesIn(state.name, d),
            isNotEmpty,
            reason: '$d in ${state.name} has no selectable city',
          );
        }
      }
      expect(total, greaterThanOrEqualTo(700));
      // Spot-check towns that the old Karnataka-only gazetteer would have
      // rejected outright.
      for (final place in const [
        'Salem',
        'Nashik',
        'Ludhiana',
        'Guwahati',
        'Kanpur',
        'Bhopal',
        'Cuttack',
        'Kozhikode',
      ]) {
        expect(
          Gazetteer.isKnown(place),
          isTrue,
          reason: '$place is not selectable',
        );
      }
    });

    test('the cascade only offers children of the chosen parent', () {
      // The guarantee behind "no invalid names": a district can never be
      // paired with a state it does not belong to.
      for (final state in Gazetteer.states) {
        final districts = Gazetteer.districtsIn(state.name);
        expect(districts, isNotEmpty, reason: '${state.name} has no districts');
        for (final d in districts) {
          expect(Gazetteer.stateOfDistrict(d), state.name);
        }
      }
      expect(Gazetteer.districtsIn('Karnataka'), contains('Mandya'));
      expect(Gazetteer.districtsIn('Kerala'), isNot(contains('Mandya')));
      expect(Gazetteer.citiesIn('Karnataka', 'Mandya'), contains('Maddur'));
      // Nothing is offered until the level above has been chosen.
      expect(Gazetteer.districtsIn(null), isEmpty);
      expect(Gazetteer.citiesIn('Karnataka', null), isEmpty);
    });

    test('a more specific place wins over a same-named parent', () {
      // "Mysuru" is both a district and its principal city. The city is the
      // more useful pin, so it must be the one lookup returns.
      final mysuru = Gazetteer.lookup('Mysuru');
      final cityEntry = Gazetteer.karnataka.districts
          .firstWhere((d) => d.name == 'Mysuru')
          .cities
          .firstWhere((c) => c.name == 'Mysuru');
      expect(mysuru!.lat, cityEntry.lat);
      expect(mysuru.lng, cityEntry.lng);
    });

    test('lookup is tolerant of stored spellings but not of nonsense', () {
      expect(Gazetteer.lookup('  mandya  ')!.name, 'Mandya');
      expect(Gazetteer.lookup('MANDYA')!.name, 'Mandya');
      // Composite values like "Maddur, Mandya" appear in older records.
      expect(Gazetteer.lookup('Maddur, Mandya')!.name, 'Maddur');
      // Unknown names must stay null so callers render plain text rather
      // than pinning the wrong place.
      expect(Gazetteer.lookup('Mandia'), isNull);
      expect(Gazetteer.lookup('Atlantis'), isNull);
      expect(Gazetteer.lookup(''), isNull);
      expect(Gazetteer.lookup(null), isNull);
      expect(Gazetteer.isKnown('Bengaluru'), isTrue);
      expect(Gazetteer.isKnown('Nowhereville'), isFalse);
    });

    test('search ranks prefix matches first and never invents names', () {
      final hits = Gazetteer.search('mand', limit: 30);
      expect(hits, isNotEmpty);
      // Every suggestion must be a name the gazetteer can pin, otherwise the
      // field would propose a place and then fail to map it.
      for (final hit in hits) {
        expect(Gazetteer.lookup(hit), isNotNull);
      }
      expect(hits, contains('Mandya'));
      // Prefix matches must all precede substring matches. Asserted as an
      // ordering property rather than a fixed first element: now that the
      // gazetteer covers all of India, "Mandapeta" is an equally valid
      // prefix hit, and pinning the test to one town would only record
      // which state happened to sort first.
      final lastPrefix = hits.lastIndexWhere(
        (h) => h.toLowerCase().startsWith('mand'),
      );
      final firstNonPrefix = hits.indexWhere(
        (h) => !h.toLowerCase().startsWith('mand'),
      );
      if (firstNonPrefix != -1) {
        expect(firstNonPrefix, greaterThan(lastPrefix));
      }
      expect(Gazetteer.search(''), isEmpty);
      expect(Gazetteer.search('zzzzz'), isEmpty);
      expect(Gazetteer.search('a', limit: 3).length, lessThanOrEqualTo(3));
    });

    test('every seeded district is a real gazetteer district', () {
      // Seed data must not introduce a place the dropdowns cannot produce,
      // or demo accounts would hold names a real signup could never create.
      for (final district in const [
        'Mandya',
        'Mysuru',
        'Hassan',
        'Bengaluru Rural',
        'Tumakuru',
        'Belagavi',
        'Ballari',
      ]) {
        expect(
          Gazetteer.stateOfDistrict(district),
          isNotNull,
          reason: '$district is used in seed data but is not a district',
        );
      }
    });

    test('exporter and investor countries all resolve', () {
      expect(Gazetteer.countryNames, contains('India'));
      expect(Gazetteer.countryNames.first, 'India');
      for (final name in Gazetteer.countryNames) {
        expect(Gazetteer.lookup(name), isNotNull, reason: '$name is unmapped');
      }
    });
  });

  group('Location input is constrained', () {
    test('signup collects location only through the gazetteer pickers', () {
      // The "no invalid names" guarantee is structural: if a TextFormField
      // for district or city reappeared in signup, free text would flow
      // straight back into the records the map depends on.
      final source = File(
        'lib/ui/auth/role_selection_screen.dart',
      ).readAsStringSync();
      expect(source, contains('LocationPicker('));
      expect(source, contains('CountryPicker('));
      for (final banned in const [
        '_district = TextEditingController',
        '_country = TextEditingController',
        '_city = TextEditingController',
      ]) {
        expect(
          source,
          isNot(contains(banned)),
          reason: 'signup reintroduced a free-text location field: $banned',
        );
      }
    });

    test('student goals are optional', () {
      // A student who has not decided what to become must still be able to
      // finish signing up.
      final source = File(
        'lib/ui/auth/student_details_screen.dart',
      ).readAsStringSync();
      expect(source, isNot(contains("_required(v, 'Goals')")));
      expect(source, isNot(contains('at least 15 characters')));
      expect(source, contains("_FieldLabel('Your goals & aspirations'"));

      // An empty goal must survive the round-trip into a profile.
      const details = PendingStudentDetails(
        tenthMarksCardNumber: 'KSEEB2021123456',
        currentClass: 'Class 10',
        collegeName: 'Government PU College',
        goals: '',
      );
      final profile = details.toProfile('u_1');
      expect(profile.goals, isEmpty);
      expect(StudentProfile.fromMap(profile.toMap()).goals, isEmpty);
    });
  });

  group('Peer-to-peer vehicle rental', () {
    test('anyone on the marketplace can list a vehicle and rent one', () {
      // The requirement is "anyone can list the vehicle for renting and
      // anyone can get that vehicle for rent". Asserted across every role
      // rather than a sample, because a single role missing either half is
      // exactly the failure this feature must not have, and it would be
      // invisible until a user of that role went looking.
      for (final role in UserRole.values) {
        if (role == UserRole.student) continue;
        expect(
          Rbac.can(role, Permission.listVehicleForRent),
          isTrue,
          reason: '${role.name} cannot list a vehicle for rent',
        );
        expect(
          Rbac.can(role, Permission.rentVehicle),
          isTrue,
          reason: '${role.name} cannot rent a vehicle',
        );
      }
    });

    test('students are still excluded from renting', () {
      // "Anyone" means anyone on the marketplace. Students hold no
      // marketplace capability by design, and renting a vehicle is squarely
      // a marketplace act, so the education app must not gain a rental
      // surface through this feature.
      expect(
        Rbac.can(UserRole.student, Permission.listVehicleForRent),
        isFalse,
      );
      expect(Rbac.can(UserRole.student, Permission.rentVehicle), isFalse);
      expect(Rbac.of(UserRole.student), isEmpty);
      expect(Rbac.peerRentalRoles, isNot(contains(UserRole.student)));
    });

    test('peer rental is granted centrally, not role by role', () {
      // Guards against the grant being copied back into individual roles
      // later, which is how one role ends up quietly missing it.
      final source = File('lib/core/rbac/permissions.dart').readAsStringSync();
      final matrix = source.substring(
        source.indexOf('_matrix = {'),
        source.indexOf('_peerRental'),
      );
      expect(matrix, isNot(contains('Permission.rentVehicle')));
      expect(matrix, isNot(contains('Permission.listVehicleForRent')));
    });

    test('lending a vehicle stays separate from running a fleet', () {
      // A member lending an idle tractor must not be handed the commercial
      // rental workspace, and a licensed operator must keep it. Collapsing
      // the two would either burden members with fleet management or hand
      // permit-bearing surfaces to people who never applied for them.
      expect(Rbac.can(UserRole.landowner, Permission.manageRentals), isFalse);
      expect(Rbac.can(UserRole.laborer, Permission.manageFleet), isFalse);
      expect(
        Rbac.can(UserRole.vehicleRental, Permission.manageRentals),
        isTrue,
      );
    });

    test('a peer listing is billed by the day and discloses its owner', () {
      const peer = Vehicle(
        id: 'v_test',
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
        notes: 'Renter fills diesel.',
      );

      expect(peer.rateUnit, 'day');
      expect(peer.ratePaise, 160000);
      expect(peer.category.isDailyRate, isTrue);
      expect(peer.peerListed, isTrue);

      // Must survive storage, since the badge a renter relies on to tell a
      // member from a business is read back out of the record.
      final restored = Vehicle.fromMap(peer.toMap());
      expect(restored.peerListed, isTrue);
      expect(restored.notes, 'Renter fills diesel.');
      expect(restored.subtype, RoleSubtype.tractorImplementRental);
      expect(restored.ratePerDayPaise, 160000);
    });

    test('records written before peer rental read as business listings', () {
      // Older stored vehicles have no peer_listed key. Defaulting to true
      // would relabel every commercial fleet vehicle as a member listing.
      final legacy = Vehicle.fromMap({
        'id': 'v_old',
        'owner_id': 'u_rental_1',
        'owner_name': 'Hassan Wheels Rentals',
        'category': 'rental',
        'vehicle_type': 'Maruti Swift Dzire',
        'registration_number': 'KA 13 R 3390',
        'capacity_value': 5,
        'rate_per_day_paise': 180000,
        'district': 'Hassan',
      });
      expect(legacy.peerListed, isFalse);
      expect(legacy.notes, isEmpty);
    });

    test('an owner can fix a wrong rate without losing the listing', () {
      // A first-time lister routinely misprices. Without an edit path they
      // would have to delete and re-list, discarding the record that any
      // booking already points at.
      const listed = Vehicle(
        id: 'v_test',
        ownerId: 'u_landowner_1',
        ownerName: 'Ramesh Gowda',
        category: VehicleCategory.rental,
        subtype: RoleSubtype.bikeScooterRental,
        vehicleType: 'Bajaj Platina',
        registrationNumber: 'KA 13 W 7781',
        capacityValue: 2,
        ratePerDayPaise: 35000,
        district: 'Hassan',
        peerListed: true,
      );

      final revised = listed.copyWith(
        ratePerDayPaise: 45000,
        notes: 'Helmet provided.',
      );
      expect(revised.ratePerDayPaise, 45000);
      expect(revised.notes, 'Helmet provided.');

      // Identity and derived location must not move: bookings reference the
      // vehicle, and the district comes from the owner's account.
      expect(revised.id, listed.id);
      expect(revised.registrationNumber, listed.registrationNumber);
      expect(revised.district, listed.district);
      expect(revised.ownerId, listed.ownerId);
      expect(revised.peerListed, isTrue);
    });

    test('the rental kind list covers farm equipment', () {
      // Lending a tractor is the most valuable peer rental in Indian
      // agriculture and fits none of the car/jeep/bike kinds.
      final kinds = RoleSubtypeX.rentalKinds;
      expect(kinds, contains(RoleSubtype.tractorImplementRental));
      // Derived from the rental role rather than written out twice, so the
      // lister's form and the provider's fleet can never disagree.
      expect(kinds, RoleSubtypeX.forRole(UserRole.vehicleRental));
      for (final kind in kinds) {
        expect(kind.vehicleCategory, VehicleCategory.rental);
        expect(kind.label, isNotEmpty);
      }
    });

    test('both directions of rental are reachable from one screen', () {
      // The same person rents in one season and lends in another, so lending
      // must not be buried behind a separate, more official-looking route.
      final hub = File(
        'lib/ui/transport/rental_hub_screen.dart',
      ).readAsStringSync();
      expect(hub, contains("text: 'Rent'"));
      expect(hub, contains("text: 'Lend'"));
      expect(hub, contains('listVehicleForRent'));

      // Offered to every permitted role from the shell, and appended to every
      // dashboard from one place rather than per role.
      final shell = File('lib/ui/shell/app_shell.dart').readAsStringSync();
      expect(shell, contains('Permission.listVehicleForRent'));
      expect(shell, contains('RentalHubScreen()'));

      final home = File('lib/ui/dashboards/role_home.dart').readAsStringSync();
      expect(home, contains('Permission.listVehicleForRent'));
    });

    test('rental listings derive their district, never ask for it', () {
      // Every mappable place in BLOB comes from the owner's account. A rate
      // field is safe to type; a place name is not.
      final controller = File(
        'lib/state/marketplace_controller.dart',
      ).readAsStringSync();
      final method = controller.substring(
        controller.indexOf('Future<Vehicle> listVehicleForRent('),
        controller.indexOf('List<Vehicle> rentableVehicles('),
      );
      expect(method, contains('district: owner.district'));
      expect(method, contains('peerListed: true'));
      expect(method, contains('VehicleCategory.rental'));

      final hub = File(
        'lib/ui/transport/rental_hub_screen.dart',
      ).readAsStringSync();
      expect(hub, isNot(contains('_district')));
    });
  });

  group('Nothing demo-only ships in a release build', () {
    test('the lesson skip button is compiled out of release builds', () {
      // It awards a full lesson's points without the lesson, so shipping it
      // would make every points total and leaderboard position meaningless.
      final source = File(
        'lib/ui/learning/video_task_screen.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('demo only')));
      expect(source, contains('kDebugMode && !_isComplete'));
    });

    test('account switching is compiled out of release builds', () {
      // The sheet signs into ANY account on the device, administrators
      // included, with no password or OTP. In a release build that is a
      // complete authentication bypass.
      final source = File(
        'lib/ui/profile/profile_screen.dart',
      ).readAsStringSync();
      expect(source, isNot(contains("title: 'Switch demo account'")));
      expect(source, contains('if (kDebugMode)'));

      // The guard has to sit on the entry point, not just the sheet, or the
      // row still renders and only fails when tapped.
      final tileAt = source.indexOf('Switch account (debug build)');
      final guardAt = source.lastIndexOf('if (kDebugMode)', tileAt);
      expect(guardAt, greaterThan(-1));
      expect(tileAt - guardAt, lessThan(400));
    });

    test('the OTP code banner disappears with a real SMS provider', () {
      // Unlike the two above, this one cannot simply be deleted: the dev
      // provider is currently the only way to receive a code, so hiding it
      // would lock everyone out. It is safe because the banner is bound to
      // devCode, which only DevOtpProvider populates — swapping in Firebase
      // Phone Auth removes the banner with no UI change.
      final screen = File('lib/ui/auth/otp_screen.dart').readAsStringSync();
      expect(screen, contains('session.devCode != null'));

      final service = File('lib/services/otp_service.dart').readAsStringSync();
      expect(service, contains('class DevOtpProvider'));
      // Only the dev provider may ever hand back a code.
      final providers = RegExp(r'devCode: ').allMatches(service).length;
      expect(providers, 1);
    });
  });
}
