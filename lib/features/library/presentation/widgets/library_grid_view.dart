import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/domain/entities/media.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import 'library_poster_item.dart';

/// A grid view for displaying collected media posters with configurable columns.
class LibraryGridView extends StatelessWidget {
  final List<Media> items;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final String emptyMessage;
  final String? emptySvg;
  final IconData emptyIcon;
  final int crossAxisCount;
  final double? childAspectRatio;

  const LibraryGridView({
    super.key,
    required this.items,
    this.isLoading = false,
    this.onRefresh,
    this.emptyMessage = '暂无收藏',
    this.emptySvg,
    this.emptyIcon = Icons.collections_bookmark_outlined,
    this.crossAxisCount = 2,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Lottie.asset(
          'assets/lottie/movie_loading.json',
          width: 200,
          height: 200,
        ),
      );
    }

    if (items.isEmpty) {
      return EmptyStateWidget(
        message: emptyMessage,
        icon: emptyIcon,
        svgAsset: emptySvg,
        onAction: null, // No retry button for library empty state
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 30),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio ?? 2 / 3, // Poster aspect ratio
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final media = items[index];
          return LibraryPosterItem(
            media: media,
            onTap: () {
              context.push('/detail', extra: media);
            },
          );
        },
      ),
    );
  }
}
