import 'package:flutter/material.dart';
import 'chord_recommender_screen.dart';
import 'circle_of_fifths_screen.dart';
import 'piano_roll_screen.dart';

class ChordHelperScreen extends StatelessWidget {
  const ChordHelperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('CHORD HELPER & HARMONY'),
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
          // 1. Philosophy & Audio Status Banner
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline, width: 1.0),
              borderRadius: BorderRadius.circular(10.0),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.graphic_eq, size: 18, color: colorScheme.onSurface),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'HARMONIC TOOLKIT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: colorScheme.outline, width: 0.8),
                      ),
                      child: Text(
                        'AUDIO ON',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore what chords resolve naturally, visualize keys on the Circle of Fifths, and test voicings on the interactive piano roll.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'CHORD HELPER MODULES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 14),

          // Option 1: What Chord to Add
          _ChordModuleTile(
            icon: Icons.alt_route_outlined,
            title: 'What chord to add',
            subtitle: 'Diatonic resolutions, emotional moods & borrowed chords',
            badgeText: 'Recommendations',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChordRecommenderScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Option 2: Circle of Fifths & Guide
          _ChordModuleTile(
            icon: Icons.change_circle_outlined,
            title: 'Circle of fifths & harmony guide',
            subtitle: 'Interactive 12-key wheel, relative minors & modulation',
            badgeText: '12 Keys & Audio',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CircleOfFifthsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Option 3: Interactive Piano Roll
          _ChordModuleTile(
            icon: Icons.keyboard_outlined,
            title: 'Piano roll & chord keybed',
            subtitle: '2-octave interactive keyboard, voicing roles & arpeggios',
            badgeText: 'Interactive Keys',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PianoRollScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Subtle Engine Tag at Bottom
          Center(
            child: Text(
              'BUILT-IN POLYPHONIC AUDIO SYNTHESIZER • ZERO LATENCY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: colorScheme.secondary.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChordModuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;

  const _ChordModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline, width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline, width: 1.0),
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              child: Icon(
                icon,
                size: 22,
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
                      letterSpacing: 0.5,
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline, width: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: colorScheme.secondary,
                ),
              ),
            ),
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
