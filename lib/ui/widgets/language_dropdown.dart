import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';

/// Language picker rendered as a dropdown field.
///
/// With 23 languages a plain [DropdownButton] menu becomes an unusable
/// scroll, so tapping opens a searchable bottom sheet instead. The trigger
/// still reads and behaves like a standard form dropdown.
class LanguageDropdown extends StatelessWidget {
  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;
  final String? label;

  const LanguageDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguageSheet(selected: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          button: true,
          label: 'Language, ${value.englishName}',
          child: InkWell(
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.language, size: 22, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.nativeName,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (value.englishName != value.nativeName)
                          Text(
                            value.englishName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageSheet extends StatefulWidget {
  final AppLanguage selected;
  const _LanguageSheet({required this.selected});

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  String _query = '';

  List<AppLanguage> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return AppLanguage.values;
    return AppLanguage.values
        .where(
          (l) =>
              l.englishName.toLowerCase().contains(q) ||
              l.nativeName.toLowerCase().contains(q) ||
              l.code.toLowerCase() == q,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select language',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${AppLanguage.values.length} available',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search language',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text(
                        'No language matches that search',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final lang = results[i];
                        final isSelected = lang == widget.selected;
                        return ListTile(
                          onTap: () => Navigator.of(context).pop(lang),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppColors.primarySoft,
                          title: Directionality(
                            textDirection: lang.isRtl
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: Text(
                              lang.nativeName,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            lang.isFullyTranslated
                                ? lang.englishName
                                : '${lang.englishName} · partial',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
