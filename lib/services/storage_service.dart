import 'dart:convert';
import 'dart:typed_data';

/// Manages local application-owned storage for user images and profile media.
/// Creates isolated, detached copies of uploaded files so the app never relies
/// on external file paths on the user's host machine.
class AppStorageService {
  static final AppStorageService instance = AppStorageService._internal();
  AppStorageService._internal();

  /// In-memory application file copy cache: key -> binary bytes
  final Map<String, Uint8List> _copiedFiles = {};
  final Map<String, String> _dataUriFallback = {};

  /// Stores an isolated copy of user-provided image bytes in application storage.
  /// Returns a clean application storage URI (`app_storage://<id>`).
  String storeCopiedFile({
    required String originalName,
    required Uint8List bytes,
    String? extension,
  }) {
    // 1. Create a 100% independent deep copy of the raw bytes
    final detachedCopy = Uint8List.fromList(bytes);

    // 2. Generate a sanitized file identifier
    final ext = (extension ?? originalName.split('.').last).toLowerCase();
    final cleanExt = ext.isNotEmpty ? ext : 'png';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedBase = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final storageKey = 'app_storage://${timestamp}_$sanitizedBase.$cleanExt';

    // 3. Register in application storage
    _copiedFiles[storageKey] = detachedCopy;

    // 4. Store fallback data URI
    final mime = cleanExt == 'jpg' || cleanExt == 'jpeg'
        ? 'image/jpeg'
        : cleanExt == 'webp'
            ? 'image/webp'
            : cleanExt == 'gif'
                ? 'image/gif'
                : 'image/png';
    final base64String = base64Encode(detachedCopy);
    _dataUriFallback[storageKey] = 'data:$mime;base64,$base64String';

    return storageKey;
  }

  /// Retrieves raw copied image bytes from application storage
  Uint8List? getImageBytes(String storageKey) {
    if (_copiedFiles.containsKey(storageKey)) {
      return _copiedFiles[storageKey];
    }
    if (_dataUriFallback.containsKey(storageKey)) {
      final uri = _dataUriFallback[storageKey]!;
      final comma = uri.indexOf(',');
      if (comma != -1) {
        final decoded = base64Decode(uri.substring(comma + 1));
        _copiedFiles[storageKey] = decoded;
        return decoded;
      }
    }
    return null;
  }

  /// Check if image is stored in application storage
  bool hasImage(String storageKey) {
    return _copiedFiles.containsKey(storageKey) || _dataUriFallback.containsKey(storageKey);
  }

  /// Remove an image from application storage
  void removeImage(String storageKey) {
    _copiedFiles.remove(storageKey);
    _dataUriFallback.remove(storageKey);
  }

  /// Helper to get user-friendly display name of an application storage item
  String getDisplayName(String storageKey) {
    if (storageKey.startsWith('app_storage://')) {
      final raw = storageKey.substring('app_storage://'.length);
      final underscoreIndex = raw.indexOf('_');
      if (underscoreIndex != -1 && underscoreIndex + 1 < raw.length) {
        return raw.substring(underscoreIndex + 1);
      }
      return raw;
    }
    if (storageKey.startsWith('assets/images/presets/')) {
      return storageKey.split('/').last;
    }
    return storageKey;
  }
}
