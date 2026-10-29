import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves screenshots taken by integration_test/screenshots_test.dart as the
/// store screenshots.
///
/// They are saved as high-quality JPEG: the screens are full of food
/// photos, which PNG stores at 1-2 MB each and a 256-colour PNG shows with
/// visible banding. At quality 90 each is a few hundred kilobytes, well
/// under the repository's 600 KB limit for added files.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final screenshot = img.decodePng(Uint8List.fromList(bytes))!;
    final file = File(
      'fastlane/metadata/android/en-GB/images/phoneScreenshots/$name.jpg',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(img.encodeJpg(screenshot, quality: 90));
    return true;
  },
);
