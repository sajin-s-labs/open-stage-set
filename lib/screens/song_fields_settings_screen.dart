import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/song_service.dart';

class SongFieldsSettingsScreen extends StatelessWidget {
  const SongFieldsSettingsScreen({super.key});

  void _showAddFieldDialog(BuildContext context) {
    final nameController = TextEditingController();
    final placeholderController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outline, width: 1.0),
          ),
          title: Text(
            'NEW SONG FIELD',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Define a custom attribute to track with your songs (e.g. Vocalist, Delay Time, Guitar Tuning).',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Field Name *',
                    labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                    hintText: 'e.g. Vocalist, Delay Preset',
                    hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a field name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: placeholderController,
                  decoration: InputDecoration(
                    labelText: 'Hint / Placeholder (Optional)',
                    labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                    hintText: 'e.g. John, Drop D, 420ms',
                    hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: colorScheme.secondary,
                  letterSpacing: 1.0,
                  fontSize: 12,
                ),
              ),
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
                if (formKey.currentState!.validate()) {
                  SongService.instance.addField(
                    nameController.text.trim(),
                    placeholder: placeholderController.text.trim(),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text(
                'CREATE FIELD',
                style: TextStyle(
                  letterSpacing: 1.0,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Settings',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('SONG FIELDS & OPTIONS'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            thickness: 1.0,
            color: theme.dividerColor,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<SongFieldDefinition>>(
        valueListenable: SongService.instance.fieldsNotifier,
        builder: (context, fields, _) {
          return ListView(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 24.0,
              bottom: 24.0 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              // Header Card with Action Button
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'FIELD VISIBILITY & CREATION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'NEW FIELD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          onPressed: () => _showAddFieldDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toggle fields below to show or hide them when creating or viewing songs. Hidden fields will not appear in the song creation form.',
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
                'ALL AVAILABLE SONG FIELDS (${fields.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),

              ...fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: field.isVisible ? colorScheme.outline : colorScheme.outline.withOpacity(0.4),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          field.isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                          color: field.isVisible ? colorScheme.onSurface : colorScheme.secondary.withOpacity(0.5),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    field.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: field.isVisible
                                          ? colorScheme.onSurface
                                          : colorScheme.secondary.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colorScheme.outline.withOpacity(0.5),
                                        width: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      field.isSystem ? 'CORE' : 'CUSTOM',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                field.isVisible ? 'Visible in song form & views' : 'Hidden from song form',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: field.isVisible,
                          activeColor: colorScheme.onSurface,
                          activeTrackColor: colorScheme.outline,
                          onChanged: (_) {
                            SongService.instance.toggleFieldVisibility(field.id);
                          },
                        ),
                        if (!field.isSystem) ...[
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: colorScheme.secondary,
                            tooltip: 'Delete field',
                            onPressed: () {
                              SongService.instance.deleteField(field.id);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
