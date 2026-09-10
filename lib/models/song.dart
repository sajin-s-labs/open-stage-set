/// Definition of a song field/attribute (default or user-defined)
class SongFieldDefinition {
  final String id;
  final String name;
  final bool isSystem;
  final bool isVisible;
  final String placeholder;

  const SongFieldDefinition({
    required this.id,
    required this.name,
    this.isSystem = false,
    this.isVisible = true,
    this.placeholder = '',
  });

  SongFieldDefinition copyWith({
    String? id,
    String? name,
    bool? isSystem,
    bool? isVisible,
    String? placeholder,
  }) {
    return SongFieldDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      isSystem: isSystem ?? this.isSystem,
      isVisible: isVisible ?? this.isVisible,
      placeholder: placeholder ?? this.placeholder,
    );
  }
}

/// Representation of a song with core and user-defined metadata
class Song {
  final String id;
  final String title;
  final String? artist;
  final String? musicalKey;
  final int? tempo;
  final Map<String, String> customFields;
  final DateTime createdAt;

  const Song({
    required this.id,
    required this.title,
    this.artist,
    this.musicalKey,
    this.tempo,
    this.customFields = const {},
    required this.createdAt,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? musicalKey,
    int? tempo,
    Map<String, String>? customFields,
    DateTime? createdAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      musicalKey: musicalKey ?? this.musicalKey,
      tempo: tempo ?? this.tempo,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
