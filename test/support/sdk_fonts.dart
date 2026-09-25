import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the Roboto and Material Icons fonts bundled with the Flutter SDK.
///
/// Widget tests otherwise render text in a test font whose glyphs are all
/// one em wide, far wider than real text. Layout checks that judge whether
/// labels fit use real metrics instead.
Future<void> loadSdkFonts() async {
  // flutter_tester lives under <flutter>/bin/cache/artifacts/engine/...
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.path != directory.parent.path &&
      !Directory('${directory.path}/artifacts/material_fonts').existsSync()) {
    directory = directory.parent;
  }
  final fonts = '${directory.path}/artifacts/material_fonts';
  Future<ByteData> read(String file) async =>
      ByteData.sublistView(await File('$fonts/$file').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final file in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]) {
    roboto.addFont(read(file));
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('materialicons-regular.otf'))).load();
}
