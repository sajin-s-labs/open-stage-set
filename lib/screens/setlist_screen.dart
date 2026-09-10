import 'package:flutter/material.dart';
import '../models/setlist.dart';
import '../models/song.dart';
import '../services/setlist_service.dart';
import '../services/song_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/create_song_sheet.dart';
import 'setlist_settings_screen.dart';
import 'stage_view_screen.dart';

String _formatDate(DateTime dt) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

class SetlistScreen extends StatefulWidget {
  const SetlistScreen({super.key});

  @override
  State<SetlistScreen> createState() => _SetlistScreenState();
}

class _SetlistScreenState extends State<SetlistScreen> {
  String _searchQuery = '';
  int _selectedTab = 0; // 0: Upcoming Gigs, 1: Past Shows / Archive

  void _openSetlistModal(BuildContext context, {Setlist? initialSetlist}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _CreateSetlistSheet(initialSetlist: initialSetlist),
    );
  }

  void _confirmDeleteSetlist(BuildContext context, Setlist setlist) {
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
            'DELETE SETLIST',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${setlist.title}"? This cannot be undone.',
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
                SetlistService.instance.deleteSetlist(setlist.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${setlist.title}"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('DELETE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('SETLISTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Display Options (Show/Hide)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SetlistSettingsScreen(),
                ),
              );
            },
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
      drawer: const AppDrawer(),
      body: ValueListenableBuilder<List<Setlist>>(
        valueListenable: SetlistService.instance.setlistsNotifier,
        builder: (context, setlists, _) {
          return ValueListenableBuilder<List<SetlistOptionDefinition>>(
            valueListenable: SetlistService.instance.optionsNotifier,
            builder: (context, options, _) {
              final showDate = SetlistService.instance.isOptionVisible('date');
              final showLocation = SetlistService.instance.isOptionVisible('location');

              final filtered = setlists.where((s) {
                final q = _searchQuery.toLowerCase();
                final titleMatch = s.title.toLowerCase().contains(q);
                final locMatch = s.location?.toLowerCase().contains(q) ?? false;
                return titleMatch || locMatch;
              }).toList();

              final upcomingList = filtered.where(SetlistService.instance.isUpcoming).toList();
              upcomingList.sort((a, b) => a.date.compareTo(b.date));

              final archivedList = filtered.where(SetlistService.instance.isArchived).toList();
              archivedList.sort((a, b) => b.date.compareTo(a.date));

              final displayList = _selectedTab == 0 ? upcomingList : archivedList;

              return Column(
                children: [
                  // Top Search and Create Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search, size: 18, color: colorScheme.secondary),
                              hintText: 'Search setlists, venues...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: colorScheme.secondary.withOpacity(0.6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              isDense: true,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: colorScheme.outline),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.onSurface,
                            foregroundColor: colorScheme.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'NEW SETLIST',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          onPressed: () => _openSetlistModal(context),
                        ),
                      ],
                    ),
                  ),

                  // Segmented Tabs: UPCOMING GIGS vs PAST SHOWS ARCHIVE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTab = 0;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? colorScheme.surfaceContainerHighest
                                    : colorScheme.surface,
                                border: Border.all(
                                  color: _selectedTab == 0
                                      ? colorScheme.onSurface
                                      : colorScheme.outline,
                                  width: _selectedTab == 0 ? 1.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'UPCOMING GIGS (${upcomingList.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w600,
                                    letterSpacing: 1.0,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTab = 1;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? colorScheme.surfaceContainerHighest
                                    : colorScheme.surface,
                                border: Border.all(
                                  color: _selectedTab == 1
                                      ? colorScheme.onSurface
                                      : colorScheme.outline,
                                  width: _selectedTab == 1 ? 1.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'PAST SHOWS (${archivedList.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w600,
                                    letterSpacing: 1.0,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Setlists List View
                  Expanded(
                    child: displayList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                _selectedTab == 0
                                    ? (_searchQuery.isEmpty
                                        ? 'No upcoming setlists.\nTap "+ NEW SETLIST" to prepare your next gig.'
                                        : 'No upcoming setlists match "$_searchQuery"')
                                    : (_searchQuery.isEmpty
                                        ? 'No completed gigs in archive yet.\nCompleted setlists will appear here.'
                                        : 'No archived setlists match "$_searchQuery"'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              left: 20.0,
                              right: 20.0,
                              top: 4.0,
                              bottom: 20.0 + MediaQuery.of(context).padding.bottom,
                            ),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              final item = displayList[index];
                              final durationMinutes = (item.songIds.length * 3.5).round();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colorScheme.outline, width: 1.0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Card Top Info
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
                                                        item.title,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                          color: colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      if (showDate || (showLocation && item.location != null && item.location!.isNotEmpty)) ...[
                                                        const SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            if (showDate) ...[
                                                              Icon(Icons.calendar_today_outlined, size: 12, color: colorScheme.secondary),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                _formatDate(item.date),
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: colorScheme.secondary,
                                                                ),
                                                              ),
                                                            ],
                                                            if (showDate && showLocation && item.location != null && item.location!.isNotEmpty) ...[
                                                              const SizedBox(width: 10),
                                                            ],
                                                            if (showLocation && item.location != null && item.location!.isNotEmpty) ...[
                                                              Icon(Icons.place_outlined, size: 13, color: colorScheme.secondary),
                                                              const SizedBox(width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  item.location!,
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    color: colorScheme.secondary,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(color: colorScheme.outline),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '${item.songIds.length} Songs • ~$durationMinutes min',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: colorScheme.onSurface,
                                                        ),
                                                      ),
                                                    ),
                                                    Builder(
                                                      builder: (context) {
                                                        final isArchived = SetlistService.instance.isArchived(item);
                                                        final isActiveGig = item.id == SetlistService.instance.activeSetlist?.id;

                                                        if (isActiveGig) {
                                                          return Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: colorScheme.onSurface,
                                                                borderRadius: BorderRadius.circular(3),
                                                              ),
                                                              child: Text(
                                                                'ACTIVE STAGE',
                                                                style: TextStyle(
                                                                  fontSize: 8.5,
                                                                  fontWeight: FontWeight.bold,
                                                                  letterSpacing: 0.5,
                                                                  color: colorScheme.surface,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        } else if (isArchived) {
                                                          return Padding(
                                                            padding: const EdgeInsets.only(top: 4.0),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: colorScheme.surfaceContainerHighest,
                                                                borderRadius: BorderRadius.circular(3),
                                                                border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                                                              ),
                                                              child: Text(
                                                                item.isCompleted ? 'COMPLETED' : 'DATE PASSED',
                                                                style: TextStyle(
                                                                  fontSize: 8.5,
                                                                  fontWeight: FontWeight.bold,
                                                                  letterSpacing: 0.5,
                                                                  color: colorScheme.secondary,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        return const SizedBox.shrink();
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Card Bottom Action Bar
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                                          border: Border(
                                            top: BorderSide(color: colorScheme.outline.withOpacity(0.6), width: 0.8),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: colorScheme.onSurface,
                                                  foregroundColor: colorScheme.surface,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                ),
                                                icon: const Icon(Icons.play_arrow, size: 16),
                                                label: const Text(
                                                  'STAGE VIEW',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) => StageViewScreen(setlist: item),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: colorScheme.onSurface,
                                                side: BorderSide(color: colorScheme.outline),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              ),
                                              icon: const Icon(Icons.edit_outlined, size: 15),
                                              label: const Text('EDIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              onPressed: () => _openSetlistModal(context, initialSetlist: item),
                                            ),
                                            const SizedBox(width: 4),
                                            Builder(
                                              builder: (context) {
                                                final isArchived = SetlistService.instance.isArchived(item);
                                                final isActiveGig = item.id == SetlistService.instance.activeSetlist?.id;

                                                return PopupMenuButton<String>(
                                                  icon: Icon(Icons.more_vert, size: 18, color: colorScheme.secondary),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    side: BorderSide(color: colorScheme.outline, width: 1.0),
                                                  ),
                                                  onSelected: (action) {
                                                    if (action == 'set_active') {
                                                      SetlistService.instance.setActiveSetlist(item.id);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Set "${item.title}" as active stage setlist.'),
                                                          duration: const Duration(seconds: 2),
                                                        ),
                                                      );
                                                    } else if (action == 'duplicate') {
                                                      final cloned = SetlistService.instance.duplicateSetlist(item.id);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Duplicated "${cloned.title}"'),
                                                          duration: const Duration(seconds: 2),
                                                        ),
                                                      );
                                                    } else if (action == 'toggle_archive') {
                                                      final willArchive = !isArchived;
                                                      SetlistService.instance.markSetlistCompleted(item.id, willArchive);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(willArchive
                                                              ? 'Moved "${item.title}" to Past Shows Archive'
                                                              : 'Reopened "${item.title}" to Upcoming Gigs (scheduled for Today)'),
                                                          duration: const Duration(seconds: 2),
                                                        ),
                                                      );
                                                    } else if (action == 'delete') {
                                                      _confirmDeleteSetlist(context, item);
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    if (!isArchived && !isActiveGig)
                                                      const PopupMenuItem(
                                                        value: 'set_active',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.star_outline, size: 16),
                                                            SizedBox(width: 10),
                                                            Text('Set as Active Setlist', style: TextStyle(fontSize: 13)),
                                                          ],
                                                        ),
                                                      ),
                                                    const PopupMenuItem(
                                                      value: 'duplicate',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.copy_outlined, size: 16),
                                                          SizedBox(width: 10),
                                                          Text('Duplicate Setlist', style: TextStyle(fontSize: 13)),
                                                        ],
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'toggle_archive',
                                                      child: Row(
                                                        children: [
                                                          Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 16),
                                                          const SizedBox(width: 10),
                                                          Text(isArchived ? 'Reopen (Move to Upcoming)' : 'Complete Show & Archive', style: const TextStyle(fontSize: 13)),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuDivider(),
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete_outline, size: 16),
                                                          SizedBox(width: 10),
                                                          Text('Delete Setlist', style: TextStyle(fontSize: 13)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CreateSetlistSheet extends StatefulWidget {
  final Setlist? initialSetlist;

  const _CreateSetlistSheet({this.initialSetlist});

  @override
  State<_CreateSetlistSheet> createState() => _CreateSetlistSheetState();
}

class _CreateSetlistSheetState extends State<_CreateSetlistSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late DateTime _selectedDate;
  final List<String> _selectedSongIds = [];

  bool get isEditing => widget.initialSetlist != null;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSetlist;
    _titleController = TextEditingController(text: s?.title ?? '');
    _locationController = TextEditingController(text: s?.location ?? '');
    _selectedDate = s?.date ?? DateTime.now();
    if (s != null) {
      _selectedSongIds.addAll(s.songIds);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.onSurface,
                  onPrimary: Theme.of(context).colorScheme.surface,
                  surface: Theme.of(context).cardColor,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _openSongPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;
        final allSongs = SongService.instance.songsNotifier.value;
        final tempSelected = List<String>.from(_selectedSongIds);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outline, width: 1.0),
              ),
              title: Text(
                'SELECT SONGS FOR SETLIST',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: colorScheme.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: allSongs.isEmpty
                    ? Text(
                        'No songs available in repertoire. Create a new song first.',
                        style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: allSongs.length,
                        itemBuilder: (context, idx) {
                          final song = allSongs[idx];
                          final isChecked = tempSelected.contains(song.id);

                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              song.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '${song.artist ?? "Unknown artist"}${song.musicalKey != null ? " • Key: ${song.musicalKey}" : ""}',
                              style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                            ),
                            value: isChecked,
                            activeColor: colorScheme.onSurface,
                            checkColor: colorScheme.surface,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  tempSelected.add(song.id);
                                } else {
                                  tempSelected.remove(song.id);
                                }
                              });
                            },
                          );
                        },
                      ),
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
                    setState(() {
                      _selectedSongIds.clear();
                      _selectedSongIds.addAll(tempSelected);
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('CONFIRM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _createNewSongDirectly(BuildContext context) {
    CreateSongSheet.show(
      context,
      onSongCreated: (newSong) {
        setState(() {
          if (!_selectedSongIds.contains(newSong.id)) {
            _selectedSongIds.add(newSong.id);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final allSongs = SongService.instance.songsNotifier.value;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'EDIT SETLIST' : 'NEW SETLIST',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isEditing
                    ? 'Update performance setlist, venue, and track order'
                    : 'Create a performance setlist with date, venue, and track order',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Title (Required)
              TextFormField(
                controller: _titleController,
                autofocus: !isEditing,
                decoration: InputDecoration(
                  labelText: 'Setlist Title *',
                  labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                  hintText: 'e.g. Summer Festival Night 1',
                  hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Setlist title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Date Picker Field
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Performance Date',
                                  style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.calendar_month_outlined, size: 18, color: colorScheme.secondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Location (Optional)
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location / Venue (Optional)',
                  labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                  hintText: 'e.g. The Fillmore • Main Stage',
                  hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              // Songs Header & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SONGS IN SETLIST (${_selectedSongIds.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(color: colorScheme.outline),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.library_add_outlined, size: 14),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'FROM LIBRARY',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onPressed: () => _openSongPicker(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(color: colorScheme.outline),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 14),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'CREATE NEW SONG',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onPressed: () => _createNewSongDirectly(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_selectedSongIds.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'No songs added to this setlist yet.\nTap "From Library" or "Create New Song" above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ...List.generate(_selectedSongIds.length, (idx) {
                  final id = _selectedSongIds[idx];
                  final song = allSongs.firstWhere(
                    (s) => s.id == id,
                    orElse: () => Song(id: id, title: 'Unknown Song', createdAt: DateTime.now()),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '#${idx + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (song.artist != null)
                                Text(
                                  song.artist!,
                                  style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                                ),
                            ],
                          ),
                        ),
                        // Move Up Button
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 16),
                          tooltip: 'Move up',
                          color: idx > 0 ? colorScheme.onSurface : colorScheme.outline.withOpacity(0.3),
                          onPressed: idx > 0
                              ? () {
                                  setState(() {
                                    final moved = _selectedSongIds.removeAt(idx);
                                    _selectedSongIds.insert(idx - 1, moved);
                                  });
                                }
                              : null,
                        ),
                        // Move Down Button
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          tooltip: 'Move down',
                          color: idx < _selectedSongIds.length - 1 ? colorScheme.onSurface : colorScheme.outline.withOpacity(0.3),
                          onPressed: idx < _selectedSongIds.length - 1
                              ? () {
                                  setState(() {
                                    final moved = _selectedSongIds.removeAt(idx);
                                    _selectedSongIds.insert(idx + 1, moved);
                                  });
                                }
                              : null,
                        ),
                        // Remove Button
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: 'Remove from setlist',
                          color: colorScheme.secondary,
                          onPressed: () {
                            setState(() {
                              _selectedSongIds.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.onSurface,
                    foregroundColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (isEditing) {
                        final updated = widget.initialSetlist!.copyWith(
                          title: _titleController.text.trim(),
                          date: _selectedDate,
                          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
                          songIds: _selectedSongIds,
                        );
                        SetlistService.instance.updateSetlist(updated);
                        Navigator.of(context).pop(updated);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated "${updated.title}"'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        final newSetlist = Setlist(
                          id: 'setlist_${DateTime.now().millisecondsSinceEpoch}',
                          title: _titleController.text.trim(),
                          date: _selectedDate,
                          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
                          songIds: _selectedSongIds,
                          isCompleted: false,
                          createdAt: DateTime.now(),
                        );

                        SetlistService.instance.addSetlist(newSetlist);
                        Navigator.of(context).pop(newSetlist);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Created "${newSetlist.title}"'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    isEditing ? 'UPDATE SETLIST' : 'SAVE SETLIST',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
