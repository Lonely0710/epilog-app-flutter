import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SiteType {
  douban,
  tmdb,
  maoyan,
  bangumi,
  other;

  String get title {
    switch (this) {
      case SiteType.douban:
        return '豆瓣';
      case SiteType.tmdb:
        return 'TMDb';
      case SiteType.maoyan:
        return '猫眼电影';
      case SiteType.bangumi:
        return 'Bangumi';
      case SiteType.other:
        return 'Browser';
    }
  }

  String get iconPath {
    switch (this) {
      case SiteType.douban:
        return 'assets/header/ic_web_douban.png';
      case SiteType.tmdb:
        return 'assets/header/ic_web_tmdb.png';
      case SiteType.maoyan:
        return 'assets/header/ic_web_maoyan.png';
      case SiteType.bangumi:
        return 'assets/header/ic_web_bangumi.png';
      case SiteType.other:
        return 'assets/icons/ic_logo.png'; // Default fallback
    }
  }

  double? get iconHeight {
    switch (this) {
      case SiteType.douban:
        return null; // Default
      case SiteType.tmdb:
        return 16;
      case SiteType.maoyan:
        return 32;
      case SiteType.bangumi:
        return 32;
      case SiteType.other:
        return 32;
    }
  }
}

class WebBrowserPageArgs {
  final String url;
  final String title;
  final String headerIconPath;
  final double? headerIconHeight;

  WebBrowserPageArgs({
    required this.url,
    required this.title,
    required this.headerIconPath,
    this.headerIconHeight,
  });

  factory WebBrowserPageArgs.fromSiteType({
    required SiteType siteType,
    required String url,
  }) {
    return WebBrowserPageArgs(
      url: url,
      title: siteType.title,
      headerIconPath: siteType.iconPath,
      headerIconHeight: siteType.iconHeight,
    );
  }
}

class WebBrowserPage extends StatefulWidget {
  final WebBrowserPageArgs args;

  const WebBrowserPage({
    super.key,
    required this.args,
  });

  @override
  State<WebBrowserPage> createState() => _WebBrowserPageState();
}

class _WebBrowserPageState extends State<WebBrowserPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onHttpError: (HttpResponseError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.args.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        elevation: 1,
        title: Image.asset(
          widget.args.headerIconPath,
          height: widget.args.headerIconHeight ?? 24,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            widget.args.title,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_hasError)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/404_not_found.svg',
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _controller.reload();
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
