import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_stage_set/theme/app_theme.dart';
import 'package:open_stage_set/services/storage_service.dart';
import 'package:open_stage_set/services/song_service.dart';
import 'package:open_stage_set/services/setlist_service.dart';
import 'package:open_stage_set/services/profile_service.dart';
import 'package:open_stage_set/models/song.dart';
import 'package:open_stage_set/models/setlist.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AppTheme persists theme selection across restarts', () async {
    // 1. Initial should be light
    await AppTheme.init();
    expect(AppTheme.currentThemeMode.value, AppThemeMode.light);

    // 2. Change to oledDark theme
    AppTheme.setTheme(AppThemeMode.oledDark);
    expect(AppTheme.currentThemeMode.value, AppThemeMode.oledDark);

    // 3. Reset in-memory notifier to light to simulate app kill & relaunch
    AppTheme.currentThemeMode.value = AppThemeMode.light;

    // 4. Call init() as app startup does
    await AppTheme.init();
    expect(AppTheme.currentThemeMode.value, AppThemeMode.oledDark);
  });

  test('SongService persists added and edited songs across restarts', () async {
    await SongService.instance.init();
    final initialCount = SongService.instance.songsNotifier.value.length;

    final newSong = Song(
      id: 'test_song_1',
      title: 'Persistent Rock',
      artist: 'The Testers',
      musicalKey: 'A Min',
      tempo: 120,
      createdAt: DateTime.now(),
    );
    await SongService.instance.addSong(newSong);
    expect(SongService.instance.songsNotifier.value.length, initialCount + 1);

    // Simulate app restart by clearing in-memory songs
    SongService.instance.songsNotifier.value = [];

    // Re-initialize from storage
    await SongService.instance.init();
    expect(SongService.instance.songsNotifier.value.length, initialCount + 1);
    expect(SongService.instance.songsNotifier.value.first.title, 'Persistent Rock');
  });

  test('SetlistService persists setlist changes across restarts', () async {
    await SetlistService.instance.init();
    final initialCount = SetlistService.instance.setlistsNotifier.value.length;

    final newSetlist = Setlist(
      id: 'test_setlist_1',
      title: 'Festival Headliner',
      date: DateTime.now().add(const Duration(days: 5)),
      location: 'Central Arena',
      songIds: ['test_song_1'],
      createdAt: DateTime.now(),
    );
    await SetlistService.instance.addSetlist(newSetlist);
    expect(SetlistService.instance.setlistsNotifier.value.length, initialCount + 1);

    // Simulate app restart
    SetlistService.instance.setlistsNotifier.value = [];
    await SetlistService.instance.init();

    expect(SetlistService.instance.setlistsNotifier.value.length, initialCount + 1);
    expect(SetlistService.instance.setlistsNotifier.value.first.title, 'Festival Headliner');
  });

  test('ProfileService persists profile edits across restarts', () async {
    await ProfileService.instance.init();
    final current = ProfileService.instance.profileNotifier.value;
    ProfileService.instance.updateProfile(current.copyWith(bandName: 'Electric Symphony'));

    // Simulate app restart
    ProfileService.instance.profileNotifier.value = ProfileService.defaultProfile;
    await ProfileService.instance.init();

    expect(ProfileService.instance.profileNotifier.value.bandName, 'Electric Symphony');
  });

  test('AppStorageService persists uploaded files across restarts', () async {
    await AppStorageService.instance.init();
    final testBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
    final storageKey = AppStorageService.instance.storeCopiedFile(
      originalName: 'stage_avatar.png',
      bytes: testBytes,
    );

    expect(AppStorageService.instance.hasImage(storageKey), isTrue);
    expect(AppStorageService.instance.getImageBytes(storageKey), testBytes);

    // Simulate restart with a fresh AppStorageService instance
    // Re-init from shared preferences
    await AppStorageService.instance.init();
    expect(AppStorageService.instance.hasImage(storageKey), isTrue);
    final reloadedBytes = AppStorageService.instance.getImageBytes(storageKey);
    expect(reloadedBytes, testBytes);
  });

  test('SongService.deleteSong removes song from all setlists', () async {
    await SongService.instance.init();
    await SetlistService.instance.init();

    final song = Song(
      id: 'song_to_delete',
      title: 'To Be Deleted',
      createdAt: DateTime.now(),
    );
    await SongService.instance.addSong(song);

    final setlist = Setlist(
      id: 'setlist_with_song',
      title: 'Active Setlist',
      date: DateTime.now().add(const Duration(days: 1)),
      songIds: ['song_to_delete', 'other_song'],
      createdAt: DateTime.now(),
    );
    await SetlistService.instance.addSetlist(setlist);

    expect(
      SetlistService.instance.setlistsNotifier.value
          .firstWhere((s) => s.id == 'setlist_with_song')
          .songIds,
      contains('song_to_delete'),
    );

    // Delete song
    await SongService.instance.deleteSong('song_to_delete');

    // Verify it is removed from SongService
    expect(
      SongService.instance.songsNotifier.value.any((s) => s.id == 'song_to_delete'),
      isFalse,
    );

    // Verify it was cleaned up from the setlist
    final updatedSetlist = SetlistService.instance.setlistsNotifier.value
        .firstWhere((s) => s.id == 'setlist_with_song');
    expect(updatedSetlist.songIds.contains('song_to_delete'), isFalse);
    expect(updatedSetlist.songIds, ['other_song']);
  });
}
