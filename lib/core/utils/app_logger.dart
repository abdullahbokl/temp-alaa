import 'package:flutter/foundation.dart';

/// A centralized logging utility for LearnifyLMS.
/// 
/// This allows controlling the verbosity of logs throughout the application.
class AppLogger {
  static bool isEnabled = kDebugMode;
  static bool showNetworkLogs = false; // Disable network logs by default to prevent terminal lag
  static bool showBlocLogs = true;
  static bool showAssetLogs = false;

  static void log(String message, {String? tag}) {
    if (!isEnabled) return;
    
    final tagPrefix = tag != null ? '[$tag] ' : '';
    debugPrint('$tagPrefix$message');
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!isEnabled) return;
    
    final tagPrefix = tag != null ? '[$tag ERROR] ' : '[ERROR] ';
    debugPrint('$tagPrefix$message');
    if (error != null) debugPrint('Error detail: $error');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }

  static void network(String message) {
    if (!isEnabled || !showNetworkLogs) return;
    debugPrint('[NETWORK] $message');
  }
}
