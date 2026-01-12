# Animation System

This project uses the official [animations](https://pub.dev/packages/animations) package for consistent Material Design motion.

## Route Transitions

We use `go_router` with custom transition pages defined in `lib/app/animations/route_transitions.dart`.

### Shared Axis Transition (Z-Axis)
Used for hierarchical navigation (e.g., list to detail, search page). Elements scael and fade in/out along the Z-axis.

**Usage:**
```dart
GoRoute(
  path: '/details',
  pageBuilder: (context, state) {
    return SharedAxisTransitionPage(
      key: state.pageKey,
      child: DetailsPage(),
      transitionType: SharedAxisTransitionType.scaled, // Default
    );
  },
),
```

### Fade Through Transition
Used for switching between UI elements that have no strong relationship (e.g., Bottom Navigation Tabs).

**Usage:**
For `go_router` StatefulShellRoutes (Tabs), we use a custom `AnimatedBranchContainer` that implements the Fade Through logic while preserving state (unlike standard `FadeThroughTransitionPage` which resets state).

```dart
// In app_router.dart
StatefulShellRoute(
  navigatorContainerBuilder: (context, navigationShell, children) {
    return AnimatedBranchContainer(
      currentIndex: navigationShell.currentIndex,
      children: children,
    );
  },
  // ...
)
```


## Dialog Animations

All dialogs use the **Fade Scale** pattern.

**Usage:**
```dart
import 'package:drama_tracker/app/animations/dialog_animations.dart';

showAnimatedDialog(
  context: context,
  builder: (context) => MyDialog(),
);
```

## Bottom Sheet Animations

Bottom sheets use a slide + fade transition.

**Usage:**
```dart
import 'package:drama_tracker/app/animations/dialog_animations.dart';

showAnimatedBottomSheet(
  context: context,
  builder: (context) => MyBottomSheet(),
);
```

## Container Transform

Use `AnimatedCardContainer` to expand a card into a full-screen view smoothly.

**Usage:**
```dart
AnimatedCardContainer(
  closedChild: MyCard(),
  openBuilder: (context, closeContainer) => DetailPage(onClose: closeContainer),
);
```
