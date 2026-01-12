import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showAvatar;

  const SharedAppBar({
    super.key,
    required this.title,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    // Get current user for avatar
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 56, // Adjust if needed
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Image.asset(
          'assets/icons/ic_logo.png',
          fit: BoxFit.contain,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pacifico',
        ),
      ),
      actions: [
        if (showAvatar && user != null) ...[
          GestureDetector(
            onTap: () {
              // Navigate to settings page
              // Assuming '/settings' is the route path for the settings tab
              context.go('/settings');
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.grey,
                      ),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(
              width:
                  48), // Placeholder to balance title if needed, or just empty
        ]
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
