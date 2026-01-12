import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class SettingsUserInfo extends StatelessWidget {
  final String displayName;
  final VoidCallback onEditName;

  const SettingsUserInfo({
    super.key,
    required this.displayName,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use yellow in dark mode for better visibility
    final highlightColor = isDark
        ? Colors.amber.withValues(alpha: 0.5)
        : Theme.of(context).primaryColor.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onEditName,
      child: Stack(
        children: [
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            height: 12,
            child: CustomPaint(
              painter: HighlighterPainter(color: highlightColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontFamily: 'LibreBaskerville',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit,
                    size: 16,
                    color: isDark
                        ? AppTheme.primary
                        : Theme.of(context).primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HighlighterPainter extends CustomPainter {
  final Color color;
  HighlighterPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // A slightly wavy horizontal line
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(
        size.width / 4, size.height / 2 - 2, size.width / 2, size.height / 2);
    path.quadraticBezierTo(
        size.width * 3 / 4, size.height / 2 + 2, size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
