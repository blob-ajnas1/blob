import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/learning.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';
import 'role_selection_screen.dart';
import 'student_details_screen.dart';

/// Step 2 — choose Student or Job Seeker.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  UserCategory? _selected;

  void _continue() {
    final category = _selected;
    if (category == null) {
      showSnack(context, 'Please choose one option to continue', error: true);
      return;
    }
    if (category.needsAcademicProfile) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const StudentDetailsScreen()),
      );
    } else {
      // Job seekers skip the academic form and go straight to role setup.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const RoleSelectionScreen(category: UserCategory.jobSeeker),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(title: const Text('About you')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Which best describes you?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'This decides the daily tasks and opportunities you '
                      'see. You can change it later in your profile.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: UserCategory.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final category = UserCategory.values[i];
                  return _CategoryCard(
                    category: category,
                    selected: _selected == category,
                    onTap: () => setState(() => _selected = category),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final UserCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.icon,
                  size: 26,
                  color: selected ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.border,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
