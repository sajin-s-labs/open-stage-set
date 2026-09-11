import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/audio_synth.dart';
import '../services/audio_synth_service.dart';

class CircleOfFifthsScreen extends StatefulWidget {
  const CircleOfFifthsScreen({super.key});

  @override
  State<CircleOfFifthsScreen> createState() => _CircleOfFifthsScreenState();
}

class _CircleOfFifthsScreenState extends State<CircleOfFifthsScreen> {
  // 12 Major keys around the circle in clockwise order of 5ths
  static const List<_CircleKeyData> _circleData = [
    _CircleKeyData(major: 'C', minor: 'Am', accidentals: 'No ♯ / ♭', sharpsCount: 0),
    _CircleKeyData(major: 'G', minor: 'Em', accidentals: '1 Sharp (F♯)', sharpsCount: 1),
    _CircleKeyData(major: 'D', minor: 'Bm', accidentals: '2 Sharps (F♯, C♯)', sharpsCount: 2),
    _CircleKeyData(major: 'A', minor: 'F#m', accidentals: '3 Sharps (F♯, C♯, G♯)', sharpsCount: 3),
    _CircleKeyData(major: 'E', minor: 'C#m', accidentals: '4 Sharps (F♯, C♯, G♯, D♯)', sharpsCount: 4),
    _CircleKeyData(major: 'B', minor: 'G#m', accidentals: '5 Sharps (F♯, C♯, G♯, D♯, A♯)', sharpsCount: 5),
    _CircleKeyData(major: 'F#', minor: 'D#m', accidentals: '6 Sharps / 6 Flats', sharpsCount: 6),
    _CircleKeyData(major: 'Db', minor: 'Bbm', accidentals: '5 Flats (B♭, E♭, A♭, D♭, G♭)', sharpsCount: -5),
    _CircleKeyData(major: 'Ab', minor: 'Fm', accidentals: '4 Flats (B♭, E♭, A♭, D♭)', sharpsCount: -4),
    _CircleKeyData(major: 'Eb', minor: 'Cm', accidentals: '3 Flats (B♭, E♭, A♭)', sharpsCount: -3),
    _CircleKeyData(major: 'Bb', minor: 'Gm', accidentals: '2 Flats (B♭, E♭)', sharpsCount: -2),
    _CircleKeyData(major: 'F', minor: 'Dm', accidentals: '1 Flat (B♭)', sharpsCount: -1),
  ];

  int _selectedIndex = 0; // Starts at 'C'
  int _cadenceAudioToken = 0;

  @override
  void dispose() {
    _cadenceAudioToken++;
    super.dispose();
  }

  void _playChordByName(String chordName, String quality) {
    String cleanRoot = chordName.replaceAll('♯', '#').replaceAll('♭', 'b').trim();
    if (cleanRoot.length > 1 && cleanRoot.endsWith('m') && !cleanRoot.endsWith('dim')) {
      cleanRoot = cleanRoot.substring(0, cleanRoot.length - 1);
    }
    final chord = MusicTheory.buildChord(cleanRoot, quality);
    AudioSynthesizer.instance.playChord(chord.midiNotes, durationSeconds: 1.5, volume: 0.35);
  }

