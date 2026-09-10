import 'package:flutter/material.dart';
import '../models/setlist.dart';
import '../services/setlist_service.dart';

class SetlistSettingsScreen extends StatelessWidget {
  const SetlistSettingsScreen({super.key});

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
        title: const Text('SETLIST DISPLAY OPTIONS'),
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
          return ListView(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 24.0,
              bottom: 24.0 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STAGE DISPLAY VISIBILITY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose which metadata fields and indicators appear when viewing setlists. Customize your view for minimalist stage performance or detailed rehearsal references.',
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
                'FIELD & METADATA VISIBILITY (${options.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),

              ...options.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: option.isVisible ? colorScheme.outline : colorScheme.outline.withOpacity(0.4),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                          color: option.isVisible ? colorScheme.onSurface : colorScheme.secondary.withOpacity(0.5),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: option.isVisible
                                      ? colorScheme.onSurface
                                      : colorScheme.secondary.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                option.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: option.isVisible,
                          activeColor: colorScheme.onSurface,
                          activeTrackColor: colorScheme.outline,
                          onChanged: (_) {
                            SetlistService.instance.toggleOptionVisibility(option.id);
                          },
                        ),
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
