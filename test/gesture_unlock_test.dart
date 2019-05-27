import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gesture_unlock/gesture_unlock.dart';

void main() {
  const MethodChannel channel = MethodChannel('gesture_unlock');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await GestureUnlock.platformVersion, '42');
  });
}
