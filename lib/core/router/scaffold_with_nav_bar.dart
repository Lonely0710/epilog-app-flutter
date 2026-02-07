import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../app/theme/app_colors.dart';
import '../presentation/widgets/shared_app_bar.dart';

/// InheritedWidget to provide nav visibility control to child widgets
class NavVisibilityController extends InheritedWidget {
  final VoidCallback toggleNavVisibility;
  final void Function(bool) setNavVisibility;
  final bool isNavVisible;
  final int currentIndex;

  const NavVisibilityController({
    super.key,
    required this.toggleNavVisibility,
    required this.setNavVisibility,
    required this.isNavVisible,
    required this.currentIndex,
    required super.child,
  });

  static NavVisibilityController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NavVisibilityController>();
  }

  @override
  bool updateShouldNotify(NavVisibilityController oldWidget) {
    return isNavVisible != oldWidget.isNavVisible || currentIndex != oldWidget.currentIndex;
  }
}

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
      : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> with TickerProviderStateMixin {
  bool _isNavVisible = true;
  late AnimationController _visibilityController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Animation controller for tab switching
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;
  int _previousIndex = 0;

  // Drag state
  double? _dragValue;

  // Store the fractional position when drag ends to use as animation start
  double? _dragEndPosition;

  @override
  void initState() {
    super.initState();
    _visibilityController = AnimationController(
      // Slightly longer duration for smoother nav bar transitions
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _visibilityController,
      // Use emphasized curve for smoother fade
      curve: Curves.easeInOutCubicEmphasized,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _visibilityController,
      // Use emphasized curve for smoother slide
      curve: Curves.easeInOutCubicEmphasized,
    ));

    // Tab animation controller
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _tabAnimation = CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.fastOutSlowIn,
    );
    _tabAnimationController.value = 1.0; // Start completed

    // Start with nav visible
    _visibilityController.value = 0;
    _previousIndex = widget.navigationShell.currentIndex;
  }

  @override
  void dispose() {
    _visibilityController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  void _toggleNavVisibility() {
    setState(() {
      _isNavVisible = !_isNavVisible;
    });
    if (_isNavVisible) {
      _visibilityController.reverse();
    } else {
      _visibilityController.forward();
    }
  }

  void _setNavVisibility(bool visible) {
    if (visible != _isNavVisible) {
      setState(() {
        _isNavVisible = visible;
      });
      if (visible) {
        _visibilityController.reverse();
      } else {
        _visibilityController.forward();
      }
    }
  }

  // Library is now at index 2 (after swapping with Recommend)
  bool get _isLibraryPage => widget.navigationShell.currentIndex == 2;

  @override
  void didUpdateWidget(covariant ScaffoldWithNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate tab change
    if (oldWidget.navigationShell.currentIndex != widget.navigationShell.currentIndex) {
      // If we have a stored drag end position, animate from there
      // The _dragEndPosition will be cleared in AnimatedBuilder after animation completes
      if (_dragEndPosition != null) {
        // Start the animation from 0, the AnimatedBuilder will use _dragEndPosition
        _tabAnimationController.forward(from: 0);
      } else if (_dragValue == null) {
        _previousIndex = oldWidget.navigationShell.currentIndex;
        _tabAnimationController.forward(from: 0);
      } else {
        // If we were dragging, the movement was manual. Ensure we are settled.
        _previousIndex = oldWidget.navigationShell.currentIndex;
        _tabAnimationController.value = 1.0;
      }
    }

    // When navigating away from Library, ensure nav is visible
    if (!_isLibraryPage && !_isNavVisible) {
      _setNavVisibility(true);
    }
    // When entering Library, ensure nav is visible initially (reset state)
    // User will manually trigger full screen via light cord interactions
    if (_isLibraryPage && oldWidget.navigationShell.currentIndex != 2 && !_isNavVisible) {
      _setNavVisibility(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return NavVisibilityController(
      toggleNavVisibility: _toggleNavVisibility,
      setNavVisibility: _setNavVisibility,
      isNavVisible: _isNavVisible,
      currentIndex: widget.navigationShell.currentIndex,
      child: Scaffold(
        // Hide app bar for Library page (immersive mode)
        // Adjust title for 'Hot'
        appBar: _isLibraryPage
            ? null
            : SharedAppBar(
                title: _getTitle(widget.navigationShell.currentIndex),
                showAvatar: widget.navigationShell.currentIndex == 0 || widget.navigationShell.currentIndex == 1,
              ),
        body: widget.navigationShell,
        // Animated bottom navigation for immersive mode
        bottomNavigationBar: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: ReverseAnimation(_fadeAnimation),
            child: _buildBottomNavBar(context, bottomPadding),
          ),
        ),
        extendBody: true,
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, double bottomPadding) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;
    const itemsCount = 4;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 16,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[100],
          borderRadius: BorderRadius.circular(32),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;

            // Revert flex values to previous logic for simplicity and stability if needed,
            // but user wants smooth sliding.
            const selectedFlex = 2.0;
            const unselectedFlex = 1.0;

            // Geometry helper calculating layout for a fractional index
            // We use a Record (dart 3) to return values
            ({double pillLeft, double pillWidth, List<double> itemLefts, List<double> itemWidths}) calculateLayout(
                double fractionalIndex) {
              // 1. Calculate weights for each item
              // Weight is interpolated between unselected (1.0) and selected (2.0)
              // based on distance from fractionalIndex
              final weights = List.generate(itemsCount, (i) {
                final distance = (fractionalIndex - i).abs();
                // If distance is 0 (selected), weight is 2.0
                // If distance is >= 1 (unselected), weight is 1.0
                final t = (1.0 - distance).clamp(0.0, 1.0);
                // Standard linear interpolation
                return lerpDouble(unselectedFlex, selectedFlex, t)!;
              });

              final totalWeight = weights.reduce((a, b) => a + b);
              final unitWidth = availableWidth / totalWeight;

              final itemWidths = weights.map((w) => w * unitWidth).toList();
              final itemLefts = <double>[];
              double currentLeft = 0;
              for (final w in itemWidths) {
                itemLefts.add(currentLeft);
                currentLeft += w;
              }

              // Calculate pill geometry
              // The pill should be positioned corresponding to the fractional index.
              // We interpolate between the geometries of the floor(index) and ceil(index).
              final lowerIndex = fractionalIndex.floor().clamp(0, itemsCount - 1);
              final upperIndex = (lowerIndex + 1).clamp(0, itemsCount - 1);
              final t = fractionalIndex - lowerIndex;

              final lowerLeft = itemLefts[lowerIndex];
              final lowerWidth = itemWidths[lowerIndex];

              final upperLeft = itemLefts[upperIndex];
              final upperWidth = itemWidths[upperIndex];

              final pillLeft = lerpDouble(lowerLeft, upperLeft, t)!;
              final pillWidth = lerpDouble(lowerWidth, upperWidth, t)!;

              return (
                pillLeft: pillLeft,
                pillWidth: pillWidth,
                itemLefts: itemLefts,
                itemWidths: itemWidths,
              );
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque, // Ensure we catch drags
              onHorizontalDragStart: (details) {
                setState(() {
                  _dragValue = currentIndex.toDouble();
                });
              },
              onHorizontalDragUpdate: (details) {
                if (_dragValue == null) return;
                // Sensitivity calculation
                // Total width = availableWidth
                // Total indices = itemsCount - 1 (range 0..3)
                // Let's say dragging full width moves across all tabs?
                // Or dragging one "tab width" moves one tab.
                // Avg tab width is availableWidth / 4.
                // So delta / (availableWidth/4) = deltaIndex.
                final deltaIndex = details.primaryDelta! / (availableWidth / itemsCount);
                setState(() {
                  _dragValue = (_dragValue! + deltaIndex).clamp(0.0, itemsCount - 1 + 0.0);
                });
              },
              onHorizontalDragEnd: (details) {
                if (_dragValue == null) return;

                final velocity = details.primaryVelocity ?? 0;
                int targetIndex = _dragValue!.round();

                // Flick support
                if (velocity.abs() > 300) {
                  if (velocity > 0) {
                    // Flick right
                    targetIndex = _dragValue!.floor() + 1;
                  } else {
                    // Flick left
                    targetIndex = _dragValue!.ceil() - 1;
                  }
                }

                targetIndex = targetIndex.clamp(0, itemsCount - 1);

                // Store the current drag position before clearing
                // This will be used as the animation start point
                final dragEndPos = _dragValue!;

                setState(() {
                  _dragEndPosition = dragEndPos;
                  _dragValue = null;
                });
                _onTap(context, targetIndex);
              },
              onHorizontalDragCancel: () {
                setState(() {
                  _dragValue = null;
                });
              },
              child: AnimatedBuilder(
                animation: _tabAnimation,
                builder: (context, child) {
                  // Determine the driving value for the layout
                  // If dragging, use _dragValue
                  // If animating after drag, interpolate from drag end position to target
                  // Otherwise, interpolate between _previousIndex and currentIndex
                  double drivingValue;
                  if (_dragValue != null) {
                    drivingValue = _dragValue!;
                  } else if (_dragEndPosition != null) {
                    // Animate from the exact drag end position to the target
                    drivingValue = lerpDouble(
                      _dragEndPosition!,
                      currentIndex.toDouble(),
                      _tabAnimation.value,
                    )!;
                    // Clear the drag end position once animation completes
                    if (_tabAnimation.value >= 1.0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _dragEndPosition = null;
                          });
                        }
                      });
                    }
                  } else {
                    drivingValue = lerpDouble(
                      _previousIndex.toDouble(),
                      currentIndex.toDouble(),
                      _tabAnimation.value,
                    )!;
                  }

                  final layout = calculateLayout(drivingValue);

                  return Stack(
                    children: [
                      // Liquid Glass Selection Indicator
                      Positioned(
                        left: layout.pillLeft,
                        top: 0,
                        bottom: 0,
                        width: layout.pillWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: LiquidGlassLayer(
                            settings: LiquidGlassSettings(
                              thickness: isDark ? 15 : 10,
                              blur: isDark ? 0 : 2,
                              glassColor: isDark ? const Color(0x22FFFFFF) : Colors.white.withValues(alpha: 0.4),
                            ),
                            child: FakeGlass(
                              shape: LiquidRoundedSuperellipse(
                                borderRadius: 24,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.primary.withValues(alpha: 0.85) : AppColors.primary,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Tab Items
                      ...List.generate(itemsCount, (index) {
                        final left = layout.itemLefts[index];
                        final width = layout.itemWidths[index];

                        // Text opacity logic based on drivingValue
                        // 1.0 when index == drivingValue, 0.0 when |index - drivingValue| >= 1
                        final distance = (drivingValue - index).abs();
                        double textOpacity = (1.0 - distance).clamp(0.0, 1.0);
                        textOpacity = Curves.easeOut.transform(textOpacity);

                        return Positioned(
                          left: left,
                          top: 0,
                          bottom: 0,
                          width: width,
                          child: _buildTabItem(
                            context,
                            index: index,
                            activeIcon: _getActiveIcon(index),
                            inactiveIcon: _getInactiveIcon(index),
                            label: _getLabel(index),
                            // Visually selected if closest
                            isSelected: index == drivingValue.round(),
                            isDark: isDark,
                            textOpacity: textOpacity,
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getActiveIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.whatshot; // Hot
      case 2:
        return Icons.video_library;
      case 3:
        return Icons.person; // Profile
      default:
        return Icons.circle;
    }
  }

  IconData _getInactiveIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_outlined;
      case 1:
        return Icons.whatshot_outlined; // Hot
      case 2:
        return Icons.video_library_outlined;
      case 3:
        return Icons.person_outline; // Profile
      default:
        return Icons.circle_outlined;
    }
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return '首页';
      case 1:
        return '推荐';
      case 2:
        return '资料库';
      case 3:
        return '账户';
      default:
        return '';
    }
  }

  Widget _buildTabItem(
    BuildContext context, {
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required double textOpacity,
  }) {
    final inactiveColor = isDark ? Colors.grey[400]! : Colors.grey;

    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.translucent,
      child: Center(
        // Use Center instead of Column
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              // Increased icon sizes: Active 32, Inactive 28
              size: isSelected ? 32 : 28,
              color: isSelected ? Colors.white : inactiveColor,
            ),
            if (textOpacity > 0.01) ...[
              SizedBox(width: 8 * textOpacity),
              Opacity(
                opacity: textOpacity,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: textOpacity,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Hot';
      case 2:
        return 'Library';
      case 3:
        return 'Settings';
      default:
        return 'Epilog';
    }
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
