import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';

/// Duration for all route transitions
const Duration kRouteTransitionDuration = Duration(milliseconds: 300);

/// Fade Through transition page - for bottom nav tab switches
/// Use when UI elements have no spatial relationship
class FadeThroughTransitionPage<T> extends CustomTransitionPage<T> {
  FadeThroughTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          transitionDuration: kRouteTransitionDuration,
          reverseTransitionDuration: kRouteTransitionDuration,
        );
}

/// Shared Axis transition page - for hierarchical navigation
/// Use for parent-child navigation (push routes)
class SharedAxisTransitionPage<T> extends CustomTransitionPage<T> {
  SharedAxisTransitionPage({
    required super.child,
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.scaled,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: transitionType,
              child: child,
            );
          },
          transitionDuration: kRouteTransitionDuration,
          reverseTransitionDuration: kRouteTransitionDuration,
        );
}

/// Fade transition page - simple fade in/out
/// Use for overlays or when minimal transition is preferred
class FadeTransitionPage<T> extends CustomTransitionPage<T> {
  FadeTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: kRouteTransitionDuration,
          reverseTransitionDuration: kRouteTransitionDuration,
        );
}

/// Helper extension to create animated routes more easily
extension AnimatedGoRoute on GoRoute {
  /// Creates a SharedAxis transition (z-axis by default) for this route
  static Page<T> sharedAxisPage<T>({
    required Widget child,
    SharedAxisTransitionType type = SharedAxisTransitionType.scaled,
    String? name,
    Object? arguments,
    String? restorationId,
    LocalKey? key,
  }) {
    return SharedAxisTransitionPage<T>(
      child: child,
      transitionType: type,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      key: key,
    );
  }

  /// Creates a FadeThrough transition for this route
  static Page<T> fadeThroughPage<T>({
    required Widget child,
    String? name,
    Object? arguments,
    String? restorationId,
    LocalKey? key,
  }) {
    return FadeThroughTransitionPage<T>(
      child: child,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      key: key,
    );
  }
}
