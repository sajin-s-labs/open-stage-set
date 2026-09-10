import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Returns an ImageProvider capable of loading:
/// 1. Local App Assets (e.g. 'assets/images/presets/avatar_mono_1.jpg')
/// 2. Application Storage Copies (e.g. 'app_storage://...')
/// 3. Inlined Data URIs ('data:image/...;base64,...')
/// 4. Remote URLs ('https://...')
ImageProvider? getAppImageProvider(String? pathOrUri) {
  if (pathOrUri == null || pathOrUri.trim().isEmpty) return null;
  final trimmed = pathOrUri.trim();

  // 1. Local App Asset
  if (trimmed.startsWith('assets/')) {
    return AssetImage(trimmed);
  }

  // 2. Application Storage Copy
  if (trimmed.startsWith('app_storage://')) {
    final bytes = AppStorageService.instance.getImageBytes(trimmed);
    if (bytes != null) {
      return MemoryImage(bytes);
    }
  }

  // 3. Base64 Data URI
  if (trimmed.startsWith('data:image')) {
    final commaIndex = trimmed.indexOf(',');
    if (commaIndex != -1) {
      try {
        final base64Data = trimmed.substring(commaIndex + 1);
        return MemoryImage(base64Decode(base64Data));
      } catch (e) {
        return null;
      }
    }
  }

  // 4. Remote URL
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return NetworkImage(trimmed);
  }

  return null;
}
