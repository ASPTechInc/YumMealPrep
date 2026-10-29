import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'package:yummealprep/services/image_store_io.dart'
    if (dart.library.js_interop) 'package:yummealprep/services/image_store_web.dart'
    as platform;

/// Saves the pictures people add to meals and recipes, and turns any image
/// source the app stores into something it can display or print.
///
/// An image source is one of:
/// - a bundled asset path, such as `assets/images/meals/lunch_lasagne.png`
/// - `local:images/<file>`, a picture saved in the app's own storage
/// - a `data:` URI, used where there is no file system (the web build)
///
/// Remote URLs are not supported on purpose: the app works offline and
/// does not contact any server.
abstract class ImageStore {
  /// Opens the store used on this platform.
  static Future<ImageStore> open() => platform.openImageStore();

  /// Saves [bytes] and returns the source to store with the item.
  Future<String> save(Uint8List bytes, {String extension = 'jpg'});

  /// Whether [source] is a picture this store saved, as opposed to a
  /// bundled asset.
  bool owns(String source);

  /// Deletes a picture this store saved. Other sources are ignored.
  Future<void> delete(String source);

  /// An image provider for a picture this store saved, or `null`.
  ImageProvider? providerFor(String source);

  /// The bytes of a picture this store saved, or `null`.
  Future<Uint8List?> readBytes(String source);

  // Inline pictures, decoded once. MemoryImage compares its bytes by
  // identity, so a new provider each build would never hit the image cache.
  final Map<String, MemoryImage> _inline = {};
  static const int _maxInline = 64;

  /// An image provider for any image source, or `null` if [source] is empty
  /// or cannot be shown.
  ImageProvider? resolve(String? source) {
    if (source == null || source.isEmpty) return null;
    if (isAsset(source)) return AssetImage(source);
    if (source.startsWith('data:')) {
      final cached = _inline.remove(source);
      final provider = cached ?? _decodeInline(source);
      if (provider == null) return null;
      _inline[source] = provider; // most recently used last
      if (_inline.length > _maxInline) _inline.remove(_inline.keys.first);
      return provider;
    }
    return providerFor(source);
  }

  MemoryImage? _decodeInline(String source) {
    final bytes = decodeDataUri(source);
    return bytes == null ? null : MemoryImage(bytes);
  }

  /// The bytes of any image source, for printing and backups.
  Future<Uint8List?> load(String? source, {AssetBundle? bundle}) async {
    if (source == null || source.isEmpty) return null;
    if (isAsset(source)) {
      try {
        final data = await (bundle ?? rootBundle).load(source);
        return data.buffer.asUint8List();
      } on FlutterError {
        return null;
      }
    }
    if (source.startsWith('data:')) return decodeDataUri(source);
    return readBytes(source);
  }

  static bool isAsset(String source) => source.startsWith('assets/');

  static Uint8List? decodeDataUri(String source) {
    try {
      return UriData.parse(source).contentAsBytes();
    } on FormatException {
      return null;
    }
  }
}

/// Keeps pictures inline as `data:` URIs inside the records themselves.
///
/// Used by the web build, which has no file system, and by tests.
class DataUriImageStore extends ImageStore {
  @override
  Future<String> save(Uint8List bytes, {String extension = 'jpg'}) async {
    final mimeType = switch (extension.toLowerCase()) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  @override
  bool owns(String source) => false;

  @override
  Future<void> delete(String source) async {}

  @override
  ImageProvider? providerFor(String source) => null;

  @override
  Future<Uint8List?> readBytes(String source) async => null;
}
