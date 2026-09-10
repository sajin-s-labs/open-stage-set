import 'package:flutter/material.dart';
import '../models/setlist.dart';

class SetlistService {
  static final SetlistService instance = SetlistService._internal();
  SetlistService._internal();

  /// Reactive list of display options (what to show and hide in setlists and stage view)
  final ValueNotifier<List<SetlistOptionDefinition>> optionsNotifier =
      ValueNotifier<List<SetlistOptionDefinition>>([
    const SetlistOptionDefinition(
      id: 'date',
      name: 'Event Date',
      description: 'Show performance date on setlist cards and header',
      isVisible: true,
      category: 'metadata',
    ),
    const SetlistOptionDefinition(
      id: 'location',
      name: 'Venue / Location',
      description: 'Show stage or venue location',
      isVisible: true,
      category: 'metadata',
    ),
    const SetlistOptionDefinition(
      id: 'song_key',
      name: 'Song Musical Key',
      description: 'Show key tags next to song titles in setlists',
      isVisible: true,
      category: 'metadata',
    ),
    const SetlistOptionDefinition(
      id: 'song_tempo',
      name: 'Song Tempo (BPM)',
      description: 'Display BPM tempo tags next to songs',
      isVisible: true,
      category: 'metadata',
    ),
    const SetlistOptionDefinition(
      id: 'song_artist',
      name: 'Song Author / Artist',
      description: 'Show author/artist beneath song titles in setlists',
      isVisible: true,
      category: 'metadata',
    ),
    const SetlistOptionDefinition(
      id: 'song_notes',
      name: 'Custom Fields & Stage Notes',
      description: 'Display capo, tuning, and stage notes chips in setlist songs',
      isVisible: true,
      category: 'metadata',
    ),
    const SetlistOptionDefinition(
      id: 'song_numbers',
      name: 'Track Sequence Numbers',
      description: 'Show #1, #2, #3 numbering on setlist items',
      isVisible: true,
      category: 'metadata',
    ),
    const SetlistOptionDefinition(
      id: 'stage_status_bar',
      name: 'Stage Top Status Bar',
      description: 'Show live track counter and playing status banner at top of stage',
      isVisible: true,
      category: 'stage',
    ),
    const SetlistOptionDefinition(
      id: 'stage_inactive_details',
      name: 'Inactive Track Details',
      description: 'Show BPM, artist & notes on non-playing songs (hide to collapse inactive songs to titles only)',
      isVisible: true,
      category: 'stage',
    ),
    const SetlistOptionDefinition(
      id: 'stage_dim_inactive',
      name: 'Dim Inactive Tracks',
      description: 'Dim non-playing songs to spotlight the active track with high contrast',
      isVisible: false,
      category: 'stage',
    ),
    const SetlistOptionDefinition(
      id: 'stage_large_font',
      name: 'Extra Large Stage Font',
      description: 'Enlarge song titles and keys for distant legibility on floor monitors and stands',
      isVisible: false,
      category: 'stage',
    ),
  ]);

