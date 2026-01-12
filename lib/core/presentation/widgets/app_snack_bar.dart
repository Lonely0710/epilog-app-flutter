import 'package:flutter/material.dart';

class AppSnackBar {
  AppSnackBar._();

  // Timestamp of the last network error snackbar shown
  static DateTime? _lastNetworkErrorTime;

  // Minimum interval between network error snackbars (in seconds)
  static const int _debounceSeconds = 5;

  // Shows a network error snackbar with retry action.
  // Duration: 5 seconds
  // Debounce: Won't show again within 5 seconds of the last one
  static void showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
    String message = 'Network Error',
  }) {
    // Debounce: Skip if shown recently
    final now = DateTime.now();
    if (_lastNetworkErrorTime != null &&
        now.difference(_lastNetworkErrorTime!).inSeconds < _debounceSeconds) {
      return;
    }
    _lastNetworkErrorTime = now;

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323232),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Color.lerp(primaryColor, Colors.white, 0.3),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
              )
            : null,
      ),
    );
  }

  // Shows a generic error snackbar.
  static void showError(
    BuildContext context, {
    required String message,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323232),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onAction();
                },
              )
            : null,
      ),
    );
  }

  // Shows a success snackbar.
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF81C784), // Light Green
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323232),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
