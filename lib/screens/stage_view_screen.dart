import 'package:flutter/material.dart';
import '../models/setlist.dart';
import '../models/song.dart';
import '../services/setlist_service.dart';
import '../services/song_service.dart';

class StageViewScreen extends StatefulWidget {
  final Setlist setlist;

  const StageViewScreen({
    super.key,
    required this.setlist,
  });

  @override
  State<StageViewScreen> createState() => _StageViewScreenState();
}

class _StageViewScreenState extends State<StageViewScreen> {
  int? _currentPlayingIndex;

  void _openDisplayOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;

        return ValueListenableBuilder<List<SetlistOptionDefinition>>(
          valueListenable: SetlistService.instance.optionsNotifier,
          builder: (context, options, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.tune_outlined, size: 18, color: colorScheme.onSurface),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'STAGE DISPLAY OPTIONS',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    Text(
                      'Toggle what to show or hide on the stage cards in real time.',
                      style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(color: colorScheme.outline),
                              foregroundColor: colorScheme.onSurface,
                            ),
                            onPressed: () => SetlistService.instance.applyStandardPreset(),
                            child: const Text('STANDARD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(color: colorScheme.outline),
                              foregroundColor: colorScheme.onSurface,
                            ),
                            onPressed: () => SetlistService.instance.applyMinimalistPreset(),
                            child: const Text('MINIMAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(color: colorScheme.outline),
                              foregroundColor: colorScheme.onSurface,
                            ),
                            onPressed: () => SetlistService.instance.applyPureLivePreset(),
                            child: const Text('TELEPROMPT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 6),

                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, idx) {
                          final opt = options[idx];
                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              opt.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              opt.description,
                              style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                            ),
                            value: opt.isVisible,
                            activeColor: colorScheme.onSurface,
                            activeTrackColor: colorScheme.outline,
                            onChanged: (_) {
                              SetlistService.instance.toggleOptionVisibility(opt.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmCompleteGig(BuildContext context, Setlist setlist) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            'COMPLETE GIG & ARCHIVE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Mark "${setlist.title}" as completed and archive it to Past Shows?',
            style: TextStyle(fontSize: 13, color: colorScheme.secondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('CANCEL', style: TextStyle(color: colorScheme.secondary, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.onSurface,
                foregroundColor: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                SetlistService.instance.markSetlistCompleted(setlist.id, true);
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Show completed! Archived "${setlist.title}" to Past Shows.'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('FINISH & ARCHIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allSongs = SongService.instance.songsNotifier.value;

    return ValueListenableBuilder<List<Setlist>>(
      valueListenable: SetlistService.instance.setlistsNotifier,
      builder: (context, setlists, _) {
        final currentSetlist = setlists.firstWhere(
          (s) => s.id == widget.setlist.id,
          orElse: () => widget.setlist,
        );

        final songs = currentSetlist.songIds.map((id) {
          return allSongs.firstWhere(
            (s) => s.id == id,
            orElse: () => Song(id: id, title: 'Unknown Song', createdAt: DateTime.now()),
          );
        }).toList();

        return ValueListenableBuilder<List<SetlistOptionDefinition>>(
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

            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Exit Stage View',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      currentSetlist.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    if (showDate || (showLocation && currentSetlist.location != null)) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (showDate) _formatDate(currentSetlist.date),
                          if (showLocation && currentSetlist.location != null) currentSetlist.location!,
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (!SetlistService.instance.isArchived(currentSetlist))
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text(
                        'FINISH GIG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      onPressed: () => _confirmCompleteGig(context, currentSetlist),
                    ),
                  IconButton(
                    icon: const Icon(Icons.tune_outlined),
                    tooltip: 'Stage Display Options (Show/Hide)',
                    onPressed: () => _openDisplayOptionsSheet(context),
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1.0),
                  child: Divider(
                    height: 1.0,
                    thickness: 1.0,
                    color: theme.dividerColor,
                  ),
                ),
              ),
              body: songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.queue_music_outlined,
                        size: 48,
                        color: colorScheme.secondary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This setlist has no songs yet.',
                        style: TextStyle(fontSize: 14, color: colorScheme.secondary),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Stage Status Bar (Toggable show/hide)
                    if (showStatusBar)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          border: Border(
                            bottom: BorderSide(color: colorScheme.outline, width: 0.8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                                  '${songs.length} TRACKS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _currentPlayingIndex != null
                                    ? 'PLAYING: #${_currentPlayingIndex! + 1}'
                                    : 'TAP TO HIGHLIGHT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                  color: colorScheme.secondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                     // Stage Song Cards List
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          left: 20.0,
                          right: 20.0,
                          top: 16.0,
                          bottom: 24.0 + MediaQuery.of(context).padding.bottom,
                        ),
                        itemCount: songs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == songs.length) {
                            final isArchived = SetlistService.instance.isArchived(currentSetlist);
                            if (!isArchived) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: colorScheme.outline, width: 1.2),
                                    foregroundColor: colorScheme.onSurface,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text(
                                    'COMPLETE GIG & ARCHIVE SETLIST',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  onPressed: () => _confirmCompleteGig(context, currentSetlist),
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(10),
                                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle, size: 18, color: colorScheme.secondary),
                                          const SizedBox(width: 10),
                                          Text(
                                            'SHOW COMPLETED (ARCHIVED)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          SetlistService.instance.markSetlistCompleted(currentSetlist.id, false);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Reopened "${currentSetlist.title}" to Upcoming Gigs.'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        child: const Text('REOPEN GIG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }

                          final song = songs[index];
                          final isCurrent = _currentPlayingIndex == index;
                          final cardOpacity = (dimInactive && !isCurrent) ? 0.45 : 1.0;
                          final allowCardDetails = isCurrent || showInactiveDetails;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
                            child: Opacity(
                              opacity: cardOpacity,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _currentPlayingIndex = isCurrent ? null : index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? colorScheme.surfaceContainerHighest
                                        : colorScheme.surface,
                                    border: Border.all(
                                      color: isCurrent ? colorScheme.onSurface : colorScheme.outline,
                                      width: isCurrent ? 2.0 : 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.all(largeFont ? 20.0 : 18.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Track number, Title, and Key/Tempo Badges
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (showNumbers) ...[
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: largeFont ? 10 : 8,
                                                vertical: largeFont ? 5 : 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isCurrent
                                                    ? colorScheme.onSurface
                                                    : colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '#${(index + 1).toString().padLeft(2, '0')}',
                                                style: TextStyle(
                                                  fontSize: largeFont ? 14 : 13,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                  color: isCurrent ? colorScheme.surface : colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                          ],
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  song.title,
                                                  style: TextStyle(
                                                    fontSize: largeFont ? 24 : 20,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                ),
                                                if (allowCardDetails && showArtist && song.artist != null && song.artist!.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    song.artist!,
                                                    style: TextStyle(
                                                      fontSize: largeFont ? 14 : 13,
                                                      fontWeight: FontWeight.w500,
                                                      color: colorScheme.secondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Badges: Key & Tempo
                                          Row(
                                            children: [
                                              if (showKey && song.musicalKey != null && song.musicalKey!.isNotEmpty) ...[
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: largeFont ? 12 : 10,
                                                    vertical: largeFont ? 7 : 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: colorScheme.outline,
                                                      width: 1.2,
                                                    ),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    song.musicalKey!,
                                                    style: TextStyle(
                                                      fontSize: largeFont ? 15 : 13,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                      color: colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              if (allowCardDetails && showTempo && song.tempo != null) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.surfaceContainerHighest,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '${song.tempo} BPM',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: colorScheme.secondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Stage Custom Fields & Notes Row (Capo, Tuning, etc.)
                                      if (allowCardDetails && showNotes && song.customFields.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: song.customFields.entries.map((entry) {
                                            final fieldDef = SongService.instance.fieldsNotifier.value.firstWhere(
                                              (f) => f.id == entry.key || f.name.toLowerCase() == entry.key.toLowerCase(),
                                              orElse: () => SongFieldDefinition(id: entry.key, name: entry.key),
                                            );
                                            final displayLabel = fieldDef.name.isNotEmpty ? fieldDef.name : entry.key;

                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: colorScheme.outline.withOpacity(0.7),
                                                  width: 0.8,
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: '${displayLabel.toUpperCase()}: ',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 10,
                                                        letterSpacing: 0.5,
                                                        color: colorScheme.secondary,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: entry.value,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        color: colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
            );
          },
        );
      },
    );
  }
}
