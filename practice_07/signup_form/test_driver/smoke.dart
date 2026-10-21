import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  final adb =
      '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools/adb';
  Future<ProcessResult> android(List<String> args) =>
      Process.run(adb, ['-s', 'emulator-5554', ...args]);
  Future<void> screenshot(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final result = await Process.run(adb, [
      '-s',
      'emulator-5554',
      'exec-out',
      'screencap',
      '-p',
    ], stdoutEncoding: null);
    if (result.exitCode != 0) {
      throw StateError('Screenshot failed: ${result.stderr}');
    }
    await File(name).writeAsBytes(result.stdout as List<int>);
  }

  Future<void> tap(String key) async {
    final target = find.byValueKey(key);
    await driver.scrollIntoView(target);
    await driver.tap(target);
  }

  Future<void> enter(String key, String value) async {
    await tap(key);
    await driver.enterText(value);
  }

  final oldIme = (await android([
    'shell',
    'settings',
    'get',
    'secure',
    'show_ime_with_hard_keyboard',
  ])).stdout.toString().trim();
  try {
    await enter('name', 'Rassul');
    await enter('email', 'rassul@kbtu.kz');
    await enter('password', 'password123');
    await enter('confirm', 'password123');
    await tap('group');
    await driver.tap(find.text('IT-2301'));
    await tap('birth');
    await driver.tap(find.text('OK'));
    await tap('agreed');
    await android([
      'shell',
      'settings',
      'put',
      'secure',
      'show_ime_with_hard_keyboard',
      '1',
    ]);
    await driver.setTextEntryEmulation(enabled: false);
    await tap('confirm');
    await Future<void>.delayed(const Duration(seconds: 1));
    await driver.scrollIntoView(find.byValueKey('confirm'));
    await screenshot('keyboard_open.png');
    await android(['shell', 'input', 'keyevent', '4']);
    await driver.setTextEntryEmulation(enabled: true);
    await tap('submit');
    await driver.waitFor(find.text('Account created'));
    await android(['shell', 'wm', 'size', '1600x2400']);
    await android(['shell', 'wm', 'density', '240']);
    await Future<void>.delayed(const Duration(seconds: 2));
    await screenshot('tablet.png');
    await driver.tap(find.text('Start over'));
    await driver.waitFor(find.byValueKey('name'));
  } finally {
    await android(['shell', 'wm', 'size', 'reset']);
    await android(['shell', 'wm', 'density', 'reset']);
    if (oldIme == 'null') {
      await android([
        'shell',
        'settings',
        'delete',
        'secure',
        'show_ime_with_hard_keyboard',
      ]);
    } else {
      await android([
        'shell',
        'settings',
        'put',
        'secure',
        'show_ime_with_hard_keyboard',
        oldIme,
      ]);
    }
    await driver.close();
  }
}
