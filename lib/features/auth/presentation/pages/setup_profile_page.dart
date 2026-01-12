import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avatar_plus/avatar_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_theme.dart';
import '../widgets/success_dialog.dart';

class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  // Avatar State
  final GlobalKey _avatarKey = GlobalKey();
  String _avatarSeed = "epilog"; // Initial seed
  File? _localImageFile;
  bool _isUsingLocalImage = false;

  // Existing avatar from DB
  String? _existingAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _regenerateSeed();
    _usernameController.addListener(() {
      setState(() {});
    });
  }

  void _loadInitialData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata;
      _usernameController.text = metadata?['display_name'] as String? ?? '';
      _existingAvatarUrl = metadata?['avatar_url'] as String?;
    }
  }

  void _regenerateSeed() {
    setState(() {
      _avatarSeed = DateTime.now().millisecondsSinceEpoch.toString();
      _isUsingLocalImage = false;
      _localImageFile = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);

    if (pickedFile != null) {
      setState(() {
        _localImageFile = File(pickedFile.path);
        _isUsingLocalImage = true;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureAvatarPng() async {
    try {
      RenderRepaintBoundary? boundary = _avatarKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Delay slightly to ensure render
      await Future.delayed(const Duration(milliseconds: 20));

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing avatar: $e");
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

      // Upload
      await Supabase.instance.client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      // Get URL
      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '请输入用户名',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.primaryFont,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF333333),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          margin: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? finalAvatarUrl = _existingAvatarUrl;

      // Handle Avatar Upload if changed
      // If using local image
      if (_isUsingLocalImage && _localImageFile != null) {
        final bytes = await _localImageFile!.readAsBytes();
        final url =
            await _uploadFile(_localImageFile!.path, bytes, 'image/jpeg');
        if (url != null) finalAvatarUrl = url;
      }
      // If using generated avatar (and existing is null or user wants to overwrite old custom one with new generated)
      // Limitation: We don't track if 'generated' is 'new' vs 'old'.
      // Strategy: If _isUsingLocalImage is false, we capture whatever is on screen (AvatarPlus) and upload it.
      // This ensures we persist the generated avatar forever.
      else if (!_isUsingLocalImage) {
        final bytes = await _captureAvatarPng();
        if (bytes != null) {
          final url = await _uploadFile('generated.png', bytes, 'image/png');
          if (url != null) finalAvatarUrl = url;
        }
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': username,
            'avatar_url': finalAvatarUrl,
            'has_set_username': true,
          },
        ),
      );

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(
            onDismiss: () {
              Navigator.of(context).pop(); // Close dialog
              context.go('/home'); // Navigate to home
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '保存失败: $e',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.primaryFont,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            margin: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1A2A3A) : AppTheme.surface;
    final borderColor = isDark ? Colors.grey.shade700 : AppTheme.divider;
    final titleColor = isDark ? Colors.white : AppTheme.textPrimary;
    final buttonBgColor = isDark ? const Color(0xFF1A2A3A) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    RepaintBoundary(
                      key: _avatarKey,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: surfaceColor,
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        // ClipOval is essential for RepaintBoundary capture to look round?
                        // Actually RepaintBoundary captures the widget rect.
                        // If we want transparency outside circle, the container decoration handles clipping visually,
                        // but the captured image will be a square with transparency corners IF container supports it.
                        // Let's use ClipOval to be safe.
                        child: ClipOval(
                          child: _isUsingLocalImage && _localImageFile != null
                              ? Image.file(_localImageFile!, fit: BoxFit.cover)
                              : AvatarPlus(
                                  _avatarSeed,
                                  height: 120,
                                  width: 120,
                                ),
                        ),
                      ),
                    ),

                    // Refresh Button (Only for generated)
                    if (!_isUsingLocalImage)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _regenerateSeed,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.refresh,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),

                    // Add Image Button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: buttonBgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add_photo_alternate,
                              color: AppTheme.primary, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                "设置你的昵称",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                "不管是真名还是代号，告诉我们该如何称呼你。",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color:
                        isDark ? Colors.grey.shade400 : AppTheme.textSecondary),
              ),
              const SizedBox(height: 48),

              // Username Field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "昵称",
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: _usernameController.text.isNotEmpty
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "开启 Epilog 之旅",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
