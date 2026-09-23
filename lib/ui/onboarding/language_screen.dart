import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../state/session_controller.dart';
import '../auth/phone_login_screen.dart';
import '../widgets/brand.dart';
import '../widgets/language_dropdown.dart';

class LanguageScreen extends StatefulWidget {
  /// When true the screen is opened from Settings and pops on save.
  final bool fromSettings;
  const LanguageScreen({super.key, this.fromSettings = false});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late AppLanguage _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<SessionController>().language;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: widget.fromSettings
          ? AppBar(title: Text(session.t('choose_language')))
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.fromSettings) ...[
                const SizedBox(height: 12),
                const BlobMark(size: 56),
                const SizedBox(height: 20),
                Text(
                  session.t('choose_language'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                session.t('language_hint'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // The dropdown itself.
              LanguageDropdown(
                value: _selected,
                onChanged: (lang) => setState(() => _selected = lang),
              ),

              const SizedBox(height: 20),
              _PreviewCard(language: _selected),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await session.setLanguage(_selected);
                    if (!context.mounted) return;
                    if (widget.fromSettings) {
                      Navigator.of(context).pop();
                    } else {
                      await session.completeOnboarding();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const PhoneLoginScreen(),
                        ),
                      );
                    }
                  },
                  child: Text(S.t(_selected, 'continue_label')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the greeting in the chosen language so the user gets immediate,
/// legible confirmation before committing — important when the script is
/// unfamiliar.
class _PreviewCard extends StatelessWidget {
  final AppLanguage language;
  const _PreviewCard({required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Directionality(
        textDirection: language.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.t(language, 'greeting')} 👋',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              S.t(language, 'app_tagline'),
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (!language.isFullyTranslated) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Translation in progress — some screens will '
                      'show English.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
