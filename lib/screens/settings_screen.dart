import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/song_service.dart';
import '../services/setlist_service.dart';
import '../services/profile_service.dart';
import '../models/song.dart';
import '../models/setlist.dart';
import '../models/user_profile.dart';
import 'theme_appearance_screen.dart';
import 'song_fields_settings_screen.dart';
import 'setlist_settings_screen.dart';
import 'stage_settings_screen.dart';
import 'profile_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _getThemeBadge(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.oledDark:
        return 'OLED Dark';
      case AppThemeMode.grayscale:
        return 'Grayscale';
      case AppThemeMode.light:
        return 'Light';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.currentThemeMode,
      builder: (context, currentMode, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('SETTINGS'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Divider(
                height: 1.0,
                thickness: 1.0,
                color: theme.dividerColor,
              ),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 24.0,
              bottom: 24.0 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              Text(
                'PREFERENCES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),

              // Option 0: Musician Profile
              ValueListenableBuilder<UserProfile>(
                valueListenable: ProfileService.instance.profileNotifier,
                builder: (context, profile, _) {
                  return _SettingsOptionTile(
                    icon: Icons.person_outline,
                    title: 'Musician profile',
                    subtitle: profile.bandName.isNotEmpty
                        ? '${profile.bandName} • ${profile.instruments.take(2).join(", ")}'
                        : 'Name, instruments, band & images',
                    badgeText: profile.name,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 1: Theme & Appearance
              _SettingsOptionTile(
                icon: Icons.palette_outlined,
                title: 'Theme & appearance',
                subtitle: 'OLED Dark, Grayscale & Monochrome Light',
                badgeText: _getThemeBadge(currentMode),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ThemeAppearanceScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Stage Mode & Hide Settings
              ValueListenableBuilder<List<SetlistOptionDefinition>>(
                valueListenable: SetlistService.instance.optionsNotifier,
                builder: (context, options, _) {
                  final hiddenCount = options.where((o) => !o.isVisible).length;
                  return _SettingsOptionTile(
                    icon: Icons.speaker_group_outlined,
                    title: 'Stage mode & hide settings',
                    subtitle: 'Hide status bar, BPM, notes & chrome for distraction-free gigs',
                    badgeText: hiddenCount > 0 ? '$hiddenCount hidden' : 'Full info',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StageSettingsScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 3: Song Fields & Attributes
              ValueListenableBuilder<List<SongFieldDefinition>>(
                valueListenable: SongService.instance.fieldsNotifier,
                builder: (context, fields, _) {
                  final activeCount = fields.where((f) => f.isVisible).length;
                  return _SettingsOptionTile(
                    icon: Icons.tune_outlined,
                    title: 'Song fields & options',
                    subtitle: 'Manage song metadata, custom fields & visibility',
                    badgeText: '$activeCount active',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SongFieldsSettingsScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 4: Setlist Display Options
              ValueListenableBuilder<List<SetlistOptionDefinition>>(
                valueListenable: SetlistService.instance.optionsNotifier,
                builder: (context, options, _) {
                  final activeCount = options.where((o) => o.isVisible).length;
                  return _SettingsOptionTile(
                    icon: Icons.queue_music_outlined,
                    title: 'Setlist display options',
                    subtitle: 'Show or hide event date, venue, keys, tempo & notes',
                    badgeText: '$activeCount active',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SetlistSettingsScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 4: About
              _SettingsOptionTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App specifications, version & philosophy',
                badgeText: 'v1.0.0',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final VoidCallback onTap;

  const _SettingsOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline, width: 1.0),
              ),
              child: Icon(
                icon,
                size: 20,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline, width: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
