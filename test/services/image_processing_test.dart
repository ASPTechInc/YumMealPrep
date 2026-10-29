import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:yummealprep/services/image_processing.dart';

void main() {
  test('shrinks large photos to the maximum size as JPEG', () async {
    final photo = img.Image(width: 4000, height: 3000);
    final prepared = await prepareImage(img.encodePng(photo), extension: 'png');

    expect(prepared.extension, 'jpg');
    final result = img.decodeJpg(prepared.bytes)!;
    expect(result.width, maxImageSide);
    expect(result.height, 1200);
  });

  test('keeps small photos at their size', () async {
    final prepared = await prepareImage(
      img.encodeJpg(img.Image(width: 800, height: 600)),
      extension: 'jpg',
    );
    final result = img.decodeJpg(prepared.bytes)!;
    expect((result.width, result.height), (800, 600));
  });

  test('removes metadata such as the camera and location', () async {
    final photo = img.Image(width: 400, height: 300);
    photo.exif.imageIfd['Make'] = 'SecretCam';
    final original = img.encodeJpg(photo);
    expect(latin1.decode(original), contains('SecretCam'));

    final prepared = await prepareImage(original, extension: 'jpg');
    expect(latin1.decode(prepared.bytes), isNot(contains('SecretCam')));
  });

  test('keeps files it cannot read as they are', () async {
    final bytes = utf8.encode('not an image');
    final prepared = await prepareImage(bytes, extension: 'heic');
    expect(prepared.bytes, bytes);
    expect(prepared.extension, 'heic');
  });
}
