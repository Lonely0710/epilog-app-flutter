import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';

class CircularRating extends StatelessWidget {
  final double rating; // 0.0 to 10.0
  final double size;
  final double strokeWidth;

  final Color? color;
  final Color? trackColor;

  const CircularRating({
    super.key,
    required this.rating,
    this.size = 40,
    this.strokeWidth = 3,
    this.color,
    this.trackColor,
  });

  Color _getRatingColor(double percentage) {
    if (color != null) return color!;
    return AppColors.getRatingColor(percentage);
  }

  Color _getTrackColor(double percentage) {
    if (trackColor != null) return trackColor!;
    return AppColors.getRatingBgColor(percentage);
  }

  @override
  Widget build(BuildContext context) {
    final percentage = rating * 10;
    final color = _getRatingColor(percentage);
    final trackColor = _getTrackColor(percentage);

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.ratingCircleBg,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: trackColor,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: strokeWidth,
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${percentage.toInt()}',
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnDark,
                    fontFamily: AppTheme.primaryFont,
                  ),
                ),
                TextSpan(
                  text: '%',
                  style: TextStyle(
                    fontSize: size * 0.2,
                    color: AppColors.textOnDark.withValues(alpha: 0.7),
                    fontFamily: AppTheme.primaryFont,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
