import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'models/user_profile.dart';
import 'models/setlist.dart';
import 'models/song.dart';
import 'services/profile_service.dart';
import 'services/setlist_service.dart';
import 'services/song_service.dart';
import 'widgets/app_drawer.dart';
import 'screens/songs_screen.dart';
import 'screens/setlist_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stage_view_screen.dart';
import 'screens/chord_helper_screen.dart';
import 'package:flutter/services.dart';
import 'screens/progression_player_screen.dart';
import 'utils/image_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.currentThemeMode,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'Open Stage Set',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(currentThemeMode),
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _relativeDateBadge(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final gigDay = DateTime(date.year, date.month, date.day);
    final diffDays = gigDay.difference(today).inDays;

    if (diffDays == 0) return 'TODAY';
    if (diffDays == 1) return 'TOMORROW';
    if (diffDays > 1) return 'IN $diffDays DAYS';
    return 'PAST';
  }

  void _showSwitchSetlistDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final upcoming = SetlistService.instance.upcomingSetlists;
    final currentActiveId = SetlistService.instance.activeSetlist?.id;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outline, width: 1.0),
          ),
          title: Text(
            'SELECT ACTIVE UPCOMING SETLIST',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: upcoming.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No upcoming setlists available. Past shows are safely archived.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(color: colorScheme.outline),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SetlistScreen()),
                            );
                          },
                          child: const Text('CREATE NEW SETLIST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: upcoming.length,
                    itemBuilder: (context, idx) {
                      final item = upcoming[idx];
                      final isCurrent = item.id == currentActiveId;
                      final badgeText = _relativeDateBadge(item.date);

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${_formatDate(item.date)} • ${item.songIds.length} songs',
                          style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                        ),
                        trailing: isCurrent
                            ? Icon(Icons.check_circle, size: 18, color: colorScheme.onSurface)
                            : null,
                        onTap: () {
                          SetlistService.instance.setActiveSetlist(item.id);
                          Navigator.of(dialogContext).pop();
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'CLOSE',
                style: TextStyle(color: colorScheme.secondary, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.currentThemeMode,
      builder: (context, currentThemeMode, _) {
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open sidebar',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: const Text('OPEN STAGE SET'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Divider(
                height: 1.0,
                thickness: 1.0,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          drawer: const AppDrawer(),
          body: ListView(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
              bottom: 24.0 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              // 1. Musician Profile Banner Card
              ValueListenableBuilder<UserProfile>(
                valueListenable: ProfileService.instance.profileNotifier,
                builder: (context, profile, _) {
                  final avatarUrl = profile.getEffectiveAvatarUrl(currentThemeMode);
                  final bgUrl = profile.getEffectiveBackgroundUrl(currentThemeMode);
                  final avatarProvider = getAppImageProvider(avatarUrl);
                  final bgProvider = getAppImageProvider(bgUrl);

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline, width: 1.0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Background banner (No edit button on Dashboard)
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            image: bgProvider != null
                                ? DecorationImage(
                                    image: bgProvider,
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withOpacity(0.55),
                                      BlendMode.darken,
                                    ),
                                  )
                                : null,
                          ),
                        ),

                        // Musician Details & Avatar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -28),
                                child: Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colorScheme.surface, width: 2.5),
                                    color: colorScheme.surfaceContainerHighest,
                                    image: avatarProvider != null
                                        ? DecorationImage(
                                            image: avatarProvider,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: avatarProvider == null
                                      ? Icon(Icons.person, size: 30, color: colorScheme.onSurface)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    if (profile.bandName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        profile.bandName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Instruments list
                        if (profile.instruments.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 14.0),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: profile.instruments.map((inst) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colorScheme.outline),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    inst,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 2. Active Setlist Card View
              Text(
                'STAGE SETLIST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),

              ValueListenableBuilder<String?>(
                valueListenable: SetlistService.instance.activeSetlistIdNotifier,
                builder: (context, activeId, _) {
                  return ValueListenableBuilder<List<Setlist>>(
                    valueListenable: SetlistService.instance.setlistsNotifier,
                    builder: (context, setlists, _) {
                      final active = SetlistService.instance.activeSetlist;

                      if (active == null) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.event_available_outlined, size: 36, color: colorScheme.secondary.withOpacity(0.5)),
                                const SizedBox(height: 10),
                                Text(
                                  'NO UPCOMING SETLISTS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Past shows are safely saved in your archive.\nCreate or schedule your next gig to activate stage mode.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.onSurface,
                                    side: BorderSide(color: colorScheme.outline),
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('CREATE SETLIST'),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const SetlistScreen()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final allSongs = SongService.instance.songsNotifier.value;
                      final setlistSongs = active.songIds
                          .map((id) => allSongs.firstWhere((s) => s.id == id, orElse: () => Song(id: id, title: 'Unknown Song', createdAt: DateTime.now())))
                          .toList();

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline, width: 1.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Top Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ACTIVE UPCOMING SETLIST',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () => _showSwitchSetlistDialog(context),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Row(
                                        children: [
                                          Icon(Icons.swap_horiz, size: 14, color: colorScheme.secondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'SWITCH',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Main Setlist Body
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              active.title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today_outlined, size: 12, color: colorScheme.secondary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDate(active.date),
                                                  style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                                                ),
                                                if (active.location != null && active.location!.isNotEmpty) ...[
                                                  const SizedBox(width: 10),
                                                  Icon(Icons.place_outlined, size: 12, color: colorScheme.secondary),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      active.location!,
                                                      style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceContainerHighest,
                                              border: Border.all(color: colorScheme.outline.withOpacity(0.8)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _relativeDateBadge(active.date),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.8,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: colorScheme.outline),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${setlistSongs.length} Songs',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(),
                                  const SizedBox(height: 10),

                                  // Track preview
                                  ...setlistSongs.take(4).map((song) {
                                    final idx = setlistSongs.indexOf(song);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            '#${idx + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              song.title,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (song.musicalKey != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: colorScheme.outline.withOpacity(0.6)),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                song.musicalKey!,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          if (song.tempo != null)
                                            Text(
                                              '${song.tempo} BPM',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: colorScheme.secondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),

                                  if (setlistSongs.length > 4) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '+ ${setlistSongs.length - 4} more tracks in setlist',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),

                                  // Action Buttons inside Card
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.onSurface,
                                            foregroundColor: colorScheme.surface,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(Icons.play_arrow, size: 16),
                                          label: const Text(
                                            'STAGE VIEW',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                           onPressed: () {
                                             Navigator.of(context).push(
                                               MaterialPageRoute(
                                                 builder: (context) => StageViewScreen(setlist: active),
                                               ),
                                             );
                                           },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: colorScheme.onSurface,
                                          side: BorderSide(color: colorScheme.outline),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.queue_music, size: 16),
                                        label: const Text(
                                          'ALL SETLISTS',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const SetlistScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // 3. Quick Navigation Hub
              Text(
                'QUICK REPERTOIRE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SongsScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.library_music_outlined, size: 20, color: colorScheme.onSurface),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Songs',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Full Library',
                                    style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: colorScheme.secondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, size: 20, color: colorScheme.onSurface),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Settings',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'App & Themes',
                                    style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: colorScheme.secondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Chord Helper Quick Access Card
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ChordHelperScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Icon(Icons.piano_outlined, size: 18, color: colorScheme.onSurface),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chord Helper & Harmony Toolkit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Next chords, Circle of Fifths & piano roll',
                              style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline, width: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SOUND ON',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, size: 16, color: colorScheme.secondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 5. Song Studio (Experimental) Quick Access Card
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProgressionPlayerScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Icon(Icons.graphic_eq_outlined, size: 18, color: colorScheme.onSurface),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Song Studio & Progression Player',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Song sections, passing chords, piano/guitar diagrams',
                              style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          border: Border.all(color: colorScheme.outline, width: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'EXPERIMENTAL',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, size: 16, color: colorScheme.secondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
