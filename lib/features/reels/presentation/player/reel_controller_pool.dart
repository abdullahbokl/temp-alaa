import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/config/bunny_stream_resolver.dart';

const BetterPlayerBufferingConfiguration _reelBufferingConfig =
    BetterPlayerBufferingConfiguration(
  minBufferMs: 2000,
  maxBufferMs: 10000,
  bufferForPlaybackMs: 500,
  bufferForPlaybackAfterRebufferMs: 500,
);

const BetterPlayerCacheConfiguration _reelCacheConfig =
    BetterPlayerCacheConfiguration(
  useCache: true,
  maxCacheSize: 128 * 1024 * 1024,
  maxCacheFileSize: 32 * 1024 * 1024,
  preCacheSize: 6 * 1024 * 1024,
);

class ReelControllerPool {
  static final ReelControllerPool _instance = ReelControllerPool._internal();
  factory ReelControllerPool() => _instance;
  ReelControllerPool._internal();

  static const int maxControllers = 3;

  final List<BetterPlayerController> _controllers = <BetterPlayerController>[];
  final Map<String, Completer<bool>> _loadingCompleters = {};

  BetterPlayerController controllerAt(int slot) {
    assert(slot >= 0 && slot < maxControllers);
    while (_controllers.length < maxControllers) {
      _controllers.add(_createController());
    }
    return _controllers[slot];
  }

  BetterPlayerController _createController() {
    return BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: false,
        autoDispose: false,
        looping: true,
        handleLifecycle: false,
        allowedScreenSleep: false,
        autoDetectFullscreenDeviceOrientation: true,
        aspectRatio: 9 / 16,
        fit: BoxFit.cover,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
          enableFullscreen: false,
          enablePlayPause: false,
          enableMute: false,
          enableOverflowMenu: false,
          enableProgressText: false,
          enableProgressBar: true,
          enableSkips: false,
          enableSubtitles: false,
        ),
      ),
    );
  }

  void releaseSlot(int slot) {
    if (slot < 0 || slot >= _controllers.length) return;
    try {
      unawaited(_controllers[slot].pause().catchError((_) {}));
    } catch (_) {}
  }

  bool contains(BetterPlayerController controller) {
    return _controllers.contains(controller);
  }

  static String toBunnyHlsUrl(String bunnyPlayUrl) {
    return BunnyStreamResolver.toHlsUrl(bunnyPlayUrl) ?? bunnyPlayUrl.trim();
  }

  static bool _isIosLikeReelsTarget() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Reels: **HLS** (`playlist.m3u8` via [toBunnyHlsUrl]) — same stream Safari/AVPlayer uses.
  /// On **iOS**, after load: `setVolume(0)` → short delay → `play()` so autoplay actually starts.
  ///
  /// [forceStart]: when false (preload), only attaches the source; use [warmUp] to buffer.
  /// [slotKey]: unique key for this slot to handle fast-swipe locking.
  Future<bool> setDataSource(
    BetterPlayerController controller, {
    required String url,
    bool forceStart = true,
    String? slotKey,
  }) async {
    if (url.trim().isEmpty) return false;

    if (slotKey != null) {
      if (_loadingCompleters.containsKey(slotKey)) {
        return _loadingCompleters[slotKey]!.future;
      }
      _loadingCompleters[slotKey] = Completer<bool>();
    }

    try {
      final result = await _setDataSourceInternal(controller,
          url: url, forceStart: forceStart);
      if (slotKey != null) {
        _loadingCompleters[slotKey]?.complete(result);
        _loadingCompleters.remove(slotKey);
      }
      return result;
    } catch (e) {
      if (slotKey != null) {
        _loadingCompleters[slotKey]?.complete(false);
        _loadingCompleters.remove(slotKey);
      }
      rethrow;
    }
  }

  Future<bool> _setDataSourceInternal(
    BetterPlayerController controller, {
    required String url,
    bool forceStart = true,
  }) async {
    try {
      await controller.pause();
    } catch (_) {}

    final trimmed = url.trim();
    final resolved = BunnyStreamResolver.resolve(trimmed);

    Future<void> tryLoad(String loadUrl, BetterPlayerVideoFormat format) async {
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        loadUrl,
        videoFormat: format,
        headers: resolved.headers,
        cacheConfiguration: _isIosLikeReelsTarget()
            ? const BetterPlayerCacheConfiguration(useCache: false)
            : _reelCacheConfig,
        bufferingConfiguration: _reelBufferingConfig,
      );
      await controller.setupDataSource(dataSource);
    }

    Future<void> forceStartPlayback() async {
      if (!forceStart) return;
      if (_isIosLikeReelsTarget()) {
        try {
          await controller.setVolume(0);
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      try {
        await controller.play();
      } catch (_) {}
      if (_isIosLikeReelsTarget()) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        try {
          await controller.setVolume(1);
        } catch (_) {}
      }
    }

    final hlsUrl = resolved.isHls ? resolved.url : toBunnyHlsUrl(trimmed);
    final isHls = hlsUrl.toLowerCase().contains('.m3u8');

    if (isHls) {
      try {
        await tryLoad(hlsUrl, BetterPlayerVideoFormat.hls);
        await forceStartPlayback();
        return true;
      } catch (e) {
        debugPrint('Reel HLS load failed: $e');
      }
    }

    try {
      await tryLoad(trimmed, BetterPlayerVideoFormat.other);
      await forceStartPlayback();
      return true;
    } catch (e) {
      debugPrint('Reel progressive fallback failed: $e');
    }

    return false;
  }

  Future<void> warmUp(BetterPlayerController controller) async {
    try {
      await controller.setVolume(0);
      await controller.play();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await controller.pause();
      await controller.seekTo(Duration.zero);
    } catch (_) {}
  }

  void pauseAll() {
    for (final c in _controllers) {
      try {
        unawaited(c.pause().catchError((_) {}));
      } catch (_) {}
    }
  }

  void disposeAll() {
    final toDispose = List<BetterPlayerController>.from(_controllers);
    _controllers.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in toDispose) {
        try {
          c.dispose(forceDispose: true);
        } catch (_) {}
      }
    });
  }

  void clearPool() {
    _controllers.clear();
    _loadingCompleters.clear();
  }

  Future<void> preBuffer({
    required int currentIndex,
    required List<String> urls,
    required List<int> slots,
    int bufferAhead = 2,
  }) async {
    if (urls.isEmpty || slots.isEmpty) return;

    for (int offset = 1; offset <= bufferAhead; offset++) {
      final targetIndex = currentIndex + offset;
      if (targetIndex >= urls.length) break;

      final url = urls[targetIndex];
      if (url.isEmpty) continue;

      final slotIndex =
          (slots.length > targetIndex) ? slots[targetIndex] : null;
      if (slotIndex == null || slotIndex >= maxControllers) continue;

      final controller = controllerAt(slotIndex);
      try {
        await setDataSource(
          controller,
          url: url,
          forceStart: false,
          slotKey: 'prebuffer_$targetIndex',
        );
        await warmUp(controller);
      } catch (_) {}
    }
  }
}

final reelControllerPool = ReelControllerPool();
