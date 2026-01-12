import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

import '../widgets/settings_user_info.dart'; // Import for HighlighterPainter

class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogBg,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline_rounded,
                          color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'About  ',
                          style: TextStyle(
                            fontFamily: 'LibreBaskerville',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Stack(
                          children: [
                            Positioned(
                              bottom: 2,
                              left: 0,
                              right: 0,
                              height: 12,
                              child: CustomPaint(
                                painter: HighlighterPainter(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.3)),
                              ),
                            ),
                            Text(
                              'Epilog',
                              style: TextStyle(
                                fontFamily: 'LibreBaskerville',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Gradient Divider
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (isDark ? Colors.white : Colors.grey)
                            .withValues(alpha: 0.0),
                        (isDark ? Colors.white : Colors.grey)
                            .withValues(alpha: 0.2),
                        (isDark ? Colors.white : Colors.grey)
                            .withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '👋你好，我是这款应用的开发者。',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '在这里，我希望能为你提供一个纯粹的角落，整理光影记忆，珍藏感动瞬间。\n\n作为一名海报控和影迷，Epilog 的诞生源于对电影艺术的热爱。愿它能陪你记录每一段精彩的旅程。',
                  style: TextStyle(
                    fontSize: 15,
                    color: textSecondary,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
          // Close Icon
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close,
                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }
}