  Future<void> _playCadence() async {
    final token = ++_cadenceAudioToken;
    final data = _circleData[_selectedIndex];
    final subdominant = _circleData[(_selectedIndex - 1 + 12) % 12].major;
    final dominant = _circleData[(_selectedIndex + 1) % 12].major;
    final tonic = data.major;

    final chords = [
      MusicTheory.buildChord(tonic, 'Major'),
      MusicTheory.buildChord(subdominant, 'Major'),
      MusicTheory.buildChord(dominant, 'Major'),
      MusicTheory.buildChord(tonic, 'Major'),
    ];

    for (final chord in chords) {
      if (token != _cadenceAudioToken || !mounted) return;
      AudioSynthesizer.instance.playChord(chord.midiNotes, durationSeconds: 1.2, volume: 0.35);
      await Future.delayed(const Duration(milliseconds: 650));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentKey = _circleData[_selectedIndex];

    // Neighbor calculations on the wheel (Cluster of 6 Diatonic Chords)
    final subdominantIndex = (_selectedIndex - 1 + 12) % 12;
    final dominantIndex = (_selectedIndex + 1) % 12;
    final subdominantKey = _circleData[subdominantIndex];
    final dominantKey = _circleData[dominantIndex];
    final supertonicMinor = subdominantKey.minor; // ii: rel. minor of IV (e.g. Dm in key of C)
    final mediantMinor = dominantKey.minor;       // iii: rel. minor of V (e.g. Em in key of C)

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Chord Helper',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('CIRCLE OF FIFTHS & HARMONY GUIDE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Play I - IV - V - I Cadence',
            onPressed: _playCadence,
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
      body: ListView(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 24.0 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          // ==============================================================
          // 1. INTERACTIVE CIRCLE-BASED WHEEL AT TOP
          // ==============================================================
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline, width: 1.0),
              borderRadius: BorderRadius.circular(10.0),
              color: colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'INTERACTIVE CIRCLE OF FIFTHS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'CLOCKWISE: +5th (♯)',
                        style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Outer Ring: Major Keys • Inner Ring: Relative Minors • Tap nodes to audition & select',
                  style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Harmonic Function Legend
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildLegendItem('I (Tonic)', colorScheme.onSurface, colorScheme.surface, isSolid: true),
                    _buildLegendItem('IV (Subdominant)', colorScheme.surfaceContainerHighest, colorScheme.onSurface),
                    _buildLegendItem('V (Dominant)', colorScheme.surfaceContainerHighest, colorScheme.onSurface),
                    _buildLegendItem('vi (Rel. Minor)', colorScheme.surfaceContainerHighest, colorScheme.onSurface),
                  ],
                ),
                const SizedBox(height: 16),

                // Dynamic Responsive Circular Wheel
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxAvailableWidth = constraints.maxWidth;
                    final wheelSize = maxAvailableWidth.clamp(260.0, 360.0);
                    final scale = wheelSize / 340.0;
                    final centerCoord = wheelSize / 2;

                    final rMajor = 136.0 * scale;
                    final rMinor = 86.0 * scale;
                    final majorBtnWidth = 42.0 * scale;
                    final majorBtnHeight = 36.0 * scale;
                    final minorBtnWidth = 38.0 * scale;
                    final minorBtnHeight = 30.0 * scale;
                    final hubDiameter = 116.0 * scale;

