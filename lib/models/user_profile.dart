import '../theme/app_theme.dart';

/// Musician Profile model
class UserProfile {
  final String name;
  final String bandName;
  final List<String> instruments;
  final String? avatarUrl;
  final String? backgroundUrl;

  // Theme-adaptive image settings
  final bool dynamicThemeImages;
  final String? darkAvatarUrl;
  final String? grayscaleAvatarUrl;
  final String? lightAvatarUrl;
  final String? darkBackgroundUrl;
  final String? grayscaleBackgroundUrl;
  final String? lightBackgroundUrl;

  const UserProfile({
    required this.name,
    required this.bandName,
    this.instruments = const [],
    this.avatarUrl,
    this.backgroundUrl,
    this.dynamicThemeImages = false,
    this.darkAvatarUrl,
    this.grayscaleAvatarUrl,
    this.lightAvatarUrl,
    this.darkBackgroundUrl,
    this.grayscaleBackgroundUrl,
    this.lightBackgroundUrl,
  });

  /// Returns the effective avatar URL based on active theme
  String? getEffectiveAvatarUrl(AppThemeMode mode) {
    if (dynamicThemeImages) {
      switch (mode) {
        case AppThemeMode.oledDark:
          return darkAvatarUrl ?? avatarUrl;
        case AppThemeMode.grayscale:
          return grayscaleAvatarUrl ?? darkAvatarUrl ?? avatarUrl;
        case AppThemeMode.light:
          return lightAvatarUrl ?? avatarUrl;
      }
    }
    return avatarUrl;
  }

  /// Returns the effective background banner URL based on active theme
  String? getEffectiveBackgroundUrl(AppThemeMode mode) {
    if (dynamicThemeImages) {
      switch (mode) {
        case AppThemeMode.oledDark:
          return darkBackgroundUrl ?? backgroundUrl;
        case AppThemeMode.grayscale:
          return grayscaleBackgroundUrl ?? darkBackgroundUrl ?? backgroundUrl;
        case AppThemeMode.light:
          return lightBackgroundUrl ?? backgroundUrl;
      }
    }
    return backgroundUrl;
  }

  UserProfile copyWith({
    String? name,
    String? bandName,
    List<String>? instruments,
    String? avatarUrl,
    String? backgroundUrl,
    bool? dynamicThemeImages,
    String? darkAvatarUrl,
    String? grayscaleAvatarUrl,
    String? lightAvatarUrl,
    String? darkBackgroundUrl,
    String? grayscaleBackgroundUrl,
    String? lightBackgroundUrl,
  }) {
    return UserProfile(
      name: name ?? this.name,
      bandName: bandName ?? this.bandName,
      instruments: instruments ?? this.instruments,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      dynamicThemeImages: dynamicThemeImages ?? this.dynamicThemeImages,
      darkAvatarUrl: darkAvatarUrl ?? this.darkAvatarUrl,
      grayscaleAvatarUrl: grayscaleAvatarUrl ?? this.grayscaleAvatarUrl,
      lightAvatarUrl: lightAvatarUrl ?? this.lightAvatarUrl,
      darkBackgroundUrl: darkBackgroundUrl ?? this.darkBackgroundUrl,
      grayscaleBackgroundUrl: grayscaleBackgroundUrl ?? this.grayscaleBackgroundUrl,
      lightBackgroundUrl: lightBackgroundUrl ?? this.lightBackgroundUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'bandName': bandName,
    'instruments': instruments,
    'avatarUrl': avatarUrl,
    'backgroundUrl': backgroundUrl,
    'dynamicThemeImages': dynamicThemeImages,
    'darkAvatarUrl': darkAvatarUrl,
    'grayscaleAvatarUrl': grayscaleAvatarUrl,
    'lightAvatarUrl': lightAvatarUrl,
    'darkBackgroundUrl': darkBackgroundUrl,
    'grayscaleBackgroundUrl': grayscaleBackgroundUrl,
    'lightBackgroundUrl': lightBackgroundUrl,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? 'Stage Performer',
    bandName: json['bandName'] as String? ?? 'Live Ensemble',
    instruments: (json['instruments'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    avatarUrl: json['avatarUrl'] as String?,
    backgroundUrl: json['backgroundUrl'] as String?,
    dynamicThemeImages: json['dynamicThemeImages'] as bool? ?? false,
    darkAvatarUrl: json['darkAvatarUrl'] as String?,
    grayscaleAvatarUrl: json['grayscaleAvatarUrl'] as String?,
    lightAvatarUrl: json['lightAvatarUrl'] as String?,
    darkBackgroundUrl: json['darkBackgroundUrl'] as String?,
    grayscaleBackgroundUrl: json['grayscaleBackgroundUrl'] as String?,
    lightBackgroundUrl: json['lightBackgroundUrl'] as String?,
  );
}
