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
      showSnack(
        context,
        context.read<SessionController>().t('category_choose_prompt'),
        error: true,
      );
      return;
    }
    if (category.needsAcademicProfile) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const StudentDetailsScreen()),
      );
    } else {
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
    final session = context.watch<SessionController>();
    const palette = AgriPalette();

    return Scaffold(
      backgroundColor: AppColors.agriCream,
      appBar: AppBar(
        backgroundColor: AppColors.agriCream,
        automaticallyImplyLeading: false,
        leadingWidth: 68,
        leading: Navigator.of(context).canPop()
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 16),
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: IconButton.styleFrom(
                    backgroundColor: palette.primarySoft,
                    foregroundColor: palette.primary,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
              )
            : null,
        title: Text(
          session.t('about_you'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.primaryDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 14),
              child: Container(
                width: 78,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    PositionedDirectional(
                      start: 4,
                      bottom: 1,
                      child: Icon(
                        Icons.landscape_rounded,
                        size: 36,
                        color: palette.primaryLight,
                      ),
                    ),
                    PositionedDirectional(
                      end: 5,
                      bottom: 6,
                      child: Icon(
                        Icons.cottage_rounded,
                        size: 25,
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 18),
                children: [
                  Text(
                    session.t('about_question'),
                    style: TextStyle(
                      fontSize: 23,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: palette.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.t('about_description'),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (final category in UserCategory.values) ...[
                    _CategoryCard(
                      category: category,
                      label: session.t(
                        category == UserCategory.student
                            ? 'category_student'
                            : 'category_job_seeker',
                      ),
                      subtitle: session.t(
                        category == UserCategory.student
                            ? 'category_student_subtitle'
                            : 'category_job_seeker_subtitle',
                      ),
                      description: session.t(
                        category == UserCategory.student
                            ? 'category_student_description'
                            : 'category_job_seeker_description',
                      ),
                      selected: _selected == category,
                      onTap: () => setState(() => _selected = category),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.agriCream, palette.primarySoft],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PositionedDirectional(
                    start: 4,
                    top: -18,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: Icon(
                          Icons.grass_rounded,
                          size: 26,
                          color: palette.primaryLight.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 4,
                    top: -18,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: Icon(
                          Icons.agriculture_outlined,
                          size: 26,
                          color: palette.primaryLight.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        minimumSize: const Size.fromHeight(54),
                        shape: const StadiumBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              session.t('continue_label'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.label,
    required this.subtitle,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final UserCategory category;
  final String label;
  final String subtitle;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const palette = AgriPalette();
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? palette.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? palette.primary : palette.border,
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.primaryDark.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: selected ? palette.primary : palette.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    category.icon,
                    size: 27,
                    color: selected ? AppColors.textOnPrimary : palette.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: palette.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Divider(height: 20, color: palette.border),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
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
                  color: selected ? palette.primary : palette.border,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
