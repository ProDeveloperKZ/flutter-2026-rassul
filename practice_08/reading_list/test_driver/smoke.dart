import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  final adb =
      '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools/adb';
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

  Future<void> enter(String key, String value) async {
    await driver.tap(find.byValueKey(key));
    await driver.enterText(value);
  }

  try {
    await driver.tap(find.byValueKey('filter-unread'));
    await driver.waitFor(find.text('Reading list (4)'));
    await driver.scrollIntoView(
      find.text(
        'A Very Long Title About Forms, Focus, the Keyboard and Everything That Overflows',
      ),
    );
    await screenshot('screenshot_list.png');
    await driver.tap(find.byType('FloatingActionButton'));
    await driver.tap(find.text('Save'));
    await driver.waitFor(find.text('A whole number above 0'));
    await screenshot('screenshot_form.png');
    await enter('title', 'Dart in practice');
    await enter('author', 'Student');
    await enter('pages', '120');
    await driver.tap(find.text('Save'));
    await driver.waitFor(find.text('Reading list (5)'));
    await driver.scrollUntilVisible(
      find.byType('ListView'),
      find.text('Dart in practice'),
      dyScroll: -250,
    );
    await driver.tap(find.text('Dart in practice'));
    await driver.waitFor(find.text('Year unknown'));
    await driver.tap(find.text('Mark as read'));
    await driver.waitFor(find.text('Reading list (4)'));
  } finally {
    await driver.close();
  }
}
