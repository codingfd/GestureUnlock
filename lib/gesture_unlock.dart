import 'dart:async';

import 'package:flutter/services.dart';

class GestureUnlock {
  static const MethodChannel _channel =
      const MethodChannel('gesture_unlock');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');

    return version;
  }
}
