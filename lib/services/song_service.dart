import 'package:flutter/material.dart';
import '../models/song.dart';

class SongService {
  static final SongService instance = SongService._internal();
  SongService._internal();

  /// Reactive list of available song fields/attributes
  final ValueNotifier<List<SongFieldDefinition>> fieldsNotifier =
      ValueNotifier<List<SongFieldDefinition>>([
    const SongFieldDefinition(
      id: 'author',
      name: 'Author / Artist',
      isSystem: true,
      isVisible: true,
      placeholder: 'e.g. David Bowie',
    ),
    const SongFieldDefinition(
      id: 'key',
      name: 'Musical Key',
      isSystem: true,
      isVisible: true,
      placeholder: 'e.g. C, G, Em, F#m',
    ),
    const SongFieldDefinition(
      id: 'tempo',
      name: 'Tempo (BPM)',
      isSystem: true,
      isVisible: true,
      placeholder: 'e.g. 120',
    ),
    const SongFieldDefinition(
      id: 'time_sig',
      name: 'Time Signature',
      isSystem: false,
      isVisible: true,
      placeholder: 'e.g. 4/4, 3/4, 6/8',
    ),
    const SongFieldDefinition(
      id: 'capo',
      name: 'Capo Position',
      isSystem: false,
      isVisible: true,
      placeholder: 'e.g. 2nd Fret, None',
    ),
    const SongFieldDefinition(
      id: 'tuning',
      name: 'Instrument Tuning',
      isSystem: false,
      isVisible: true,
      placeholder: 'e.g. Standard E, Drop D, DADGAD',
    ),
    const SongFieldDefinition(
      id: 'notes',
      name: 'Stage Notes',
      isSystem: false,
      isVisible: true,
      placeholder: 'e.g. Synth intro, modulation on chorus',
    ),
  ]);

  /// Reactive list of songs
  final ValueNotifier<List<Song>> songsNotifier =
      ValueNotifier<List<Song>>([
    Song(
      id: '1',
      title: 'Starlight Orbit',
      artist: 'Orbit Collective',
      musicalKey: 'G Maj',
      tempo: 124,
      customFields: {
        'time_sig': '4/4',
        'capo': 'No Capo',
        'tuning': 'Standard E',
        'notes': 'Bass groove intro, key modulation on solo',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Song(
      id: '2',
      title: 'Echoes of Andromeda',
      artist: 'Lunar Collective',
      musicalKey: 'E Min',
      tempo: 96,
      customFields: {
        'time_sig': '6/8',
        'capo': '2nd Fret',
        'tuning': 'Drop D',
        'notes': 'Ambient reverb, dynamic swells on second verse',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Song(
      id: '3',
      title: 'Velocity Vector',
      artist: 'Solar Flare',
      musicalKey: 'D Maj',
      tempo: 140,
      customFields: {
        'time_sig': '4/4',
        'capo': 'No Capo',
        'tuning': 'Standard E',
        'notes': 'High energy breakdown at minute 3',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ]);

  /// Add a new song
  void addSong(Song song) {
    songsNotifier.value = [song, ...songsNotifier.value];
  }

  /// Update an existing song
  void updateSong(Song updated) {
    songsNotifier.value = songsNotifier.value.map((s) {
      return s.id == updated.id ? updated : s;
    }).toList();
  }

  /// Delete a song
  void deleteSong(String id) {
    songsNotifier.value = songsNotifier.value.where((s) => s.id != id).toList();
  }

  /// Add a new custom field definition
  void addField(String name, {String placeholder = ''}) {
    final cleanId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newField = SongFieldDefinition(
      id: cleanId,
      name: name,
      isSystem: false,
      isVisible: true,
      placeholder: placeholder,
    );
    fieldsNotifier.value = [...fieldsNotifier.value, newField];
  }

  /// Toggle visibility (show/hide) of any field
  void toggleFieldVisibility(String id) {
    fieldsNotifier.value = fieldsNotifier.value.map((field) {
      if (field.id == id) {
        return field.copyWith(isVisible: !field.isVisible);
      }
      return field;
    }).toList();
  }

  /// Remove a user-defined field
  void deleteField(String id) {
    fieldsNotifier.value = fieldsNotifier.value.where((f) => f.id != id).toList();
  }
}
