import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_notion_avatar/flutter_notion_avatar.dart';
import 'package:flutter_notion_avatar/flutter_notion_avatar_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../app/theme/app_theme.dart';

class SettingsAvatar extends StatelessWidget {
  final GlobalKey avatarKey;
  final String? avatarUrl;
  final bool isUsingLocalImage;
  final File? localImageFile;
  final bool isUploading;
  final VoidCallback onRefresh;
  final VoidCallback onPickImage;

  const SettingsAvatar({
    super.key,
    required this.avatarKey,
    this.avatarUrl,
    required this.isUsingLocalImage,
    this.localImageFile,
    required this.isUploading,
    required this.onRefresh,
    required this.onPickImage,
    this.onCreated,
  });

  final ValueChanged<NotionAvatarController>? onCreated;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(
          key: avatarKey,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
              boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.1), blurRadius: 8)],
            ),
            child: ClipOval(
              child: isUsingLocalImage && localImageFile != null
                  ? Image.file(localImageFile!, fit: BoxFit.cover)
                  : (avatarUrl != null && avatarUrl!.isNotEmpty && !isUsingLocalImage
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : SizedBox(
                          width: 80,
                          height: 80,
                          child: NotionAvatar(
                            useRandom: true,
                            onCreated: onCreated,
                          ),
                        )),
            ),
          ),
        ),
        // Refresh Button
        Positioned(
          top: -4,
          right: -4,
          child: InkWell(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.refresh, color: Colors.white, size: 14),
            ),
          ),
        ),
        // Add Photo Button
        Positioned(
          bottom: -4,
          right: -4,
          child: InkWell(
            onTap: onPickImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.primary.withValues(alpha: 0.2)
                      : Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  )),
              child: Icon(Icons.add_photo_alternate, color: AppTheme.primary, size: 16),
            ),
          ),
        ),
        if (isUploading)
          Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
            ),
          ),
      ],
    );
  }
}
