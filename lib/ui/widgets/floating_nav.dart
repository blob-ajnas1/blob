import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Presentation data only: destinations and permissions stay with each shell.
class FloatingNavItem {
  const FloatingNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// A compact floating bar that can render either a filled or underlined tab.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.underlined = false,
  });

  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool underlined;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(child: _item(items[index], index)),
          ],
        ),
      ),
    );
  }

  Widget _item(FloatingNavItem item, int index) {
    final selected = index == selectedIndex;
    final filled = selected && !underlined;
    final color = filled
        ? AppColors.textOnPrimary
        : selected
        ? AppColors.primary
        : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        key: ValueKey('floating-nav-${item.id}'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => onTap(index),
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (underlined) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 20,
                    height: 3,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
