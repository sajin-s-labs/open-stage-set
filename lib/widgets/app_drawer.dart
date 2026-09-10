import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import '../screens/songs_screen.dart';
import '../screens/setlist_screen.dart';
import '../screens/chord_helper_screen.dart';
import '../screens/progression_player_screen.dart';
import '../screens/profile_screen.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../utils/image_utils.dart';
import 'app_logo.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const menuItems = <_DrawerItemData>[
      _DrawerItemData(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
      ),
      _DrawerItemData(
        title: 'Setlist',
        icon: Icons.queue_music_outlined,
      ),
      _DrawerItemData(
        title: 'Songs',
        icon: Icons.library_music_outlined,
      ),
      _DrawerItemData(
        title: 'Chord helper',
        icon: Icons.piano_outlined,
      ),
      _DrawerItemData(
        title: 'Song studio',
        icon: Icons.graphic_eq_outlined,
        badge: 'EXPERIMENTAL',
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AppLogo(size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'OPEN STAGE SET',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close sidebar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Musician Profile Header in Sidebar (Seamless, not a card)
            ValueListenableBuilder<AppThemeMode>(
              valueListenable: AppTheme.currentThemeMode,
              builder: (context, themeMode, _) {
                return ValueListenableBuilder<UserProfile>(
                  valueListenable: ProfileService.instance.profileNotifier,
                  builder: (context, profile, _) {
                    final avatarUrl = profile.getEffectiveAvatarUrl(themeMode);
                    final bgUrl = profile.getEffectiveBackgroundUrl(themeMode);
                    final avatarProvider = getAppImageProvider(avatarUrl);
                    final bgProvider = getAppImageProvider(bgUrl);

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (bgProvider != null) ...[
                            Container(
                              height: 60,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: bgProvider,
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.55),
                                    BlendMode.darken,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  backgroundImage: avatarProvider,
                                  child: avatarProvider == null
                                      ? Icon(Icons.person, size: 22, color: colorScheme.onSurface)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.name,
                                        style: TextStyle(
                                          fontSize: 14,
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
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                      if (profile.instruments.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          profile.instruments.join(' • '),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: colorScheme.secondary.withOpacity(0.8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: colorScheme.secondary,
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
            const Divider(),

            // Main Menu Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: [
                  ...menuItems.map(
                    (item) => _DrawerListTile(
                      icon: item.icon,
                      title: item.title,
                      badge: item.badge,
                      onTap: () {
                        if (item.title == 'Dashboard') {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        } else if (item.title == 'Songs') {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SongsScreen(),
                            ),
                          );
                        } else if (item.title == 'Setlist') {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SetlistScreen(),
                            ),
                          );
                        } else if (item.title == 'Chord helper') {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ChordHelperScreen(),
                            ),
                          );
                        } else if (item.title == 'Song studio') {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProgressionPlayerScreen(),
                            ),
                          );
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Divider(),
                  ),
                  _DrawerListTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Subtle Version Tag at Bottom
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'v1.0.0 • OLED MONOCHROME',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItemData {
  final String title;
  final IconData icon;
  final String? badge;

  const _DrawerItemData({
    required this.title,
    required this.icon,
    this.badge,
  });
}

class _DrawerListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final VoidCallback onTap;

  const _DrawerListTile({
    required this.icon,
    required this.title,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        leading: Icon(
          icon,
          size: 20,
          color: colorScheme.onSurface,
        ),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: colorScheme.onSurface,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colorScheme.outline, width: 0.8),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 16,
          color: colorScheme.secondary.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }
}
