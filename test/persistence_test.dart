import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_stage_set/theme/app_theme.dart';
import 'package:open_stage_set/widgets/app_logo.dart';
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
    // 1. Initial should be oledDark
    await AppTheme.init();
    expect(AppTheme.currentThemeMode.value, AppThemeMode.oledDark);

    // 2. Change to light theme
    AppTheme.setTheme(AppThemeMode.light);
    expect(AppTheme.currentThemeMode.value, AppThemeMode.light);

    // 3. Reset in-memory notifier to oledDark to simulate app kill & relaunch
    AppTheme.currentThemeMode.value = AppThemeMode.oledDark;

    // 4. Call init() as app startup does
    await AppTheme.init();
    expect(AppTheme.currentThemeMode.value, AppThemeMode.light);
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
}
