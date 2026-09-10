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
}
