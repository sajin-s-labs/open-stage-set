import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/image_utils.dart';

class _ImagePreset {
  final String label;
  final String title;
  final bool isMonochrome;
  final String url;

  const _ImagePreset({
    required this.label,
    required this.title,
    required this.isMonochrome,
    required this.url,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bandController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _bgUrlController;
  late TextEditingController _instrumentInputController;
  late List<String> _instruments;

  // Theme-adaptive image settings
  late bool _dynamicThemeImages;
  late TextEditingController _darkAvatarController;
  late TextEditingController _grayscaleAvatarController;
  late TextEditingController _lightAvatarController;
  late TextEditingController _darkBgController;
  late TextEditingController _grayscaleBgController;
  late TextEditingController _lightBgController;

  // Selected tab for editing theme-specific images: 0=Dark, 1=Grayscale, 2=Light
  int _selectedThemeSlot = 0;

  // Mode used in the Live Preview
  AppThemeMode _previewMode = AppTheme.currentThemeMode.value;

  // 2 Monochrome Presets and 2 Color Presets for Profile Avatars
  static const List<_ImagePreset> _presetAvatars = [
    _ImagePreset(
      label: 'MONO 1',
      title: 'Acoustic B&W',
      isMonochrome: true,
      url: 'assets/images/presets/avatar_mono_1.jpg',
    ),
    _ImagePreset(
      label: 'MONO 2',
      title: 'Stage Electric B&W',
      isMonochrome: true,
      url: 'assets/images/presets/avatar_mono_2.jpg',
    ),
    _ImagePreset(
      label: 'COLOR 1',
      title: 'Warm Stage Lights',
      isMonochrome: false,
      url: 'assets/images/presets/avatar_color_1.jpg',
    ),
    _ImagePreset(
      label: 'COLOR 2',
      title: 'Neon Studio Sound',
      isMonochrome: false,
      url: 'assets/images/presets/avatar_color_2.jpg',
    ),
  ];

  // 2 Monochrome Presets and 2 Color Presets for Background Banners
  static const List<_ImagePreset> _presetBackgrounds = [
    _ImagePreset(
      label: 'MONO 1',
      title: 'Stage Shadows B&W',
      isMonochrome: true,
      url: 'assets/images/presets/bg_mono_1.jpg',
    ),
    _ImagePreset(
      label: 'MONO 2',
      title: 'Arena Lights B&W',
      isMonochrome: true,
      url: 'assets/images/presets/bg_mono_2.jpg',
    ),
    _ImagePreset(
      label: 'COLOR 1',
      title: 'Amber Stage Glow',
      isMonochrome: false,
      url: 'assets/images/presets/bg_color_1.jpg',
    ),
    _ImagePreset(
      label: 'COLOR 2',
      title: 'Neon Synth Studio',
      isMonochrome: false,
      url: 'assets/images/presets/bg_color_2.jpg',
    ),
  ];

  static const List<String> _commonInstruments = [
    'Lead Guitar',
    'Rhythm Guitar',
    'Acoustic Guitar',
    'Bass Guitar',
    'Synthesizer',
    'Piano / Keys',
    'Drums / Percussion',
    'Lead Vocals',
    'Backing Vocals',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ProfileService.instance.profileNotifier.value;
    _nameController = TextEditingController(text: profile.name);
    _bandController = TextEditingController(text: profile.bandName);
    _avatarUrlController = TextEditingController(text: profile.avatarUrl ?? '');
    _bgUrlController = TextEditingController(text: profile.backgroundUrl ?? '');
    _instrumentInputController = TextEditingController();
    _instruments = List<String>.from(profile.instruments);

    _dynamicThemeImages = profile.dynamicThemeImages;
    _darkAvatarController = TextEditingController(
      text: profile.darkAvatarUrl ?? _presetAvatars[0].url,
    );
    _grayscaleAvatarController = TextEditingController(
      text: profile.grayscaleAvatarUrl ?? _presetAvatars[1].url,
    );
    _lightAvatarController = TextEditingController(
      text: profile.lightAvatarUrl ?? _presetAvatars[2].url,
    );
    _darkBgController = TextEditingController(
      text: profile.darkBackgroundUrl ?? _presetBackgrounds[0].url,
    );
    _grayscaleBgController = TextEditingController(
      text: profile.grayscaleBackgroundUrl ?? _presetBackgrounds[1].url,
    );
    _lightBgController = TextEditingController(
      text: profile.lightBackgroundUrl ?? _presetBackgrounds[2].url,
    );

    _previewMode = AppTheme.currentThemeMode.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bandController.dispose();
    _avatarUrlController.dispose();
    _bgUrlController.dispose();
    _instrumentInputController.dispose();

    _darkAvatarController.dispose();
    _grayscaleAvatarController.dispose();
    _lightAvatarController.dispose();
    _darkBgController.dispose();
    _grayscaleBgController.dispose();
    _lightBgController.dispose();
    super.dispose();
  }

  void _addInstrument(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_instruments.contains(trimmed)) {
      setState(() {
        _instruments.add(trimmed);
        _instrumentInputController.clear();
      });
    }
  }

  void _removeInstrument(String name) {
    setState(() {
      _instruments.remove(name);
    });
  }

  Future<void> _pickLocalImage(ValueChanged<String> onSelected) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          // Create an isolated byte-level copy directly into internal application storage
          final storageUri = AppStorageService.instance.storeCopiedFile(
            originalName: file.name,
            bytes: file.bytes!,
            extension: file.extension,
          );
          setState(() {
            onSelected(storageUri);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Copied "${file.name}" to App Storage'),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updated = UserProfile(
        name: _nameController.text.trim(),
        bandName: _bandController.text.trim(),
        instruments: _instruments,
        avatarUrl: _avatarUrlController.text.trim().isEmpty ? null : _avatarUrlController.text.trim(),
        backgroundUrl: _bgUrlController.text.trim().isEmpty ? null : _bgUrlController.text.trim(),
        dynamicThemeImages: _dynamicThemeImages,
        darkAvatarUrl: _darkAvatarController.text.trim().isEmpty ? null : _darkAvatarController.text.trim(),
        grayscaleAvatarUrl: _grayscaleAvatarController.text.trim().isEmpty ? null : _grayscaleAvatarController.text.trim(),
        lightAvatarUrl: _lightAvatarController.text.trim().isEmpty ? null : _lightAvatarController.text.trim(),
        darkBackgroundUrl: _darkBgController.text.trim().isEmpty ? null : _darkBgController.text.trim(),
        grayscaleBackgroundUrl: _grayscaleBgController.text.trim().isEmpty ? null : _grayscaleBgController.text.trim(),
        lightBackgroundUrl: _lightBgController.text.trim().isEmpty ? null : _lightBgController.text.trim(),
      );
      ProfileService.instance.updateProfile(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  String? _getPreviewAvatar() {
    if (_dynamicThemeImages) {
      switch (_previewMode) {
        case AppThemeMode.oledDark:
          return _darkAvatarController.text.trim().isNotEmpty
              ? _darkAvatarController.text.trim()
              : _avatarUrlController.text.trim();
        case AppThemeMode.grayscale:
          return _grayscaleAvatarController.text.trim().isNotEmpty
              ? _grayscaleAvatarController.text.trim()
              : _avatarUrlController.text.trim();
        case AppThemeMode.light:
          return _lightAvatarController.text.trim().isNotEmpty
              ? _lightAvatarController.text.trim()
              : _avatarUrlController.text.trim();
      }
    }
    return _avatarUrlController.text.trim();
  }

  String? _getPreviewBackground() {
    if (_dynamicThemeImages) {
      switch (_previewMode) {
        case AppThemeMode.oledDark:
          return _darkBgController.text.trim().isNotEmpty
              ? _darkBgController.text.trim()
              : _bgUrlController.text.trim();
        case AppThemeMode.grayscale:
          return _grayscaleBgController.text.trim().isNotEmpty
              ? _grayscaleBgController.text.trim()
              : _bgUrlController.text.trim();
        case AppThemeMode.light:
          return _lightBgController.text.trim().isNotEmpty
              ? _lightBgController.text.trim()
              : _bgUrlController.text.trim();
      }
    }
    return _bgUrlController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveAvatarUrl = _getPreviewAvatar();
    final effectiveBgUrl = _getPreviewBackground();
    final avatarProvider = getAppImageProvider(effectiveAvatarUrl);
    final bgProvider = getAppImageProvider(effectiveBgUrl);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('MUSICIAN PROFILE'),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text(
              'SAVE',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            onPressed: _saveProfile,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 24.0,
            bottom: 24.0 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            // Header with Live Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LIVE PREVIEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: colorScheme.secondary,
                  ),
                ),
                if (_dynamicThemeImages) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'DYNAMIC THEME ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Theme Switcher for Live Preview (When dynamic theme is on)
            if (_dynamicThemeImages) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline, width: 0.8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Preview In Theme: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        children: [
                          _buildPreviewChip(
                            label: 'OLED DARK',
                            mode: AppThemeMode.oledDark,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(width: 6),
                          _buildPreviewChip(
                            label: 'GRAYSCALE',
                            mode: AppThemeMode.grayscale,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(width: 6),
                          _buildPreviewChip(
                            label: 'LIGHT',
                            mode: AppThemeMode.light,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Live Preview Card
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline, width: 1.0),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Background Header Banner
                  Container(
                    height: 96,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      image: bgProvider != null
                          ? DecorationImage(
                              image: bgProvider,
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.55),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                    ),
                    child: bgProvider == null
                        ? Center(
                            child: Icon(
                              Icons.music_note,
                              size: 32,
                              color: colorScheme.secondary.withOpacity(0.3),
                            ),
                          )
                        : null,
                  ),

                  // Avatar & Details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -28),
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 2.5),
                              color: colorScheme.surfaceContainerHighest,
                              image: avatarProvider != null
                                  ? DecorationImage(
                                      image: avatarProvider,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: avatarProvider == null
                                ? Icon(Icons.person, size: 28, color: colorScheme.onSurface)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_bandController.text.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _bandController.text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_instruments.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 14.0),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _instruments.map((inst) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              inst,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 1. Basic Details
            Text(
              'BASIC DETAILS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 14),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Musician / Artist Name *',
                labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                hintText: 'e.g. Alex Mercer',
                hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
              ),
              onChanged: (_) => setState(() {}),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Band Name Field
            TextFormField(
              controller: _bandController,
              decoration: InputDecoration(
                labelText: 'Band / Group Name',
                labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                hintText: 'e.g. Orbit Collective',
                hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 28),

            // 2. Instruments Section
            Text(
              'INSTRUMENTS PLAYED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add the instruments and gear you perform with on stage.',
              style: TextStyle(fontSize: 12, color: colorScheme.secondary),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _instrumentInputController,
                    decoration: InputDecoration(
                      labelText: 'Add Instrument',
                      labelStyle: TextStyle(color: colorScheme.secondary, fontSize: 13),
                      hintText: 'e.g. Electric Guitar, MIDI Controller',
                      hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.5), fontSize: 12),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.outline)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5)),
                    ),
                    onSubmitted: _addInstrument,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: colorScheme.onSurface,
                  tooltip: 'Add',
                  onPressed: () => _addInstrument(_instrumentInputController.text),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _commonInstruments.map((inst) {
                final isAdded = _instruments.contains(inst);
                return ActionChip(
                  label: Text(
                    inst,
                    style: TextStyle(
                      fontSize: 11,
                      color: isAdded ? colorScheme.surface : colorScheme.onSurface,
                    ),
                  ),
                  backgroundColor: isAdded ? colorScheme.onSurface : colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onPressed: () {
                    if (isAdded) {
                      _removeInstrument(inst);
                    } else {
                      _addInstrument(inst);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // 3. Theme-Adaptive Option Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _dynamicThemeImages ? colorScheme.onSurface : colorScheme.outline,
                  width: _dynamicThemeImages ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(10),
                color: _dynamicThemeImages
                    ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                    : Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tonality,
                        size: 20,
                        color: _dynamicThemeImages ? colorScheme.onSurface : colorScheme.secondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHANGE IMAGES BASED ON THEME',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Profile images automatically switch when toggling OLED Dark, Grayscale, or Light theme.',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _dynamicThemeImages,
                        activeColor: colorScheme.onSurface,
                        onChanged: (val) {
                          setState(() {
                            _dynamicThemeImages = val;
                          });
                        },
                      ),
                    ],
                  ),

                  if (_dynamicThemeImages) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Theme Slot Selector
                    Text(
                      'CONFIGURE IMAGES FOR EACH THEME:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _buildSlotTab(0, 'OLED DARK', colorScheme),
                        const SizedBox(width: 8),
                        _buildSlotTab(1, 'GRAYSCALE', colorScheme),
                        const SizedBox(width: 8),
                        _buildSlotTab(2, 'LIGHT', colorScheme),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Active Theme Slot Editor
                    _buildActiveSlotEditor(colorScheme),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 4. Default / Fixed Images Section
            Text(
              _dynamicThemeImages ? 'DEFAULT / FALLBACK IMAGES' : 'PROFILE & BANNER IMAGES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select from 2 Monochrome and 2 Color presets, or upload directly from your local device.',
              style: TextStyle(fontSize: 12, color: colorScheme.secondary),
            ),
            const SizedBox(height: 16),

            // Profile Avatar Editor
            _buildImagePickerBlock(
              title: 'Profile Avatar Image',
              controller: _avatarUrlController,
              presets: _presetAvatars,
              colorScheme: colorScheme,
              isAvatar: true,
            ),
            const SizedBox(height: 24),

            // Background Banner Editor
            _buildImagePickerBlock(
              title: 'Background Banner Image',
              controller: _bgUrlController,
              presets: _presetBackgrounds,
              colorScheme: colorScheme,
              isAvatar: false,
            ),
            const SizedBox(height: 32),

            // Save Button
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
                onPressed: _saveProfile,
                child: const Text(
                  'SAVE PROFILE',
                  style: TextStyle(
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
    );
  }

  Widget _buildPreviewChip({
    required String label,
    required AppThemeMode mode,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _previewMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _previewMode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? colorScheme.onSurface : colorScheme.outline,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isSelected ? colorScheme.surface : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotTab(int index, String title, ColorScheme colorScheme) {
    final isSelected = _selectedThemeSlot == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedThemeSlot = index;
            if (index == 0) _previewMode = AppThemeMode.oledDark;
            if (index == 1) _previewMode = AppThemeMode.grayscale;
            if (index == 2) _previewMode = AppThemeMode.light;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.onSurface : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? colorScheme.onSurface : colorScheme.outline,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: isSelected ? colorScheme.surface : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSlotEditor(ColorScheme colorScheme) {
    TextEditingController activeAvatarCtrl;
    TextEditingController activeBgCtrl;
    String slotName;

    switch (_selectedThemeSlot) {
      case 0:
        activeAvatarCtrl = _darkAvatarController;
        activeBgCtrl = _darkBgController;
        slotName = 'OLED Dark Theme';
        break;
      case 1:
        activeAvatarCtrl = _grayscaleAvatarController;
        activeBgCtrl = _grayscaleBgController;
        slotName = 'Grayscale Theme';
        break;
      case 2:
      default:
        activeAvatarCtrl = _lightAvatarController;
        activeBgCtrl = _lightBgController;
        slotName = 'Light Theme';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EDITING: $slotName',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Auto-activates with theme',
                style: TextStyle(fontSize: 10, color: colorScheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildImagePickerBlock(
            title: '$slotName Avatar',
            controller: activeAvatarCtrl,
            presets: _presetAvatars,
            colorScheme: colorScheme,
            isAvatar: true,
          ),
          const SizedBox(height: 16),
          _buildImagePickerBlock(
            title: '$slotName Banner',
            controller: activeBgCtrl,
            presets: _presetBackgrounds,
            colorScheme: colorScheme,
            isAvatar: false,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerBlock({
    required String title,
    required TextEditingController controller,
    required List<_ImagePreset> presets,
    required ColorScheme colorScheme,
    required bool isAvatar,
  }) {
    final currentValue = controller.text.trim();
    final hasCustom = currentValue.isNotEmpty;
    final isAppStorage = currentValue.startsWith('app_storage://');
    final isLocalAsset = currentValue.startsWith('assets/');
    final isDataUri = currentValue.startsWith('data:image');
    final isLocal = isAppStorage || isLocalAsset || isDataUri;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (isLocal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colorScheme.outline, width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAppStorage
                          ? Icons.inventory_2_outlined
                          : isLocalAsset
                              ? Icons.photo_library_outlined
                              : Icons.folder_open,
                      size: 11,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAppStorage
                          ? 'COPIED TO APP STORAGE'
                          : isLocalAsset
                              ? 'LOCAL PRESET ASSET'
                              : 'LOCAL FILE LOADED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (isAppStorage) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outline.withOpacity(0.4), width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 12, color: colorScheme.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Stored copy: ${AppStorageService.instance.getDisplayName(currentValue)} (isolated from host path)',
                    style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 6),

        // Action Row: Upload local file or Clear
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  side: BorderSide(color: colorScheme.outline),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.file_upload_outlined, size: 16),
                label: const Text(
                  'UPLOAD LOCAL IMAGE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                onPressed: () => _pickLocalImage((uri) {
                  controller.text = uri;
                }),
              ),
            ),
            if (hasCustom) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.secondary,
                  side: BorderSide(color: colorScheme.outline),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    controller.clear();
                  });
                },
                child: const Text('CLEAR', style: TextStyle(fontSize: 11)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Preset Chips Row: 2 Monochrome and 2 Color
        Text(
          'Preset Options (2 Monochrome, 2 Color):',
          style: TextStyle(fontSize: 10, color: colorScheme.secondary),
        ),
        const SizedBox(height: 6),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            final isSelected = controller.text.trim() == preset.url;
            return InkWell(
              onTap: () {
                setState(() {
                  controller.text = preset.url;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? colorScheme.onSurface : colorScheme.outline,
                    width: isSelected ? 2.0 : 0.8,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: isSelected ? colorScheme.surfaceContainerHighest : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAvatar)
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: getAppImageProvider(preset.url),
                      )
                    else
                      Container(
                        width: 32,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          image: DecorationImage(
                            image: getAppImageProvider(preset.url)!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: preset.isMonochrome
                                ? colorScheme.secondary
                                : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          preset.title,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
