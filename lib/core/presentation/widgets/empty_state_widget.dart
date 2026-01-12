import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

/// A reusable widget for displaying empty or error states.
/// Uses the app's theme colors for consistency.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.lottieAsset,
    this.svgAsset,
    this.actionLabel = '重试',
    this.onAction,
  });

  /// Main message to display (e.g., "暂无数据", "暂无相关影视推荐")
  final String message;

  /// Optional icon to display above the message
  final IconData? icon;

  /// Optional Lottie animation asset path (takes precedence over icon)
  final String? lottieAsset;

  /// Optional SVG asset path (takes precedence over icon, but after Lottie)
  final String? svgAsset;

  /// Label for the action button (default: "重试")
  final String actionLabel;

  /// Callback for the action button. If null, no button is shown.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Visual element (Lottie only)
            if (lottieAsset != null)
              Lottie.asset(
                lottieAsset!,
                width: 150,
                height: 150,
                repeat: true,
              )
            else if (svgAsset != null)
              SvgPicture.asset(
                svgAsset!,
                width: 150,
                height: 150,
              ),

            if (lottieAsset != null || svgAsset != null)
              const SizedBox(height: 24),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 100,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 4,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
