import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/song_service.dart';

class CreateSongSheet extends StatefulWidget {
  final Song? songToEdit;
  final ValueChanged<Song>? onSongCreated;
  final ValueChanged<Song>? onSongUpdated;

  const CreateSongSheet({
    super.key,
    this.songToEdit,
    this.onSongCreated,
    this.onSongUpdated,
  });

  static Future<Song?> show(
    BuildContext context, {
    Song? songToEdit,
    ValueChanged<Song>? onSongCreated,
    ValueChanged<Song>? onSongUpdated,
  }) {
    return showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => CreateSongSheet(
        songToEdit: songToEdit,
        onSongCreated: onSongCreated,
        onSongUpdated: onSongUpdated,
      ),
    );
  }

  @override
  State<CreateSongSheet> createState() => _CreateSongSheetState();
}

class _CreateSongSheetState extends State<CreateSongSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _keyController;
  late final TextEditingController _tempoController;
  final Map<String, TextEditingController> _customControllers = {};

  bool get isEditing => widget.songToEdit != null;

  @override
  void initState() {
    super.initState();
    final song = widget.songToEdit;
    _titleController = TextEditingController(text: song?.title ?? '');
    _artistController = TextEditingController(text: song?.artist ?? '');
    _keyController = TextEditingController(text: song?.musicalKey ?? '');
    _tempoController = TextEditingController(text: song?.tempo?.toString() ?? '');

    if (song != null) {
      final fields = SongService.instance.fieldsNotifier.value;
      for (final entry in song.customFields.entries) {
        final matchingField = fields.firstWhere(
          (f) => f.name.toLowerCase() == entry.key.toLowerCase() || f.id == entry.key,
          orElse: () => SongFieldDefinition(id: entry.key, name: entry.key),
        );
        _customControllers[matchingField.id] = TextEditingController(text: entry.value);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _keyController.dispose();
    _tempoController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ValueListenableBuilder<List<SongFieldDefinition>>(
      valueListenable: SongService.instance.fieldsNotifier,
      builder: (context, fields, _) {
        final visibleFields = fields.where((f) => f.isVisible).toList();

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
                        isEditing ? 'EDIT SONG' : 'NEW SONG',
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
                        ? 'Update song details, musical key, and attributes'
                        : 'Define song details and custom metadata',
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
                      labelText: 'Song Title *',
                      labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                      hintText: 'e.g. Heroes',
                      hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Song title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Author / Artist (if visible)
                  if (visibleFields.any((f) => f.id == 'author')) ...[
                    TextFormField(
                      controller: _artistController,
                      decoration: InputDecoration(
                        labelText: 'Author / Artist',
                        labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                        hintText: 'e.g. David Bowie',
                        hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Musical Key & Tempo row (if visible)
                  if (visibleFields.any((f) => f.id == 'key') || visibleFields.any((f) => f.id == 'tempo')) ...[
                    Row(
                      children: [
                        if (visibleFields.any((f) => f.id == 'key'))
                          Expanded(
                            child: TextFormField(
                              controller: _keyController,
                              decoration: InputDecoration(
                                labelText: 'Musical Key',
                                labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                                hintText: 'e.g. G Maj, Em, D',
                                hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
                              ),
                            ),
                          ),
                        if (visibleFields.any((f) => f.id == 'key') && visibleFields.any((f) => f.id == 'tempo'))
                          const SizedBox(width: 12),
                        if (visibleFields.any((f) => f.id == 'tempo'))
                          Expanded(
                            child: TextFormField(
                              controller: _tempoController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Tempo (BPM)',
                                labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                                hintText: 'e.g. 120',
                                hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Custom Fields (if visible)
                  ...visibleFields.where((f) => f.id != 'author' && f.id != 'key' && f.id != 'tempo').map((field) {
                    _customControllers.putIfAbsent(field.id, () => TextEditingController());
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: TextFormField(
                        controller: _customControllers[field.id],
                        decoration: InputDecoration(
                          labelText: field.name,
                          labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                          hintText: field.placeholder.isEmpty ? 'Enter ${field.name.toLowerCase()}' : field.placeholder,
                          hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
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
                          final customValues = <String, String>{};
                          for (final entry in _customControllers.entries) {
                            if (entry.value.text.trim().isNotEmpty) {
                              final fieldDef = fields.firstWhere(
                                (f) => f.id == entry.key,
                                orElse: () => SongFieldDefinition(id: entry.key, name: entry.key),
                              );
                              customValues[fieldDef.name] = entry.value.text.trim();
                            }
                          }

                          final int? tempoParsed = int.tryParse(_tempoController.text.trim());

                          if (isEditing) {
                            final updatedSong = widget.songToEdit!.copyWith(
                              title: _titleController.text.trim(),
                              artist: _artistController.text.trim().isEmpty ? null : _artistController.text.trim(),
                              musicalKey: _keyController.text.trim().isEmpty ? null : _keyController.text.trim(),
                              tempo: tempoParsed,
                              customFields: customValues,
                            );

                            SongService.instance.updateSong(updatedSong);
                            widget.onSongUpdated?.call(updatedSong);
                            Navigator.of(context).pop(updatedSong);
                          } else {
                            final newSong = Song(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              title: _titleController.text.trim(),
                              artist: _artistController.text.trim().isEmpty ? null : _artistController.text.trim(),
                              musicalKey: _keyController.text.trim().isEmpty ? null : _keyController.text.trim(),
                              tempo: tempoParsed,
                              customFields: customValues,
                              createdAt: DateTime.now(),
                            );

                            SongService.instance.addSong(newSong);
                            widget.onSongCreated?.call(newSong);
                            Navigator.of(context).pop(newSong);
                          }
                        }
                      },
                      child: Text(
                        isEditing ? 'UPDATE SONG' : 'SAVE SONG',
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
      },
    );
  }
}
