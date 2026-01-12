import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

/// Duration for dialog/sheet animations
const Duration kDialogTransitionDuration = Duration(milliseconds: 250);

/// Shows a dialog with FadeScale animation
/// Use for all modal dialogs in the app
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return showModal<T>(
    context: context,
    configuration: FadeScaleTransitionConfiguration(
      transitionDuration: kDialogTransitionDuration,
      reverseTransitionDuration: kDialogTransitionDuration,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel ?? '',
    ),
    useRootNavigator: useRootNavigator,
    builder: builder,
  );
}

/// Shows a bottom sheet with slide+fade animation
/// Use for all bottom sheets in the app
Future<T?> showAnimatedBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool enableDrag = true,
  bool isDismissible = true,
  bool useRootNavigator = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
    clipBehavior: clipBehavior,
    constraints: constraints,
    barrierColor: barrierColor,
    enableDrag: enableDrag,
    isDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
  );
}

/// OpenContainer wrapper for card-to-detail transitions
/// Use when a card expands into a full page (container transform pattern)
class AnimatedCardContainer extends StatelessWidget {
  final Widget closedChild;
  final Widget Function(BuildContext, VoidCallback) openBuilder;
  final Color? closedColor;
  final Color? openColor;
  final double closedElevation;
  final double openElevation;
  final ShapeBorder? closedShape;
  final ContainerTransitionType transitionType;
  final Duration transitionDuration;

  const AnimatedCardContainer({
    super.key,
    required this.closedChild,
    required this.openBuilder,
    this.closedColor,
    this.openColor,
    this.closedElevation = 0,
    this.openElevation = 4,
    this.closedShape,
    this.transitionType = ContainerTransitionType.fadeThrough,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionType: transitionType,
      transitionDuration: transitionDuration,
      openBuilder: openBuilder,
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          child: closedChild,
        );
      },
      closedColor: closedColor ?? Theme.of(context).cardColor,
      openColor: openColor ?? Theme.of(context).scaffoldBackgroundColor,
      closedElevation: closedElevation,
      openElevation: openElevation,
      closedShape: closedShape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
    );
  }
}
