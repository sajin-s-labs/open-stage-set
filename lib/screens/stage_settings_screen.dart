import 'package:flutter/material.dart';
import '../models/setlist.dart';
import '../services/setlist_service.dart';

class StageSettingsScreen extends StatelessWidget {
  const StageSettingsScreen({super.key});

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
        title: const Text('STAGE DISPLAY & HIDE SETTINGS'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            thickness: 1.0,
            color: theme.dividerColor,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<SetlistOptionDefinition>>(
        valueListenable: SetlistService.instance.optionsNotifier,
        builder: (context, options, _) {
          final showDate = SetlistService.instance.isOptionVisible('date');
          final showLocation = SetlistService.instance.isOptionVisible('location');
          final showKey = SetlistService.instance.isOptionVisible('song_key');
          final showTempo = SetlistService.instance.isOptionVisible('song_tempo');
          final showArtist = SetlistService.instance.isOptionVisible('song_artist');
          final showNotes = SetlistService.instance.isOptionVisible('song_notes');
          final showNumbers = SetlistService.instance.isOptionVisible('song_numbers');
          final showStatusBar = SetlistService.instance.isOptionVisible('stage_status_bar');
          final showInactiveDetails = SetlistService.instance.isOptionVisible('stage_inactive_details');
          final dimInactive = SetlistService.instance.isOptionVisible('stage_dim_inactive');
          final largeFont = SetlistService.instance.isOptionVisible('stage_large_font');

          final hiddenCount = options.where((o) => !o.isVisible).length;

          return ListView(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 24.0,
              bottom: 24.0 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              // 1. Philosophy & Live Status Banner
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
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
                              Icon(Icons.visibility_off_outlined, size: 18, color: colorScheme.onSurface),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'DISTRACTION-FREE STAGE MODE',
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
                            '$hiddenCount HIDDEN',
                            style: TextStyle(
                              fontSize: 10,
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
                      'Stage lights and live gigs require zero clutter. Hide non-essential metadata and chrome so your setlist remains crisp, fast, and legible from across the stage.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Stage Mode Quick Presets
              Text(
                'QUICK STAGE PRESETS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PresetButton(
                      title: 'STANDARD',
                      subtitle: 'All info',
                      isSelected: hiddenCount == 2 && !dimInactive && !largeFont,
                      onTap: () => SetlistService.instance.applyStandardPreset(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PresetButton(
                      title: 'MINIMAL',
                      subtitle: 'Spotlight',
                      isSelected: !showNotes && !showArtist && !showTempo && dimInactive,
                      onTap: () => SetlistService.instance.applyMinimalistPreset(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PresetButton(
                      title: 'TELEPROMPT',
                      subtitle: 'Titles only',
                      isSelected: !showKey && !showNumbers && !showNotes && dimInactive,
                      onTap: () => SetlistService.instance.applyPureLivePreset(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Live Stage Card Preview
              Text(
                'LIVE STAGE PREVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline, width: 1.0),
                  borderRadius: BorderRadius.circular(10.0),
                  color: colorScheme.surface,
                ),
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showStatusBar) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colorScheme.outline, width: 0.6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '● 3 TRACKS IN SETLIST',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                            Text(
                              'PLAYING: #01',
                              style: TextStyle(fontSize: 9, color: colorScheme.secondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Sample Active Song Card
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        border: Border.all(color: colorScheme.onSurface, width: 2.0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (showNumbers) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.onSurface,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#01',
                                    style: TextStyle(
                                      fontSize: largeFont ? 12 : 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.surface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  'Echoes of the Night',
                                  style: TextStyle(
                                    fontSize: largeFont ? 18 : 15,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showKey) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colorScheme.outline, width: 1.0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Am',
                                    style: TextStyle(
                                      fontSize: largeFont ? 13 : 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (showTempo) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '128 BPM',
                                    style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (showArtist) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Orbit Collective',
                              style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                            ),
                          ],
                          if (showNotes) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colorScheme.outline.withOpacity(0.5), width: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('CAPO: 2nd Fret', style: TextStyle(fontSize: 9, color: colorScheme.secondary)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Sample Inactive Song Card
                    Opacity(
                      opacity: dimInactive ? 0.45 : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          border: Border.all(color: colorScheme.outline, width: 1.0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (showNumbers) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#02',
                                  style: TextStyle(
                                    fontSize: largeFont ? 12 : 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                'Neon Skyline',
                                style: TextStyle(
                                  fontSize: largeFont ? 18 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (showInactiveDetails && showKey) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: colorScheme.outline, width: 1.0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'E',
                                  style: TextStyle(
                                    fontSize: largeFont ? 13 : 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Stage Chrome & Layout Hide Controls
              Text(
                'STAGE LAYOUT & CHROME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 10),

              _StageToggleTile(
                icon: Icons.vertical_align_top,
                title: 'Stage Top Status Bar',
                subtitle: 'Track counter and highlight instructions banner',
                isVisible: showStatusBar,
                onToggle: () => SetlistService.instance.toggleOptionVisibility('stage_status_bar'),
              ),
              _StageToggleTile(
                icon: Icons.calendar_today_outlined,
                title: 'Event Date & Venue',
                subtitle: 'Venue name and gig date in the stage app bar header',
                isVisible: showDate || showLocation,
                onToggle: () {
                  final anyVisible = showDate || showLocation;
                  if (anyVisible) {
                    if (showDate) SetlistService.instance.toggleOptionVisibility('date');
                    if (showLocation) SetlistService.instance.toggleOptionVisibility('location');
                  } else {
                    SetlistService.instance.toggleOptionVisibility('date');
                    SetlistService.instance.toggleOptionVisibility('location');
                  }
                },
              ),
              _StageToggleTile(
                icon: Icons.filter_list_outlined,
                title: 'Inactive Track Details',
                subtitle: 'Hide BPM, artist & notes on non-playing tracks to collapse them',
                isVisible: showInactiveDetails,
                onToggle: () => SetlistService.instance.toggleOptionVisibility('stage_inactive_details'),
              ),
              _StageToggleTile(
                icon: Icons.highlight_outlined,
                title: 'Dim Inactive Tracks',
                subtitle: 'Reduce opacity of non-playing songs to spotlight active track',
                isVisible: dimInactive,
                onToggle: () => SetlistService.instance.toggleOptionVisibility('stage_dim_inactive'),
              ),
              _StageToggleTile(
                icon: Icons.format_size,
                title: 'Extra Large Stage Font',
                subtitle: 'Enlarge song titles and keys for floor wedge & stand distance',
                isVisible: largeFont,
                onToggle: () => SetlistService.instance.toggleOptionVisibility('stage_large_font'),
              ),

              const SizedBox(height: 20),

              // 5. Metadata Hide Controls
              Text(
                'METADATA VISIBILITY ON STAGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 10),

              _StageToggleTile(
                icon: Icons.numbers_outlined,
                title: 'Track Sequence Numbers (#01, #02)',
                subtitle: 'Numeric position badge next to song titles',
                isVisible: showNumbers,
                onToggle: () => SetlistService.instance.toggleOptionVisibility('song_numbers'),
              ),
              _StageToggleTile(
                icon: Icons.music_note_outlined,
                title: 'Song Musical Key',
                subtitle: 'Key signatures (e.g. Am, C, G) tag next to songs',
                isVisible: showKey,
                onToggle: () => SetlistService.instance.toggleOptionVisibility('song_key'),
              ),
              _StageToggleTile(
                icon: Icons.speed_outlined,
                title: 'Song Tempo (BPM)',
                subtitle: 'Beats per minute tempo tag',
                isVisible: showTempo,
                onToggle: () => SetlistService.instance.toggleOptionVisibility('song_tempo'),
              ),
              _StageToggleTile(
                icon: Icons.person_outline,
                title: 'Song Artist / Author',
                subtitle: 'Composer / artist credit beneath title',
                isVisible: showArtist,
                onToggle: () => SetlistService.instance.toggleOptionVisibility('song_artist'),
              ),
              _StageToggleTile(
                icon: Icons.note_outlined,
                title: 'Custom Fields & Stage Notes',
                subtitle: 'Capo, guitar tuning, and performance cues chips',
                isVisible: showNotes,
                onToggle: () => SetlistService.instance.toggleOptionVisibility('song_notes'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surfaceContainerHighest : Colors.transparent,
          border: Border.all(
            color: isSelected ? colorScheme.onSurface : colorScheme.outline,
            width: isSelected ? 2.0 : 0.8,
          ),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isVisible;
  final VoidCallback onToggle;

  const _StageToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isVisible ? colorScheme.outline : colorScheme.outline.withOpacity(0.4),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(
              isVisible ? icon : Icons.visibility_off_outlined,
              size: 20,
              color: isVisible ? colorScheme.onSurface : colorScheme.secondary.withOpacity(0.4),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isVisible ? colorScheme.onSurface : colorScheme.secondary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isVisible,
              activeColor: colorScheme.onSurface,
              activeTrackColor: colorScheme.outline,
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}
