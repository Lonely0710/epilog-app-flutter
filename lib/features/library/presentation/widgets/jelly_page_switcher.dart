import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class JellyPageSwitcher extends StatelessWidget {
  final bool isAnimeWall;
  final VoidCallback onToggle;

  const JellyPageSwitcher({
    super.key,
    required this.isAnimeWall,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48, // Fixed size to match GridLayoutSwitcher
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: Tween<double>(begin: 0.75, end: 1.0).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Icon(
              isAnimeWall ? Icons.movie_filter_rounded : Icons.auto_awesome,
              key: ValueKey(isAnimeWall),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
