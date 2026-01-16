import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';

class CorePaginationGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, int index, T item) itemBuilder;
  final Future<void> Function() onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry padding;
  final Widget? emptyWidget;

  const CorePaginationGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.isLoading,
    required this.hasMore,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.55,
    this.mainAxisSpacing = 10,
    this.crossAxisSpacing = 10,
    this.padding = const EdgeInsets.all(16),
    this.emptyWidget,
  });

  @override
  State<CorePaginationGridView<T>> createState() => _CorePaginationGridViewState<T>();
}

class _CorePaginationGridViewState<T> extends State<CorePaginationGridView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !widget.isLoading &&
        widget.hasMore) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_filter_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无数据',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
    }

    if (widget.items.isEmpty && widget.isLoading) {
      return Center(
        child: Lottie.asset(
          'assets/lottie/movie_loading.json',
          width: 200,
          height: 200,
        ),
      );
    }

    return AnimationLimiter(
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: widget.padding,
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
                childAspectRatio: widget.childAspectRatio,
                crossAxisSpacing: widget.crossAxisSpacing,
                mainAxisSpacing: widget.mainAxisSpacing,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: widget.crossAxisCount,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: widget.itemBuilder(context, index, widget.items[index]),
                      ),
                    ),
                  );
                },
                childCount: widget.items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: _buildFooter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (widget.isLoading) {
      return Lottie.asset(
        'assets/lottie/movie_loading.json',
        width: 60,
        height: 60,
      );
    } else if (widget.hasMore) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: InkWell(
          onTap: widget.onLoadMore,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              // Gradient for premium feel in dark mode, clean card color in light
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: Theme.of(context).brightness == Brightness.dark ? null : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1) // Subtle frosting
                    : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                      : Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 12, // Softer shadow
                  offset: const Offset(0, 4),
                  spreadRadius: Theme.of(context).brightness == Brightness.dark ? 1 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '加载更多',
                  style: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 16,
                  color:
                      Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 1,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 12),
            Text(
              '没有更多数据了',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 1,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
            ),
          ],
        ),
      );
    }
  }
}
