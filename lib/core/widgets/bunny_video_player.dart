import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:better_player_plus/better_player_plus.dart';

import '../config/bunny_stream_resolver.dart';

const BetterPlayerBufferingConfiguration _lessonBufferingConfig =
    BetterPlayerBufferingConfiguration(
  minBufferMs: 1000,
  maxBufferMs: 5000,
  bufferForPlaybackMs: 250,
  bufferForPlaybackAfterRebufferMs: 500,
);

const BetterPlayerCacheConfiguration _lessonCacheConfig =
    BetterPlayerCacheConfiguration(
  useCache: true,
  maxCacheSize: 128 * 1024 * 1024,
  maxCacheFileSize: 32 * 1024 * 1024,
  preCacheSize: 6 * 1024 * 1024,
);

class BunnyVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoLoaded;

  const BunnyVideoPlayer({
    super.key,
    required this.videoUrl,
    this.onVideoLoaded,
  });

  @override
  State<BunnyVideoPlayer> createState() => _BunnyVideoPlayerState();
}

class _BunnyVideoPlayerState extends State<BunnyVideoPlayer> {
  WebViewController? _webController;
  BetterPlayerController? _betterPlayerController;
  bool _isLoading = true;

  static bool _isIosTarget() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  String _getEmbedUrl(String url) {
    String embedUrl = url.replaceFirst('/play/', '/embed/');

    if (!embedUrl.contains('?')) {
      embedUrl = '$embedUrl?autoplay=true&responsive=true&aspectRatio=16:9';
    } else {
      embedUrl = '$embedUrl&autoplay=true&responsive=true&aspectRatio=16:9';
    }
    return embedUrl;
  }

  @override
  void initState() {
    super.initState();
    final resolved = BunnyStreamResolver.resolve(widget.videoUrl);
    final shouldUseNative = resolved.url.isNotEmpty &&
        (resolved.isHls ||
            widget.videoUrl.trim().toLowerCase().contains('.mp4'));

    if (shouldUseNative) {
      _initNativePlayer();
    } else {
      _initWebViewPlayer();
    }
  }

  Future<void> _initNativePlayer() async {
    final controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        handleLifecycle: true,
        looping: false,
        fit: BoxFit.contain,
        deviceOrientationsOnFullScreen: const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: true,
          enableFullscreen: true,
          enablePlayPause: true,
          enableMute: true,
          enableProgressText: true,
          enableProgressBar: true,
        ),
      ),
    );

    final resolved = BunnyStreamResolver.resolve(widget.videoUrl);
    final format = resolved.isHls
        ? BetterPlayerVideoFormat.hls
        : BetterPlayerVideoFormat.other;
    final useCache = !_isIosTarget();

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      resolved.url,
      videoFormat: format,
      headers: resolved.headers,
      cacheConfiguration: useCache
          ? _lessonCacheConfig
          : const BetterPlayerCacheConfiguration(useCache: false),
      bufferingConfiguration: _lessonBufferingConfig,
    );

    await controller.setupDataSource(dataSource);
    if (_isIosTarget()) {
      try {
        await controller.setVolume(0);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 100));
      try {
        await controller.play();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        await controller.setVolume(1);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _betterPlayerController = controller;
      _isLoading = false;
    });
    widget.onVideoLoaded?.call();
  }

  void _initWebViewPlayer() {
    final embedUrl = _getEmbedUrl(widget.videoUrl);

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { 
      width: 100%;
      height: 100%;
      background: #000;
      overflow: hidden;
      margin: 0;
      padding: 0;
    }
    .video-wrapper {
      position: relative;
      width: 100%;
      height: 100%;
      overflow: hidden;
    }
    iframe {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      border: 0;
      min-width: 100%;
      min-height: 100%;
    }
  </style>
</head>
<body>
  <div class="video-wrapper">
    <iframe 
      src="$embedUrl"
      loading="lazy"
      style="border:0;position:absolute;top:50%;left:0;width:100%;height:100%;transform:translateY(-50%);"
      allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;fullscreen"
      allowfullscreen="true">
    </iframe>
  </div>
</body>
</html>
''';

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
              widget.onVideoLoaded?.call();
            }
          },
        ),
      )
      ..loadHtmlString(html);
  }

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    _betterPlayerController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_betterPlayerController != null)
            BetterPlayer(controller: _betterPlayerController!)
          else if (_webController != null)
            WebViewWidget(controller: _webController!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
