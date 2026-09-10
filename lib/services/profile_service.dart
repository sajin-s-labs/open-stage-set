import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileService {
  static final ProfileService instance = ProfileService._internal();
  ProfileService._internal();

  /// Reactive user profile
  final ValueNotifier<UserProfile> profileNotifier = ValueNotifier<UserProfile>(
    const UserProfile(
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
    ),
  );

  /// Update user profile
  void updateProfile(UserProfile newProfile) {
    profileNotifier.value = newProfile;
  }
}
