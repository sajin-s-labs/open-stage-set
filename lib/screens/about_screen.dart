import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Settings',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('ABOUT'),
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
          // Official Open Stage Set Monochrome Emblem (Resonance Fork Vector)
          const Center(
            child: AppLogo(
              size: 96,
              circular: true,
              logoId: 'tuning_fork',
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'OPEN STAGE SET',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 3.5,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Live Stage & Rehearsal Companion',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                color: colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline, width: 0.8),
              ),
              child: Text(
                'OFFICIAL EMBLEM: RESONANCE FORK (VECTOR)',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Google Antigravity & Gemini 3.8 Flash Statement Banner
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border.all(color: colorScheme.onSurface, width: 1.4),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 22,
                  color: colorScheme.onSurface,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Entire application was built using Google Antigravity, Gemini 3.8 Flash.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      height: 1.45,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Specifications Section (TOP POSITION)
          Text(
            'SPECIFICATIONS',
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
            child: const Column(
              children: [
                _InfoRow(label: 'Application', value: 'Open Stage Set'),
                Divider(height: 20),
                _InfoRow(label: 'Version', value: '1.0.0 (Build 1)'),
                Divider(height: 20),
                _InfoRow(label: 'Official Emblem', value: 'Resonance Fork (Vector)'),
                Divider(height: 20),
                _InfoRow(label: 'Platform', value: 'Google Antigravity'),
                Divider(height: 20),
                _InfoRow(label: 'AI Engine', value: 'Gemini 3.8 Flash'),
                Divider(height: 20),
                _InfoRow(label: 'Architecture', value: 'Flutter Cross-Platform'),
                Divider(height: 20),
                _InfoRow(label: 'Design System', value: 'Monochrome OLED Engine'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Philosophy Section (TOP POSITION)
          Text(
            'PHILOSOPHY',
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
            child: Text(
              'Engineered for musicians, performers, and creators who need clean, distraction-free visual references on stage without bright reflections or visual clutter.',
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Currently Supported Features Section
          Text(
            'CURRENTLY SUPPORTED FEATURES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Column(
              children: [
                _FeatureItem(
                  icon: Icons.stadium_outlined,
                  title: 'Stage Performance View',
                  description: 'Live gig companion with active song tracking, high-contrast key/tempo badges, and customizable stage field displays.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.queue_music_outlined,
                  title: 'Setlists & Song Library',
                  description: 'Organize setlists, reorder songs, search music catalog, and define custom metadata fields.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Intelligent Chord Recommender',
                  description: 'Harmonic suggestions grouped by musical feel (Simple, Uplifting, Bittersweet, Soulful, Bluesy, Tension, Modulation, Experimental) with bidirectional transition audition and prefix/suffix queuing.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.piano_outlined,
                  title: 'Interactive Piano Roll Visualizer',
                  description: '2-octave responsive keyboard displaying exact chord voicings, interval roles (R, 3, 5), single-note audition, and full chord/arpeggio playback.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.grid_on_outlined,
                  title: 'Guitar Chord Box Visualizer',
                  description: '6-string guitar fretboard box diagrams with nut indicators, open/muted strings, fingering circles, and strum chord preview.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.change_circle_outlined,
                  title: 'Circle of Fifths Explorer',
                  description: 'Harmonic circle displaying relative major/minor keys, diatonic chord degrees (I–vii°), and integrated audio playback.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.volume_up_outlined,
                  title: 'Polyphonic Audio Synthesizer',
                  description: 'Cross-platform Web Audio and native synthesis engine for smooth chord voicings, arpeggios, and keyboard feedback.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.contrast_outlined,
                  title: 'Monochrome OLED Theme Engine',
                  description: 'Pure high-contrast black and white design system crafted for distraction-free visibility on dark stages and in bright daylight.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Planned Features Section
          Text(
            'PLANNED FEATURES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.onSurface, width: 1.4),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Column(
              children: [
                _FeatureItem(
                  icon: Icons.lyrics_outlined,
                  title: 'Song Lyrics & Chord Charts',
                  statusBadge: 'IN ROADMAP',
                  description: 'Industry-standard ChordPro integration with chords rendered directly over lyrics, 1-tap real-time transposition across all keys, song section breakdown ([Verse], [Chorus], [Bridge]), and hands-free auto-scrolling stage teleprompter.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Unplanned AI Suggested Features Section
          Text(
            'UNPLANNED AI SUGGESTIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Column(
              children: [
                _FeatureItem(
                  icon: Icons.speed_outlined,
                  title: 'Silent Visual Metronome & Tap Tempo',
                  statusBadge: 'AI CONCEPT',
                  description: 'Discreet, high-contrast visual flash pulse for silent stage count-ins without monitor bleed, accompanied by an instant tap-tempo calculator.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.touch_app_outlined,
                  title: 'Bluetooth Foot Pedal Navigation',
                  statusBadge: 'AI CONCEPT',
                  description: 'Hands-free page turning via AirTurn, PageFlip, and Bluetooth LE pedals to advance songs and scroll charts during live play.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.timer_outlined,
                  title: 'Show Duration & Curfew Tracker',
                  statusBadge: 'AI CONCEPT',
                  description: 'Live performance timer tracking elapsed gig time, remaining set countdown, and visual warnings for venue curfews.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.tune_outlined,
                  title: 'Capo Calculator & Alternate Tunings',
                  statusBadge: 'AI CONCEPT',
                  description: 'Instant Capo transposition chart and fretboard chord diagrams for Drop D, DADGAD, Open G, and alternate guitar tunings.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.print_outlined,
                  title: 'Printable Monochrome Stage Setlists',
                  statusBadge: 'AI CONCEPT',
                  description: 'One-tap export of ink-efficient, high-contrast monochrome PDF setlists tailored for stage floors and sound technicians.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.mic_outlined,
                  title: 'Rehearsal Voice Memo Scratchpad',
                  statusBadge: 'AI CONCEPT',
                  description: 'Fast one-touch audio memo recorder to attach songwriting riffs, vocal lines, or rehearsal snippets directly to songs.',
                ),
                Divider(height: 16),
                _FeatureItem(
                  icon: Icons.cable_outlined,
                  title: 'Hardware MIDI Keyboard Controller',
                  statusBadge: 'AI CONCEPT',
                  description: 'USB and Bluetooth MIDI connectivity for hardware keyboard input, chord audition, and automatic harmony recognition.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? statusBadge;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    this.statusBadge,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: 18, color: colorScheme.onSurface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (statusBadge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colorScheme.outline, width: 0.8),
                        ),
                        child: Text(
                          statusBadge!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