                    return Center(
                      child: SizedBox(
                        width: wheelSize,
                        height: wheelSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Canvas Background Rings & Harmonic Wedges
                            CustomPaint(
                              size: Size(wheelSize, wheelSize),
                              painter: _CircleOfFifthsWheelBackgroundPainter(
                                outlineColor: colorScheme.outline,
                                surfaceColor: colorScheme.surface,
                                surfaceContainerColor: colorScheme.surfaceContainerHighest,
                                onSurfaceColor: colorScheme.onSurface,
                                selectedIndex: _selectedIndex,
                                scale: scale,
                              ),
                            ),

                            // 2. Outer Ring: 12 Major Key Nodes
                            ...List.generate(12, (idx) {
                              final item = _circleData[idx];
                              final angle = -math.pi / 2 + (idx * (math.pi / 6));
                              final x = centerCoord + (rMajor * math.cos(angle)) - (majorBtnWidth / 2);
                              final y = centerCoord + (rMajor * math.sin(angle)) - (majorBtnHeight / 2);

                              final isSelected = _selectedIndex == idx;
                              final isSubdominant = subdominantIndex == idx;
                              final isDominant = dominantIndex == idx;

                              String? roleBadge;
                              if (isSelected) {
                                roleBadge = 'I';
                              } else if (isSubdominant) {
                                roleBadge = 'IV';
                              } else if (isDominant) {
                                roleBadge = 'V';
                              }

                              return Positioned(
                                left: x,
                                top: y,
                                width: majorBtnWidth,
                                height: majorBtnHeight,
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedIndex = idx);
                                    _playChordByName(item.major, 'Major');
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.onSurface
                                          : (isSubdominant || isDominant)
                                              ? colorScheme.surfaceContainerHighest.withOpacity(0.8)
                                              : colorScheme.surface,
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.surface
                                            : (isSubdominant || isDominant)
                                                ? colorScheme.onSurface
                                                : colorScheme.outline,
                                        width: isSelected ? 1.8 : 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              item.major,
                                              style: TextStyle(
                                                fontSize: (12.0 * scale).clamp(10.0, 14.0),
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? colorScheme.surface : colorScheme.onSurface,
                                              ),
                                            ),
                                            if (roleBadge != null)
                                              Text(
                                                roleBadge,
                                                style: TextStyle(
                                                  fontSize: (8.0 * scale).clamp(6.5, 9.5),
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.2,
                                                  color: isSelected
                                                      ? colorScheme.surface.withOpacity(0.9)
                                                      : colorScheme.secondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // 3. Inner Ring: 12 Relative Minor Key Nodes
                            ...List.generate(12, (idx) {
                              final item = _circleData[idx];
                              final angle = -math.pi / 2 + (idx * (math.pi / 6));
                              final x = centerCoord + (rMinor * math.cos(angle)) - (minorBtnWidth / 2);
                              final y = centerCoord + (rMinor * math.sin(angle)) - (minorBtnHeight / 2);

                              final isRelMinorOfSelected = _selectedIndex == idx;

                              return Positioned(
                                left: x,
                                top: y,
                                width: minorBtnWidth,
                                height: minorBtnHeight,
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedIndex = idx);
                                    _playChordByName(item.minor, 'Minor');
                                  },
                                  borderRadius: BorderRadius.circular(5),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    decoration: BoxDecoration(
                                      color: isRelMinorOfSelected
                                          ? colorScheme.surfaceContainerHighest
                                          : colorScheme.surface.withOpacity(0.9),
                                      border: Border.all(
                                        color: isRelMinorOfSelected
                                            ? colorScheme.onSurface
                                            : colorScheme.outline.withOpacity(0.5),
                                        width: isRelMinorOfSelected ? 1.4 : 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              item.minor,
                                              style: TextStyle(
                                                fontSize: (9.5 * scale).clamp(8.0, 11.0),
                                                fontWeight: isRelMinorOfSelected ? FontWeight.bold : FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            if (isRelMinorOfSelected)
                                              Text(
                                                'vi',
                                                style: TextStyle(
                                                  fontSize: (7.5 * scale).clamp(6.0, 8.5),
                                                  fontWeight: FontWeight.w900,
                                                  color: colorScheme.secondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // 4. Center Hub: Active Key Readout & Tap-to-Audition
                            Positioned(
                              width: hubDiameter,
                              height: hubDiameter,
                              child: InkWell(
                                onTap: _playCadence,
                                borderRadius: BorderRadius.circular(hubDiameter / 2),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.surface,
                                    border: Border.all(color: colorScheme.outline, width: 1.4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadow.withOpacity(0.12),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(6 * scale),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'KEY OF',
                                            style: TextStyle(
                                              fontSize: (8.0 * scale).clamp(7.0, 9.0),
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                          Text(
                                            currentKey.major,
                                            style: TextStyle(
                                              fontSize: (22.0 * scale).clamp(16.0, 24.0),
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            'rel. ${currentKey.minor}',
                                            style: TextStyle(
                                              fontSize: (9.0 * scale).clamp(7.5, 10.5),
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                          SizedBox(height: 2 * scale),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 2 * scale),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: colorScheme.outline.withOpacity(0.6), width: 0.6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.volume_up, size: (10.0 * scale).clamp(8.0, 12.0), color: colorScheme.onSurface),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'CADENCE',
                                                  style: TextStyle(
                                                    fontSize: (7.5 * scale).clamp(6.5, 8.5),
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
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==============================================================
          // 2. QUICK KEY SELECTOR GRID (PRESENT AS WELL)
          // ==============================================================
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline, width: 1.0),
              borderRadius: BorderRadius.circular(10.0),
              color: colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'KEY SELECTOR GRID',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '12 TONAL CENTERS',
                        style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 12-key Grid arranged sequentially around the 5ths circle
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _circleData.length,
                  itemBuilder: (context, idx) {
                    final item = _circleData[idx];
                    final isSelected = _selectedIndex == idx;
                    final isSubdominant = subdominantIndex == idx;
                    final isDominant = dominantIndex == idx;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = idx;
                        });
                        _playChordByName(item.major, 'Major');
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.surfaceContainerHighest
                              : isSubdominant || isDominant
                                  ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                                  : colorScheme.surface,
                          border: Border.all(
                            color: isSelected ? colorScheme.onSurface : colorScheme.outline,
                            width: isSelected ? 2.0 : 0.8,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.major,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  item.minor,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Active Key Information Strip
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 430;
                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KEY OF ${currentKey.major} MAJOR (${currentKey.minor})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Key Signature: ${currentKey.accidentals}',
                                style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colorScheme.outline),
                              foregroundColor: colorScheme.onSurface,
                            ),
                            icon: const Icon(Icons.volume_up_outlined, size: 16),
                            label: const Text('HEAR CADENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            onPressed: _playCadence,
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KEY OF ${currentKey.major} MAJOR (${currentKey.minor})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Key Signature: ${currentKey.accidentals}',
                                style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colorScheme.outline),
                            foregroundColor: colorScheme.onSurface,
                          ),
                          icon: const Icon(Icons.volume_up_outlined, size: 16),
                          label: const Text('HEAR CADENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          onPressed: _playCadence,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ==============================================================
          // 3. DIATONIC FAMILY OF CHORDS (PRIMARY & SECONDARY TRIADS)
          // ==============================================================
          Text(
            'DIATONIC CHORDS IN ${currentKey.major} MAJOR',
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
                child: _ChordFamilyCard(
                  roman: 'I',
                  title: 'TONIC',
                  chordName: currentKey.major,
                  quality: 'Major',
                  description: 'Home base / resolution',
                  onPlay: () => _playChordByName(currentKey.major, 'Major'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChordFamilyCard(
                  roman: 'IV',
                  title: 'SUBDOMINANT',
                  chordName: subdominantKey.major,
                  quality: 'Major',
                  description: 'Energy lift / moving away',
                  onPlay: () => _playChordByName(subdominantKey.major, 'Major'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChordFamilyCard(
                  roman: 'V',
                  title: 'DOMINANT',
                  chordName: dominantKey.major,
                  quality: 'Major',
                  description: 'Maximum tension / pull to I',
                  onPlay: () => _playChordByName(dominantKey.major, 'Major'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _ChordFamilyCard(
                  roman: 'vi',
                  title: 'REL. MINOR',
                  chordName: currentKey.minor,
                  quality: 'Minor',
                  description: 'Deceptive cadence / emotion',
                  onPlay: () => _playChordByName(currentKey.minor, 'Minor'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChordFamilyCard(
                  roman: 'ii',
                  title: 'SUPERTONIC',
                  chordName: supertonicMinor,
                  quality: 'Minor',
                  description: 'Smooth setup before V',
                  onPlay: () => _playChordByName(supertonicMinor, 'Minor'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChordFamilyCard(
                  roman: 'iii',
                  title: 'MEDIANT',
                  chordName: mediantMinor,
                  quality: 'Minor',
                  description: 'Soft passing bridge',
                  onPlay: () => _playChordByName(mediantMinor, 'Minor'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ==============================================================
          // 4. HOW TO USE THE CIRCLE OF FIFTHS MASTER GUIDE
          // ==============================================================
          Text(
            'HOW TO USE THE CIRCLE OF FIFTHS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 10),

          const _GuideExpansionTile(
            title: '1. Finding Key Signatures & Accidentals',
            content: 'Starting at C (top = 0 accidentals):\n'
                '• Move CLOCKWISE (right): Add 1 Sharp (#) for each step (G=1, D=2, A=3, E=4, B=5, F#=6).\n'
                '• Move COUNTER-CLOCKWISE (left): Add 1 Flat (b) for each step (F=1, Bb=2, Eb=3, Ab=4, Db=5).\n'
                'Order of Sharps: F - C - G - D - A - E - B\n'
                'Order of Flats: B - E - A - D - G - C - F',
          ),
          const _GuideExpansionTile(
            title: '2. The 3-Chord Wonder Rule (I - IV - V)',
            content: 'Any three adjacent keys on the wheel form the primary triads of a major key:\n'
                '• Center = Tonic (I)\n'
                '• Counter-clockwise neighbor = Subdominant (IV)\n'
                '• Clockwise neighbor = Dominant (V)\n'
                'These three chords are sufficient to accompany hundreds of classic rock, folk, blues, and pop anthems.',
          ),
          const _GuideExpansionTile(
            title: '3. Relative Minors',
            content: 'Every Major key shares the exact same notes and key signature with its Relative Minor:\n'
                '• C Major shares notes with A Minor\n'
                '• G Major shares notes with E Minor\n'
                '• F Major shares notes with D Minor\n'
                'If a song feels too bright, substituting a chord with its relative minor instantly introduces introspective mood.',
          ),
          const _GuideExpansionTile(
            title: '4. Flawless Key Modulation on Stage',
            content: 'Adjacent keys on the wheel share 6 out of 7 scale notes. When writing a bridge or key change:\n'
                '• Modulate to an adjacent key (e.g. C to G or C to F) for an effortless, natural shift.\n'
                '• Modulate across the circle (e.g. C to F#) for an explosive, dramatic contrast.',
          ),
          const _GuideExpansionTile(
            title: '5. Borrowing Chords (Modal Interchange)',
            content: 'Borrow chords from the parallel minor to create instant emotional tension:\n'
                '• In C Major: Borrow Fm (iv) from C Minor for a bittersweet resolution into C.\n'
                '• Borrow Bb (bVII) for that unmistakable classic rock guitar anthem drive.',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bg, Color text, {bool isSolid = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.outline, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}

/// Custom painter that renders concentric circular tracks, spoke dividers, and harmonic function highlight arcs
class _CircleOfFifthsWheelBackgroundPainter extends CustomPainter {
  final Color outlineColor;
  final Color surfaceColor;
  final Color surfaceContainerColor;
  final Color onSurfaceColor;
  final int selectedIndex;
  final double scale;

  _CircleOfFifthsWheelBackgroundPainter({
    required this.outlineColor,
    required this.surfaceColor,
    required this.surfaceContainerColor,
    required this.onSurfaceColor,
    required this.selectedIndex,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final rOuter = r - (4 * scale);
    final rMid = 110.0 * scale;
    final rHub = 57.0 * scale;

    final linePaint = Paint()
      ..color = outlineColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw active key sector wedges behind I, IV, V
    const sectorAngle = math.pi / 6; // 30 degrees
    const halfSector = math.pi / 12; // 15 degrees

    final ivIdx = (selectedIndex - 1 + 12) % 12;
    final vIdx = (selectedIndex + 1) % 12;

    for (final idx in [ivIdx, selectedIndex, vIdx]) {
      final angle = -math.pi / 2 + (idx * sectorAngle);
      final startAngle = angle - halfSector;
      final path = Path()
        ..moveTo(center.dx + rHub * math.cos(startAngle), center.dy + rHub * math.sin(startAngle))
        ..lineTo(center.dx + rOuter * math.cos(startAngle), center.dy + rOuter * math.sin(startAngle))
        ..arcToPoint(
          Offset(center.dx + rOuter * math.cos(startAngle + sectorAngle), center.dy + rOuter * math.sin(startAngle + sectorAngle)),
          radius: Radius.circular(rOuter),
        )
        ..lineTo(
          center.dx + rHub * math.cos(startAngle + sectorAngle),
          center.dy + rHub * math.sin(startAngle + sectorAngle),
        )
        ..arcToPoint(
          Offset(center.dx + rHub * math.cos(startAngle), center.dy + rHub * math.sin(startAngle)),
          radius: Radius.circular(rHub),
          clockwise: false,
        )
        ..close();

      if (idx == selectedIndex) {
        canvas.drawPath(
          path,
          Paint()
            ..color = onSurfaceColor.withOpacity(0.08)
            ..style = PaintingStyle.fill,
        );
      } else {
        canvas.drawPath(
          path,
          Paint()
            ..color = surfaceContainerColor.withOpacity(0.35)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Concentric circular guides
    canvas.drawCircle(center, rOuter, linePaint);
    canvas.drawCircle(
      center,
      rMid,
      Paint()
        ..color = outlineColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.drawCircle(
      center,
      rHub,
      Paint()
        ..color = outlineColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Subtle spoke dividers between sectors
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 - halfSector + (i * sectorAngle);
      final p1 = Offset(center.dx + rHub * math.cos(angle), center.dy + rHub * math.sin(angle));
      final p2 = Offset(center.dx + rOuter * math.cos(angle), center.dy + rOuter * math.sin(angle));
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = outlineColor.withOpacity(0.18)
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleOfFifthsWheelBackgroundPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.scale != scale ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}

class _CircleKeyData {
  final String major;
  final String minor;
  final String accidentals;
  final int sharpsCount;

  const _CircleKeyData({
    required this.major,
    required this.minor,
    required this.accidentals,
    required this.sharpsCount,
  });
}

class _ChordFamilyCard extends StatelessWidget {
  final String roman;
  final String title;
  final String chordName;
  final String quality;
  final String description;
  final VoidCallback onPlay;

  const _ChordFamilyCard({
    required this.roman,
    required this.title,
    required this.chordName,
    required this.quality,
    required this.description,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  roman,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary,
                  ),
                ),
                Icon(Icons.volume_up_outlined, size: 14, color: colorScheme.secondary),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                chordName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 8,
                color: colorScheme.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideExpansionTile extends StatelessWidget {
  final String title;
  final String content;

  const _GuideExpansionTile({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withOpacity(0.6), width: 0.8),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 14.0),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
