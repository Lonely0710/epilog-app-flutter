import 'package:flutter/material.dart';
import 'package:lava_lamp_effect/lava_lamp_effect.dart';
import '../../../../app/theme/app_theme.dart';

class SettingsBackground extends StatelessWidget {
  final Widget child;

  const SettingsBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              LavaLampEffect(
                size: constraints.biggest,
                color: AppTheme.primary.withValues(alpha: 0.3), // Light Purple
                lavaCount: 3,
                speed: 1,
              ),
              LavaLampEffect(
                size: constraints.biggest,
                color: Colors.yellow.withValues(alpha: 0.5),
                lavaCount: 3,
                speed: 1,
              ),
              _KeyboardAwarePadding(child: child),
            ],
          );
        },
      ),
    );
  }
}

class _KeyboardAwarePadding extends StatelessWidget {
  final Widget child;

  const _KeyboardAwarePadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}
