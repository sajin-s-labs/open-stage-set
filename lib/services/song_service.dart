import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'setlist_service.dart';

class SongService {
  static final SongService instance = SongService._internal();
  SongService._internal();

  static const String _prefSongsKey = 'open_stage_set_songs_list';
  static const String _prefFieldsKey = 'open_stage_set_song_fields';

  static const List<SongFieldDefinition> defaultFields = [
    SongFieldDefinition(
      id: 'author',
      name: 'Author / Artist',
      isSystem: true,
      isVisible: true,
      placeholder: 'e.g. David Bowie',
    ),
    SongFieldDefinition(
      id: 'key',
      name: 'Musical Key',
      isSystem: true,
      isVisible: true,
      placeholder: 'e.g. C, G, Em, F#m',
    ),
    SongFieldDefinition(
      id: 'tempo',
      name: 'Tempo (BPM)',
      isSystem: true,
      isVisible: true,
      placeholder: 'e.g. 120',
    ),
    SongFieldDefinition(
      id: 'time_sig',
      name: 'Time Signature',
      isSystem: false,
      isVisible: true,
      placeholder: 'e.g. 4/4, 3/4, 6/8',
    ),
    SongFieldDefinition(
      id: 'capo',
      name: 'Capo Position',
      isSystem: false,
      isVisible: true,
      placeholder: 'e.g. 2nd Fret, None',
    ),
    SongFieldDefinition(
      id: 'tuning',
      name: 'Instrument Tuning',
      isSystem: false,
      isVisible: true,
      placeholder: 'e.g. Standard E, Drop D, DADGAD',
    ),
    SongFieldDefinition(
      id: 'notes',
      name: 'Stage Notes',
      isSystem: false,
      isVisible: true,
      placeholder: 'e.g. Synth intro, modulation on chorus',
    ),
  ];

  static List<Song> get defaultSongs => [
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
  ];

  /// Reactive list of available song fields/attributes
  final ValueNotifier<List<SongFieldDefinition>> fieldsNotifier =
      ValueNotifier<List<SongFieldDefinition>>(List.from(defaultFields));

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

  /// Initialize and load saved songs and fields
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load songs
      final songsJson = prefs.getString(_prefSongsKey);
      if (songsJson != null) {
        final List<dynamic> list = json.decode(songsJson);
        songsNotifier.value =
            list.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        songsNotifier.value = List.from(defaultSongs);
        await _saveSongs();
      }

      // Load fields
      final fieldsJson = prefs.getString(_prefFieldsKey);
      if (fieldsJson != null) {
        final List<dynamic> list = json.decode(fieldsJson);
        fieldsNotifier.value = list
            .map((e) => SongFieldDefinition.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        fieldsNotifier.value = List.from(defaultFields);
        await _saveFields();
      }
    } catch (e) {
      debugPrint('Failed to load songs from preferences: $e');
    }
  }

  Future<void> _saveSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = songsNotifier.value.map((s) => s.toJson()).toList();
      await prefs.setString(_prefSongsKey, json.encode(list));
    } catch (e) {
      debugPrint('Failed to save songs: $e');
    }
  }

  Future<void> _saveFields() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = fieldsNotifier.value.map((f) => f.toJson()).toList();
      await prefs.setString(_prefFieldsKey, json.encode(list));
    } catch (e) {
      debugPrint('Failed to save fields: $e');
    }
  }

  /// Add a new song
  Future<void> addSong(Song song) async {
    songsNotifier.value = [song, ...songsNotifier.value];
    await _saveSongs();
  }

  /// Update an existing song
  Future<void> updateSong(Song updated) async {
    songsNotifier.value = songsNotifier.value.map((s) {
      return s.id == updated.id ? updated : s;
    }).toList();
    await _saveSongs();
  }

  /// Delete a song and remove it from all setlists
  Future<void> deleteSong(String id) async {
    songsNotifier.value = songsNotifier.value.where((s) => s.id != id).toList();
    await _saveSongs();
    await SetlistService.instance.removeSongFromAllSetlists(id);
  }

  /// Add a new custom field definition
  Future<void> addField(String name, {String placeholder = ''}) async {
    final cleanId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newField = SongFieldDefinition(
      id: cleanId,
      name: name,
      isSystem: false,
      isVisible: true,
      placeholder: placeholder,
    );
    fieldsNotifier.value = [...fieldsNotifier.value, newField];
    await _saveFields();
  }

  /// Toggle visibility (show/hide) of any field
  Future<void> toggleFieldVisibility(String id) async {
    fieldsNotifier.value = fieldsNotifier.value.map((field) {
      if (field.id == id) {
        return field.copyWith(isVisible: !field.isVisible);
      }
      return field;
    }).toList();
    await _saveFields();
  }

  /// Remove a user-defined field
  Future<void> deleteField(String id) async {
    fieldsNotifier.value = fieldsNotifier.value.where((f) => f.id != id).toList();
    await _saveFields();
  }
}
