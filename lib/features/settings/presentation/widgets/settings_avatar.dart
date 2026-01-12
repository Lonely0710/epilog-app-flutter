import 'dart:io';
import 'package:flutter/material.dart';
import 'package:avatar_plus/avatar_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../app/theme/app_theme.dart';

class SettingsAvatar extends StatelessWidget {
  final GlobalKey avatarKey;
  final String avatarSeed;
  final String? avatarUrl;
  final bool isUsingLocalImage;
  final File? localImageFile;
  final bool isUploading;
  final VoidCallback onRefresh;
  final VoidCallback onPickImage;

  const SettingsAvatar({
    super.key,
    required this.avatarKey,
    required this.avatarSeed,
    this.avatarUrl,
    required this.isUsingLocalImage,
    this.localImageFile,
    required this.isUploading,
    required this.onRefresh,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: avatarKey,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                    blurRadius: 8)
              ],
            ),
            child: ClipOval(
              child: isUsingLocalImage && localImageFile != null
                  ? Image.file(localImageFile!, fit: BoxFit.cover)
                  : (avatarUrl != null &&
                          avatarUrl!.isNotEmpty &&
                          !isUsingLocalImage
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => AvatarPlus(
                            avatarSeed,
                            height: 80,
                            width: 80,
                          ),
                        )
                      : AvatarPlus(avatarSeed, height: 80, width: 80)),
            ),
          ),
        ),
        // Refresh Button
        Positioned(
          top: 0,
          right: 0,
          child: InkWell(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.refresh, color: Colors.white, size: 14),
            ),
          ),
        ),
        // Add Photo Button
        Positioned(
          bottom: 0,
          right: 0,
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
              child: Icon(Icons.add_photo_alternate,
                  color: AppTheme.primary, size: 16),
            ),
          ),
        ),
        if (isUploading)
          Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor),
            ),
          ),
      ],
    );
  }
}
