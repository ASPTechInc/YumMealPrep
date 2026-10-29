import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:yummealprep/services/image_store.dart';

Future<ImageStore> openImageStore() async {
  final supportDirectory = await getApplicationSupportDirectory();
  return FileImageStore(supportDirectory);
}

/// Saves pictures as files in the app's private support directory.
///
/// Sources are stored relative to that directory (`local:images/<file>`)
/// because the absolute path can change, for example when iOS moves the
/// app's container during an update.
///
/// Each file is named after a hash of its contents, so the same picture is
/// only ever stored once. Importing the same `.backup` twice, or using one
/// photo for two meals, reuses the existing file.
class FileImageStore extends ImageStore {
  FileImageStore(this.rootDirectory);

  static const String _prefix = 'local:';
  static const String _folder = 'images';

  final Directory rootDirectory;

  @override
  Future<String> save(Uint8List bytes, {String extension = 'jpg'}) async {
    final directory = Directory(p.join(rootDirectory.path, _folder));
    await directory.create(recursive: true);
    final safeExtension = extension.toLowerCase().replaceAll(
      RegExp('[^a-z0-9]'),
      '',
    );
    final hash = sha256.convert(bytes).toString().substring(0, 32);
    final relativePath = p.posix.join(
      _folder,
      '$hash.${safeExtension.isEmpty ? 'jpg' : safeExtension}',
    );
    final file = File(_absolutePath(relativePath));
    if (!file.existsSync() || file.lengthSync() != bytes.length) {
      // Write to a temporary file first, so a crash never leaves a
      // half-written picture under the final name.
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
    }
    return '$_prefix$relativePath';
  }

  @override
  bool owns(String source) => source.startsWith(_prefix);

  @override
  Future<void> delete(String source) async {
    final file = _fileFor(source);
    if (file != null && file.existsSync()) await file.delete();
  }

  @override
  ImageProvider? providerFor(String source) {
    final file = _fileFor(source);
    return file == null ? null : FileImage(file);
  }

  @override
  Future<Uint8List?> readBytes(String source) async {
    final file = _fileFor(source);
    if (file == null || !file.existsSync()) return null;
    return file.readAsBytes();
  }

  File? _fileFor(String source) {
    if (!owns(source)) return null;
    final relativePath = source.substring(_prefix.length);
    // Refuse anything that would escape the images folder, such as a
    // crafted backup containing "local:../../somewhere".
    final normalised = p.posix.normalize(relativePath);
    if (!p.posix.isWithin(_folder, normalised)) return null;
    return File(_absolutePath(normalised));
  }

  String _absolutePath(String relativePath) =>
      p.joinAll([rootDirectory.path, ...p.posix.split(relativePath)]);
}
