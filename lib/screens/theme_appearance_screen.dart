import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeAppearanceScreen extends StatelessWidget {
  const ThemeAppearanceScreen({super.key});

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
              tooltip: 'Back to Settings',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('THEME & APPEARANCE'),
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
                'SELECT THEME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),

              // Option 1: OLED Dark
              _ThemeOptionCard(
                title: 'OLED Dark Mode',
                subtitle: 'Pitch black (#000000) for OLED panels • Zero stage light pollution',
                icon: Icons.dark_mode_outlined,
                isSelected: currentMode == AppThemeMode.oledDark,
                onTap: () => AppTheme.setTheme(AppThemeMode.oledDark),
              ),
              const SizedBox(height: 12),

              // Option 2: Grayscale
              _ThemeOptionCard(
                title: 'Grayscale Mode',
                subtitle: 'Neutral slate greys (#1C1C1C) • Balanced soft contrast, no harsh blacks',
                icon: Icons.tonality_outlined,
                isSelected: currentMode == AppThemeMode.grayscale,
                onTap: () => AppTheme.setTheme(AppThemeMode.grayscale),
              ),
              const SizedBox(height: 12),

              // Option 3: Monochrome Light
              _ThemeOptionCard(
                title: 'Monochrome Light Mode',
                subtitle: 'High contrast clean white (#FFFFFF) & charcoal greys • Bright lighting readability',
                icon: Icons.light_mode_outlined,
                isSelected: currentMode == AppThemeMode.light,
                onTap: () => AppTheme.setTheme(AppThemeMode.light),
              ),
              const SizedBox(height: 32),

              // Display Optimization Callout
              Text(
                'DISPLAY OPTIMIZATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.energy_savings_leaf_outlined,
                          size: 18,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hardware True Black vs Grayscale',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'OLED Dark powers off pixels at pure #000000 black to maximize battery and minimize stage reflection. Grayscale mode provides a soft neutral slate palette for performers who prefer subtle contrast without pitch black clipping.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colorScheme.onSurface : colorScheme.outline,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.onSurface : colorScheme.outline,
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? colorScheme.onSurface : colorScheme.secondary,
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
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.secondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.onSurface : colorScheme.outline,
                  width: 1.5,
                ),
                color: isSelected ? colorScheme.onSurface : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: colorScheme.surface,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
