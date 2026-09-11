import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileService {
  static final ProfileService instance = ProfileService._internal();
  ProfileService._internal();

  static const String _prefProfileKey = 'open_stage_set_user_profile';

  static const UserProfile defaultProfile = UserProfile(
    name: 'Stage Performer',
    bandName: 'Live Ensemble',
    instruments: ['Lead Guitar', 'Vocals', 'Synthesizer'],
    avatarUrl: 'assets/images/presets/avatar_mono_1.jpg',
    backgroundUrl: 'assets/images/presets/bg_mono_1.jpg',
    dynamicThemeImages: false,
    darkAvatarUrl: 'assets/images/presets/avatar_mono_1.jpg',
    grayscaleAvatarUrl: 'assets/images/presets/avatar_mono_2.jpg',
    lightAvatarUrl: 'assets/images/presets/avatar_color_1.jpg',
    darkBackgroundUrl: 'assets/images/presets/bg_mono_1.jpg',
    grayscaleBackgroundUrl: 'assets/images/presets/bg_mono_2.jpg',
    lightBackgroundUrl: 'assets/images/presets/bg_color_1.jpg',
  );

  /// Reactive user profile
  final ValueNotifier<UserProfile> profileNotifier =
      ValueNotifier<UserProfile>(defaultProfile);

  /// Initialize and load saved profile
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefProfileKey);
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        profileNotifier.value = UserProfile.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  /// Update user profile and persist
  void updateProfile(UserProfile newProfile) {
    profileNotifier.value = newProfile;
    _saveProfile(newProfile);
  }

  Future<void> _saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefProfileKey, json.encode(profile.toJson()));
    } catch (e) {
      debugPrint('Failed to save profile: $e');
    }
  }
}
