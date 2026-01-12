import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// A standardized dialog button used across the app (Dialogs, Alerts).
///
/// [isPrimary] determines if it's a solid colored button (true) or an outlined/faded button (false).
/// [color] overrides the default primary color.
class SharedDialogButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPrimary;
  final IconData? icon;
  final Color? color;

  const SharedDialogButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isPrimary = true,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppTheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary ? themeColor : themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: isPrimary ? Colors.white : themeColor,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                    color: isPrimary ? Colors.white : themeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
