import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages local application-owned storage for user images and profile media.
/// Creates isolated, detached copies of uploaded files so the app never relies
/// on external file paths on the user's host machine, persisting across app restarts.
class AppStorageService {
  static final AppStorageService instance = AppStorageService._internal();
  AppStorageService._internal();

  static const String _prefStorageFilesKey = 'open_stage_set_storage_files_v1';

  /// In-memory application file copy cache: key -> binary bytes
  final Map<String, Uint8List> _copiedFiles = {};
  final Map<String, String> _dataUriFallback = {};

  /// Initialize and load stored files from persistent preferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefStorageFilesKey);
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final uri = entry.value.toString();
          _dataUriFallback[entry.key] = uri;
          final comma = uri.indexOf(',');
          if (comma != -1) {
            try {
              _copiedFiles[entry.key] = base64Decode(uri.substring(comma + 1));
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load application storage files: $e');
    }
  }

  Future<void> _persistFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefStorageFilesKey, json.encode(_dataUriFallback));
    } catch (e) {
      debugPrint('Failed to persist application storage files: $e');
    }
  }

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

    _persistFiles();

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
    _persistFiles();
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
