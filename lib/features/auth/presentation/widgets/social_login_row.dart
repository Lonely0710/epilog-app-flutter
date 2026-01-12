import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialLoginRow extends StatelessWidget {
  final VoidCallback? onGithubPressed;
  final VoidCallback? onGooglePressed;

  const SocialLoginRow({
    super.key,
    this.onGithubPressed,
    this.onGooglePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          assetName: 'assets/icons/ic_github.svg',
          onTap: onGithubPressed,
          isDark: isDark,
        ),
        const SizedBox(width: 20),
        _buildSocialButton(
          assetName: 'assets/icons/ic_google.svg',
          onTap: onGooglePressed,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String assetName,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200;
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 70,
        height: 60,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
          color: bgColor,
        ),
        child: SvgPicture.asset(
          assetName,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