  /// Reactive list of setlists
  final ValueNotifier<List<Setlist>> setlistsNotifier =
      ValueNotifier<List<Setlist>>([
    Setlist(
      id: 'setlist_1',
      title: 'Summer Stage Showcase',
      date: DateTime.now().add(const Duration(days: 3)),
      location: 'Skyline Amphitheater • Main Stage',
      songIds: ['1', '3', '2'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Setlist(
      id: 'setlist_2',
      title: 'Acoustic Rehearsal Session',
      date: DateTime.now().add(const Duration(days: 7)),
      location: 'Studio 4B',
      songIds: ['2', '1'],
      isCompleted: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Setlist(
      id: 'setlist_archive_1',
      title: 'Spring Showcase Live',
      date: DateTime.now().subtract(const Duration(days: 18)),
      location: 'Downtown Theater • Stage 1',
      songIds: ['3', '1'],
      isCompleted: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ]);

  /// Currently active setlist ID for live stage performance & dashboard card
  final ValueNotifier<String?> activeSetlistIdNotifier =
      ValueNotifier<String?>('setlist_1');

  /// Check if a performance date has passed (earlier than today)
  static bool isDatePast(DateTime date) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final setlistDay = DateTime(date.year, date.month, date.day);
    return setlistDay.isBefore(startOfToday);
  }

  /// Whether a setlist is archived (explicitly completed OR show date has passed)
  bool isArchived(Setlist setlist) {
    return setlist.isCompleted || isDatePast(setlist.date);
  }

  /// Whether a setlist is upcoming (not completed AND date is today or future)
  bool isUpcoming(Setlist setlist) {
    return !isArchived(setlist);
  }

  /// List of upcoming setlists sorted by nearest upcoming date first
  List<Setlist> get upcomingSetlists {
    final list = setlistsNotifier.value.where(isUpcoming).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// List of archived / past setlists sorted by most recent first
  List<Setlist> get archivedSetlists {
    final list = setlistsNotifier.value.where(isArchived).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Set the active setlist ID
  void setActiveSetlist(String? id) {
    activeSetlistIdNotifier.value = id;
  }

  /// Get the currently active setlist object (strictly from UPCOMING shows only)
  Setlist? get activeSetlist {
    final upcoming = upcomingSetlists;
    if (upcoming.isEmpty) return null;

    final activeId = activeSetlistIdNotifier.value;
    if (activeId != null) {
      for (final s in upcoming) {
        if (s.id == activeId) return s;
      }
    }
    // Default to nearest upcoming gig
    return upcoming.first;
  }

  /// Helper to check if a specific display option is visible
  bool isOptionVisible(String id) {
    final option = optionsNotifier.value.firstWhere(
      (opt) => opt.id == id,
      orElse: () => const SetlistOptionDefinition(id: '', name: '', description: '', isVisible: true),
    );
    return option.isVisible;
  }

  /// Toggle an option visibility (show/hide)
  void toggleOptionVisibility(String id) {
    optionsNotifier.value = optionsNotifier.value.map((opt) {
      if (opt.id == id) {
        return opt.copyWith(isVisible: !opt.isVisible);
      }
      return opt;
    }).toList();
  }

  /// Add a new setlist
  void addSetlist(Setlist setlist) {
    setlistsNotifier.value = [setlist, ...setlistsNotifier.value];
  }

  /// Update an existing setlist
  void updateSetlist(Setlist updated) {
    setlistsNotifier.value = setlistsNotifier.value.map((s) {
      return s.id == updated.id ? updated : s;
    }).toList();
  }

  /// Toggle or set a setlist as completed (archive) or active
  void markSetlistCompleted(String id, bool completed) {
    setlistsNotifier.value = setlistsNotifier.value.map((s) {
      if (s.id == id) {
        if (!completed && isDatePast(s.date)) {
          // If reopening a past show, refresh date to today so it is upcoming
          final now = DateTime.now();
          return s.copyWith(
            isCompleted: false,
            date: DateTime(now.year, now.month, now.day, s.date.hour, s.date.minute),
          );
        }
        return s.copyWith(isCompleted: completed);
      }
      return s;
    }).toList();

    // If active setlist was archived, update activeSetlistId to next upcoming
    if (completed && activeSetlistIdNotifier.value == id) {
      final upcoming = upcomingSetlists;
      activeSetlistIdNotifier.value = upcoming.isNotEmpty ? upcoming.first.id : null;
    }
  }

  /// Duplicate an existing setlist as a copy for a new gig
  Setlist duplicateSetlist(String id) {
    final existing = setlistsNotifier.value.firstWhere((s) => s.id == id);
    final cloned = Setlist(
      id: 'setlist_${DateTime.now().millisecondsSinceEpoch}',
      title: '${existing.title} (Copy)',
      date: DateTime.now().add(const Duration(days: 7)),
      location: existing.location,
      songIds: List<String>.from(existing.songIds),
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    addSetlist(cloned);
    return cloned;
  }

  /// Add a song directly to the currently active setlist
  bool addSongToActiveSetlist(String songId) {
    final active = activeSetlist;
    if (active == null) return false;
    if (active.songIds.contains(songId)) return false;
    final updated = active.copyWith(
      songIds: [...active.songIds, songId],
    );
    updateSetlist(updated);
    return true;
  }

  /// Delete a setlist
  void deleteSetlist(String id) {
    setlistsNotifier.value = setlistsNotifier.value.where((s) => s.id != id).toList();
    if (activeSetlistIdNotifier.value == id) {
      final upcoming = upcomingSetlists;
      activeSetlistIdNotifier.value = upcoming.isNotEmpty ? upcoming.first.id : null;
    }
  }

  /// Preset: Standard Stage (Show helpful metadata, standard font)
  void applyStandardPreset() {
    optionsNotifier.value = optionsNotifier.value.map((opt) {
      if (opt.id == 'stage_dim_inactive' || opt.id == 'stage_large_font') {
        return opt.copyWith(isVisible: false);
      }
      return opt.copyWith(isVisible: true);
    }).toList();
  }

  /// Preset: Minimal Stage (Hide clutter: author, notes, BPM; spotlight active)
  void applyMinimalistPreset() {
    optionsNotifier.value = optionsNotifier.value.map((opt) {
      switch (opt.id) {
        case 'song_key':
        case 'song_numbers':
        case 'stage_dim_inactive':
        case 'stage_large_font':
          return opt.copyWith(isVisible: true);
        default:
          return opt.copyWith(isVisible: false);
      }
    }).toList();
  }

  /// Preset: Pure Live Teleprompter (Hide ALL metadata, status, sequence numbers - pure song titles)
  void applyPureLivePreset() {
    optionsNotifier.value = optionsNotifier.value.map((opt) {
      switch (opt.id) {
        case 'stage_dim_inactive':
        case 'stage_large_font':
          return opt.copyWith(isVisible: true);
        default:
          return opt.copyWith(isVisible: false);
      }
    }).toList();
  }

  /// Total count of currently hidden options
  int get hiddenOptionsCount => optionsNotifier.value.where((o) => !o.isVisible).length;
}

