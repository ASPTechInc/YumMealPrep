import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// A picture ready to be stored.
typedef PreparedImage = ({Uint8List bytes, String extension});

/// The longest side, in pixels, of a picture added in the app. Large enough
/// for the full-width header on a high-resolution phone.
const int maxImageSide = 1600;

const int _jpegQuality = 85;

/// Shrinks a picked photo to at most [maxImageSide] pixels on its longest
/// side and re-encodes it as JPEG.
///
/// This keeps the app's storage and exported `.backup` files small (a
/// 12-megapixel phone photo goes from several megabytes to a few hundred
/// kilobytes), turns the photo the right way up, and drops its EXIF
/// metadata, such as the location it was taken. Runs in a background
/// isolate so the app stays responsive.
///
/// Formats the app cannot decode (such as HEIC) are kept as they are.
Future<PreparedImage> prepareImage(
  Uint8List bytes, {
  required String extension,
}) => compute(_prepare, (bytes: bytes, extension: extension));

PreparedImage _prepare(PreparedImage original) {
  final decoded = img.decodeImage(original.bytes);
  if (decoded == null) return original;

  // Turn the photo the right way up, then drop its EXIF metadata (camera,
  // date and possibly the location it was taken). The JPEG encoder would
  // otherwise copy it into the saved file.
  var image = img.bakeOrientation(decoded)..exif = img.ExifData();
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > maxImageSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: maxImageSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: maxImageSide,
            interpolation: img.Interpolation.average,
          );
  }
  // Photos have no transparency to keep, so JPEG suits them best.
  return (bytes: img.encodeJpg(image, quality: _jpegQuality), extension: 'jpg');
}
