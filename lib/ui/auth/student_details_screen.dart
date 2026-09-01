import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../data/models/learning.dart';
import '../widgets/common.dart';
import 'role_selection_screen.dart';

/// Student details captured before the account exists. [StudentProfile] is
/// keyed by user id, which is only assigned at registration, so the form
/// result travels forward in this lightweight carrier.
class PendingStudentDetails {
  final String tenthMarksCardNumber;
  final String currentClass;
  final String collegeName;
  final String goals;

  const PendingStudentDetails({
    required this.tenthMarksCardNumber,
    required this.currentClass,
    required this.collegeName,
    required this.goals,
  });

  StudentProfile toProfile(String userId) => StudentProfile(
        userId: userId,
        tenthMarksCardNumber: tenthMarksCardNumber,
        currentClass: currentClass,
        collegeName: collegeName,
        goals: goals,
        updatedAt: DateTime.now(),
      );
}

/// Step 3 — academic background. Everything except the free-text goals is
/// required.
class StudentDetailsScreen extends StatefulWidget {
  /// When true the screen pops with the collected [PendingStudentDetails]
  /// instead of continuing into signup. Used when an existing account switches
  /// to the student track and only needs the academic details filled in.
  final bool returnDetails;

  const StudentDetailsScreen({super.key, this.returnDetails = false});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marksCard = TextEditingController();
  final _college = TextEditingController();
  final _goals = TextEditingController();
  String? _currentClass;

  /// Covers school through post-graduation so the form fits every student.
  static const _classOptions = <String>[
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11',
    'Class 12',
    'ITI / Diploma',
    'Undergraduate — 1st year',
    'Undergraduate — 2nd year',
    'Undergraduate — 3rd year',
    'Undergraduate — 4th year',
    'Postgraduate',
    'Other',
  ];

  /// Only students in Class 10 or above have a 10th marks card. Below that
  /// the field is not just optional — it is not shown at all.
  static const _marksCardClasses = <String>[
    'Class 10',
    'Class 11',
    'Class 12',
    'ITI / Diploma',
    'Undergraduate — 1st year',
    'Undergraduate — 2nd year',
    'Undergraduate — 3rd year',
    'Undergraduate — 4th year',
    'Postgraduate',
    'Other',
  ];

  bool get _needsMarksCard =>
      _currentClass != null && _marksCardClasses.contains(_currentClass);

  @override
  void dispose() {
    _marksCard.dispose();
    _college.dispose();
    _goals.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_currentClass == null) {
      showSnack(context, 'Please select your current class', error: true);
      return;
    }
    // Students below Class 10 have no 10th marks card yet, so nothing is
    // collected and nothing is stored.
    if (!_needsMarksCard && _marksCard.text.trim().isNotEmpty) {
      _marksCard.clear();
    }
    final details = PendingStudentDetails(
      tenthMarksCardNumber: _marksCard.text.trim(),
      currentClass: _currentClass!,
      collegeName: _college.text.trim(),
      goals: _goals.text.trim(),
    );
    if (widget.returnDetails) {
      Navigator.of(context).pop(details);
      return;
    }
    // Students skip marketplace role selection entirely: every role in that
    // list is an agri-market role, and a student holds no marketplace
    // capability. The role is fixed to UserRole.student here.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSetupScreen(
          role: UserRole.student,
          category: UserCategory.student,
          studentDetails: details,
        ),
      ),
    );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student details')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text(
                'Tell us about your studies',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'We use this to match your daily tasks and quizzes to your '
                'level. Your goals are optional — you can add them later.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Select the class first: the marks card only exists once the
              // student has reached Class 10, so the field below is hidden
              // entirely for Classes 5–9.
              const _FieldLabel('Current class / year'),
              DropdownButtonFormField<String>(
                initialValue: _currentClass,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined),
                  hintText: 'Select your class',
                ),
                items: [
                  for (final option in _classOptions)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: (v) => setState(() => _currentClass = v),
                validator: (v) =>
                    v == null ? 'Current class is required' : null,
              ),
              const SizedBox(height: 18),

              if (_needsMarksCard) ...[
                const _FieldLabel('10th marks card number'),
                TextFormField(
                  controller: _marksCard,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9/\-]')),
                    LengthLimitingTextInputFormatter(24),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'e.g. KSEEB2021123456',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    final base = _required(v, 'Marks card number');
                    if (base != null) return base;
                    if (v!.trim().length < 6) {
                      return 'Enter the full number from your marks card';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
              ],

              const _FieldLabel('School / college name'),
              TextFormField(
                controller: _college,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Government PU College, Mandya',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                validator: (v) => _required(v, 'School / college name'),
              ),
              const SizedBox(height: 18),

              const _FieldLabel('Your goals & aspirations', optional: true),
              // Deliberately unvalidated. A student who does not yet know what
              // they want to become should still be able to finish signing up,
              // so this field accepts anything, including nothing at all.
              TextFormField(
                controller: _goals,
                maxLines: 4,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. I want to become an agricultural officer and '
                      'help farmers in my district get better prices.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  /// Appends an "(optional)" hint so a blank field never looks like an
  /// oversight the form is about to complain about.
  final bool optional;
  const _FieldLabel(this.text, {this.optional = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          optional ? '$text (optional)' : text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      );
}
