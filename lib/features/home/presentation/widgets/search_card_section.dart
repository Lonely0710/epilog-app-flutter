import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';

@Preview()
Widget previewSearchCardSection() => const SearchCardSection();

class SearchCardSection extends StatelessWidget {
  const SearchCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSearchButton(
              context,
              icon: Icons.tv,
              label: '搜索电影/电视剧',
              onTap: () {
                context.push('/search?type=movie');
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSearchButton(
              context,
              imagePath: 'assets/icons/ic_bilibili.png',
              label: '搜索动漫',
              onTap: () {
                context.push('/search?type=anime');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context,
      {IconData? icon,
      String? imagePath,
      required String label,
      VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.surface;
    final iconColor = isDark ? Colors.grey[400]! : AppTheme.textSecondary;
    final textColor = isDark ? Colors.grey[300]! : AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(imagePath, color: iconColor, width: 28, height: 28)
            else if (icon != null)
              Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
