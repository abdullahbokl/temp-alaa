import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/storage/hive_service.dart';
import 'core/network/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase only on supported platforms to avoid noisy platform channel errors
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await Firebase.initializeApp();
      await FirebaseInAppMessaging.instance
          .setAutomaticDataCollectionEnabled(true);
    } catch (error) {
      debugPrint('Firebase initialization skipped on this device: $error');
    }
  } else {
    debugPrint('Firebase not supported or configured for the current platform (${defaultTargetPlatform.name}). Skipping.');
  }

  await Future.wait([
    HiveService.init(),
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]),
    _setSystemUI(),
  ]);

  await Future.wait([CacheService.init(), initDependencies()]);

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  runApp(const LearnifyApp());
}

Future<void> _setSystemUI() async {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
}


