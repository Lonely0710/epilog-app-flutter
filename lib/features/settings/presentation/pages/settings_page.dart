import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/animations/dialog_animations.dart';
import '../widgets/settings_background.dart';
import '../widgets/typewriter_slogan.dart';
import '../widgets/settings_tile.dart';
import '../widgets/logout_confirm_dialog.dart';
import '../widgets/settings_avatar.dart';
import '../widgets/settings_user_info.dart';
import '../../../../core/presentation/widgets/app_snack_bar.dart';
import '../widgets/about_app_dialog.dart';
import '../widgets/export_dialog.dart';
import '../../../../core/presentation/widgets/shared_dialog_button.dart';
import '../../../../app/theme/app_theme.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/theme_provider.dart';

@Preview()
Widget previewSettingsPage() => const SettingsPage();

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _displayName = 'User';
  String? _avatarUrl;

  // Avatar Editing State
  final GlobalKey _avatarKey = GlobalKey();
  String _avatarSeed = "epilog";
  File? _localImageFile;
  bool _isUsingLocalImage = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _regenerateSeed();
  }

  void _regenerateSeed() {
    setState(
        () => _avatarSeed = DateTime.now().millisecondsSinceEpoch.toString());
  }

  void _loadProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _displayName = user.userMetadata?['display_name'] ?? 'User';
        _avatarUrl = user.userMetadata?['avatar_url'];
      });
    }
  }

  // --- Avatar Logic ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);

    if (pickedFile != null) {
      setState(() {
        _localImageFile = File(pickedFile.path);
        _isUsingLocalImage = true;
      });
      // Auto-save when picking local image
      _saveAvatar();
    }
  }

  Future<void> _onRefreshAvatar() async {
    _regenerateSeed();
    setState(() {
      _isUsingLocalImage = false;
      _localImageFile = null;
    });
    // Wait for render, then save
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveAvatar());
  }

  Future<Uint8List?> _captureAvatarPng() async {
    try {
      RenderRepaintBoundary? boundary = _avatarKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      await Future.delayed(const Duration(milliseconds: 50)); // Wait for render
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Capture error: $e");
      return null;
    }
  }

  Future<String?> _uploadFile(
      String path, Uint8List bytes, String contentType) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileExt = contentType == 'image/png' ? 'png' : 'jpg';
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await Supabase.instance.client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      return Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> _saveAvatar() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      String? newUrl;
      if (_isUsingLocalImage && _localImageFile != null) {
        final bytes = await _localImageFile!.readAsBytes();
        newUrl = await _uploadFile(_localImageFile!.path, bytes, 'image/jpeg');
      } else {
        final bytes = await _captureAvatarPng();
        if (bytes != null) {
          newUrl = await _uploadFile('generated.png', bytes, 'image/png');
        }
      }

      if (newUrl != null) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'avatar_url': newUrl}),
        );
        setState(() => _avatarUrl = newUrl);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('头像已更新')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('更新失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isUsingLocalImage = false;
          _localImageFile = null;
        });
      }
    }
  }

  // --- Name Editing Logic ---
  Future<void> _editName() async {
    final controller = TextEditingController(text: _displayName);
    await showAnimatedDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '修改昵称',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  // Color inherited from dialog theme or explicit
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "请输入新的昵称",
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  SharedDialogButton(
                    text: '取消',
                    icon: Icons.close,
                    isPrimary: false,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  SharedDialogButton(
                    text: '保存',
                    icon: Icons.check,
                    isPrimary: true,
                    onTap: () async {
                      final newName = controller.text.trim();
                      if (newName.isNotEmpty) {
                        await Supabase.instance.client.auth.updateUser(
                          UserAttributes(data: {'display_name': newName}),
                        );
                        setState(() => _displayName = newName);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showAnimatedDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const LogoutConfirmDialog(),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('退出失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    // For mailto, we let the platform decide the best mode
    final mode = url.scheme == 'mailto'
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication;

    try {
      if (!await launchUrl(url, mode: mode)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        if (url.scheme == 'mailto') {
          // Fallback for mailto: Copy email to clipboard
          final email = url.path;
          await Clipboard.setData(ClipboardData(text: email));
          if (mounted) {
            AppSnackBar.showSuccess(context, '邮箱已复制到剪贴板');
          }
        } else {
          if (mounted) {
            AppSnackBar.showError(context, message: '无法打开链接: $urlString');
          }
        }
      }
    }
  }

  void _showExportDialog() {
    showAnimatedDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const ExportDialog(),
    );
  }

  void _showUnderDevelopmentDialog() {
    showAnimatedDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = Theme.of(context).cardColor;

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: dialogBg,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_outlined,
                          color: AppTheme.primary, size: 32),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '通知设置',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '该功能正在开发中，敬请期待...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close,
                      color: isDark
                          ? Colors.grey[400]
                          : Theme.of(context).hintColor),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutUs() {
    showAnimatedDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const AboutAppDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Icons configuration:
    const iconDarkMode = Icons.brightness_6_rounded;
    const iconNotification = Icons.notifications_active_outlined;
    const iconData = Icons.storage_rounded;

    return SettingsBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Header Section
            Center(
              child: Column(
                children: [
                  // Header Section
                  Center(
                    child: Column(
                      children: [
                        // Avatar with Edit Capability
                        SettingsAvatar(
                          avatarKey: _avatarKey,
                          avatarSeed: _avatarSeed,
                          avatarUrl: _avatarUrl,
                          isUsingLocalImage: _isUsingLocalImage,
                          localImageFile: _localImageFile,
                          isUploading: _isUploading,
                          onRefresh: _onRefreshAvatar,
                          onPickImage: _pickImage,
                        ),
                        const SizedBox(height: 16),
                        const TypewriterSlogan(),
                        const SizedBox(height: 8),

                        // Name with Hand-Drawn Underline
                        SettingsUserInfo(
                          displayName: _displayName,
                          onEditName: _editName,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settings List
            SettingsTile(
              icon: iconDarkMode,
              iconColor: AppTheme.primary,
              title: '深色模式',
              subtitle: '切换应用的主题颜色',
              trailing: Transform.scale(
                scale: 0.8,
                child: Consumer(
                  builder: (context, ref, child) {
                    final themeMode = ref.watch(themeModeProvider);
                    final isDark = themeMode == ThemeMode.dark;
                    return Switch(
                      value: isDark,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).toggleTheme(val);
                      },
                      activeThumbColor: AppTheme.primary,
                      activeTrackColor: AppTheme.primary.withValues(alpha: 0.4),
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.grey[300],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingsTile(
              icon: iconNotification,
              iconColor: AppTheme.primary,
              title: '通知设置',
              subtitle: '管理应用通知',
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
              onTap: _showUnderDevelopmentDialog,
            ),
            const SizedBox(height: 12),
            SettingsTile(
              icon: iconData,
              iconColor: AppTheme.primary,
              title: '数据管理',
              subtitle: '导出收藏数据',
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
              onTap: _showExportDialog,
            ),
            const SizedBox(height: 12),
            // Logout - same format as other tiles
            SettingsTile(
              icon: Icons.logout_rounded,
              iconColor: AppTheme.error,
              title: 'Log out',
              subtitle: '退出当前账号',
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 20),

            // Help & About Cards Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.2)
                              : Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.08),
                          width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .shadowColor
                              .withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.help_outline_rounded,
                                size: 22, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              '帮助与反馈',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _launchUrl('https://github.com/Lonely0710'),
                                child: Image.asset(
                                  'assets/icons/ic_staff_github.png',
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    _launchUrl('mailto:lingsou43@gmail.com'),
                                child: Image.asset(
                                  'assets/icons/ic_staff_gmail.png',
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _showAboutUs,
                    child: Container(
                      height: 100,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.2)
                                    : Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.08),
                            width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .shadowColor
                                .withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 22, color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    '关于我们',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Center(
                                child: Text(
                                  'v1.0.0',
                                  style: TextStyle(
                                    fontFamily: 'CourierPrime',
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/icons/ic_avatar.jpg',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 100), // Extra padding for bottom nav
          ],
        ),
      ),
    );
  }
}
