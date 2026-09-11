/// Configuration option for what to show and hide in setlists and stage view
class SetlistOptionDefinition {
  final String id;
  final String name;
  final String description;
  final bool isVisible;
  final String category; // 'metadata' or 'stage'

  const SetlistOptionDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.isVisible = true,
    this.category = 'metadata',
  });

  SetlistOptionDefinition copyWith({
    String? id,
    String? name,
    String? description,
    bool? isVisible,
    String? category,
  }) {
    return SetlistOptionDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isVisible: isVisible ?? this.isVisible,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'isVisible': isVisible,
    'category': category,
  };

  factory SetlistOptionDefinition.fromJson(Map<String, dynamic> json) =>
      SetlistOptionDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        isVisible: json['isVisible'] as bool? ?? true,
        category: json['category'] as String? ?? 'metadata',
      );
}

/// Representation of a live performance setlist
class Setlist {
  final String id;
  final String title;
  final DateTime date;
  final String? location;
  final List<String> songIds;
  final bool isCompleted;
  final DateTime createdAt;

  const Setlist({
    required this.id,
    required this.title,
    required this.date,
    this.location,
    this.songIds = const [],
    this.isCompleted = false,
    required this.createdAt,
  });

  Setlist copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? location,
    List<String>? songIds,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Setlist(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      location: location ?? this.location,
      songIds: songIds ?? this.songIds,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'location': location,
    'songIds': songIds,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Setlist.fromJson(Map<String, dynamic> json) => Setlist(
    id: json['id'] as String,
    title: json['title'] as String,
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    location: json['location'] as String?,
    songIds: (json['songIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    isCompleted: json['isCompleted'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
  );
}
