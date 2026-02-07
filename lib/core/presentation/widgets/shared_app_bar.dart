import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../features/auth/data/convex_user_repository.dart';

class SharedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showAvatar;

  const SharedAppBar({
    super.key,
    required this.title,
    this.showAvatar = true,
  });

  @override
  State<SharedAppBar> createState() => _SharedAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SharedAppBarState extends State<SharedAppBar> {
  Stream<Map<String, dynamic>?>? _userStream;

  @override
  void initState() {
    super.initState();
    if (widget.showAvatar) {
      _userStream = ConvexUserRepository.instance.watchCurrentUser();
    }
  }

  @override
  void didUpdateWidget(covariant SharedAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showAvatar != oldWidget.showAvatar) {
      if (widget.showAvatar) {
        _userStream = ConvexUserRepository.instance.watchCurrentUser();
      } else {
        _userStream = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get Clerk Auth state for fallback and auth status
    final authState = ClerkAuth.of(context, listen: true);
    final clerkUser = authState.user;
    final clerkAvatarUrl = clerkUser?.imageUrl;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: widget.showAvatar ? _userStream : null,
      builder: (context, snapshot) {
        final convexUser = snapshot.data;
        final convexAvatarUrl = convexUser?['avatarUrl'] as String?;

        // Prioritize Convex avatar, then Clerk avatar
        final avatarUrl = convexAvatarUrl ?? clerkAvatarUrl;

        return AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leadingWidth: 56, // Adjust if needed
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Image.asset(
              'assets/icons/ic_badge.png',
              fit: BoxFit.contain,
            ),
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pacifico',
            ),
          ),
          actions: [
            if (widget.showAvatar)
              GestureDetector(
                onTap: () {
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
              )
            else
              const SizedBox(width: 48), // Placeholder
          ],
        );
      },
    );
  }
}
