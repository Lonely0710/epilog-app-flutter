import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class GridLayoutSwitcher extends StatelessWidget {
  final bool isCompactMode;
  final VoidCallback onToggle;

  const GridLayoutSwitcher({
    super.key,
    required this.isCompactMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48, // Fixed size to match JellyPageSwitcher
          height: 48,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariant.withValues(alpha: 0.9)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              isCompactMode
                  ? Icons.grid_view_rounded
                  : Icons.view_module_rounded,
              key: ValueKey(isCompactMode),
              color: isDark ? Colors.white : AppColors.textPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
