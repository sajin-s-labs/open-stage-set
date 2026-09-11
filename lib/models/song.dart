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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isSystem': isSystem,
    'isVisible': isVisible,
    'placeholder': placeholder,
  };

  factory SongFieldDefinition.fromJson(Map<String, dynamic> json) => SongFieldDefinition(
    id: json['id'] as String,
    name: json['name'] as String,
    isSystem: json['isSystem'] as bool? ?? false,
    isVisible: json['isVisible'] as bool? ?? true,
    placeholder: json['placeholder'] as String? ?? '',
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'musicalKey': musicalKey,
    'tempo': tempo,
    'customFields': customFields,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String?,
    musicalKey: json['musicalKey'] as String?,
    tempo: json['tempo'] as int?,
    customFields: (json['customFields'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ) ??
        const {},
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}
