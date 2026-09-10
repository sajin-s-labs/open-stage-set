import 'package:flutter/material.dart';
import '../services/audio_synth.dart';
import '../services/audio_synth_service.dart';

class PianoRollScreen extends StatefulWidget {
  const PianoRollScreen({super.key});

  @override
  State<PianoRollScreen> createState() => _PianoRollScreenState();
}

class _PianoRollScreenState extends State<PianoRollScreen> {
  String _selectedRoot = 'C';
  String _selectedQuality = 'Major';
  int _baseOctave = 3; // Starts at C3 (MIDI 48)

  int? _activePressedMidi;

  ChordInfo get _currentChord => MusicTheory.buildChord(_selectedRoot, _selectedQuality, octave: _baseOctave + 1);

  void _playKey(int midi) {
    setState(() {
      _activePressedMidi = midi;
    });
    AudioSynthesizer.instance.playMidiNote(midi, durationSeconds: 1.0, volume: 0.4);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _activePressedMidi == midi) {
        setState(() {
          _activePressedMidi = null;
        });
      }
    });
  }

  void _playCurrentChord() {
    AudioSynthesizer.instance.playChord(_currentChord.midiNotes, durationSeconds: 1.6, volume: 0.35);
  }

  Future<void> _playCurrentArpeggio() async {
    await AudioSynthesizer.instance.playArpeggio(
      _currentChord.midiNotes,
      delayMs: 130,
      durationSeconds: 1.2,
      volume: 0.35,
    );
  }

  /// Get role label for a MIDI note within the current chord
  String? _getRoleInChord(int midi) {
    final rootMidi = MusicTheory.getMidiForNote(_selectedRoot, _baseOctave + 1);
    final interval = (midi - rootMidi) % 12;
    final normalizedInterval = interval >= 0 ? interval : interval + 12;

    switch (normalizedInterval) {
      case 0:
        return 'R';
      case 4:
        return '3';
      case 3:
        return '♭3';
      case 7:
        return '5';
      case 6:
        return '♭5';
      case 8:
        return '♯5';
      case 10:
        return '♭7';
      case 11:
        return '7';
      case 5:
        return '4';
      case 2:
        return _selectedQuality == 'Add9' ? '9' : '2';
      default:
        return null;
    }
  }

  bool _isNoteInChord(int midi) {
    return _currentChord.midiNotes.contains(midi);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chord = _currentChord;

    // 2 Octaves: 14 white keys
    // White key semitone offsets from C: [0, 2, 4, 5, 7, 9, 11]
    const whiteSemitones = [0, 2, 4, 5, 7, 9, 11];
    final whiteNotesList = <_KeyModel>[];

    final startMidi = 12 * (_baseOctave + 1); // C3 = 48 if baseOctave=3

    // Build 14 white keys (2 octaves)
    for (int oct = 0; oct < 2; oct++) {
      for (int i = 0; i < whiteSemitones.length; i++) {
        final midi = startMidi + (oct * 12) + whiteSemitones[i];
        final name = MusicTheory.chromaticNotes[midi % 12];
        whiteNotesList.add(_KeyModel(
          midi: midi,
          name: name,
          isBlack: false,
          octave: (midi ~/ 12) - 1,
        ));
      }
    }

    // Black keys offsets that exist after white keys:
    // C#(1), D#(3), none after E(4), F#(6), G#(8), A#(10), none after B(11)
    const blackKeyRelativeIndex = [0, 1, 3, 4, 5]; // White key indexes that have black key to their right

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Chord Helper',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('PIANO ROLL & CHORD KEYBED'),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note_outlined),
            tooltip: 'Arpeggiate Chord',
            onPressed: _playCurrentArpeggio,
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Play Chord',
            onPressed: _playCurrentChord,
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
          left: 20.0,
          right: 20.0,
          top: 20.0,
          bottom: 24.0 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          // 1. Chord Selector Strip
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline, width: 1.0),
              borderRadius: BorderRadius.circular(10.0),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROOT NOTE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: colorScheme.secondary),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedRoot,
                        isDense: true,
                        isExpanded: true,
                        dropdownColor: colorScheme.surface,
                        underline: const SizedBox(),
                        items: MusicTheory.chromaticNotes.map((r) {
                          return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontWeight: FontWeight.bold)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRoot = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHORD QUALITY',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: colorScheme.secondary),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedQuality,
                        isDense: true,
                        isExpanded: true,
                        dropdownColor: colorScheme.surface,
                        underline: const SizedBox(),
                        items: MusicTheory.chordIntervals.keys.map((q) {
                          return DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontWeight: FontWeight.bold)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedQuality = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Active Chord Notes & Play Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 430;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline, width: 1.0),
                  borderRadius: BorderRadius.circular(10.0),
                  color: colorScheme.surface,
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chord.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Notes: ${chord.noteNames.join(" - ")}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.secondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: colorScheme.outline),
                                    foregroundColor: colorScheme.onSurface,
                                  ),
                                  icon: const Icon(Icons.music_note, size: 16),
                                  label: const Text('ARPEGGIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  onPressed: _playCurrentArpeggio,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.onSurface,
                                    foregroundColor: colorScheme.surface,
                                  ),
                                  icon: const Icon(Icons.volume_up, size: 16),
                                  label: const Text('PLAY CHORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  onPressed: _playCurrentChord,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chord.name,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Notes: ${chord.noteNames.join(" - ")}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.secondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: colorScheme.outline),
                                  foregroundColor: colorScheme.onSurface,
                                ),
                                icon: const Icon(Icons.music_note, size: 16),
                                label: const Text('ARPEGGIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                onPressed: _playCurrentArpeggio,
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.onSurface,
                                  foregroundColor: colorScheme.surface,
                                ),
                                icon: const Icon(Icons.volume_up, size: 16),
                                label: const Text('PLAY CHORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                onPressed: _playCurrentChord,
                              ),
                            ],
                          ),
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. Interactive 2-Octave Keyboard
          Text(
            'INTERACTIVE PIANO KEYBED (2 OCTAVES)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.grey.shade700, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final whiteKeyWidth = totalWidth / 14;
                final blackKeyWidth = whiteKeyWidth * 0.65;
                const blackKeyHeight = 115.0;

                return Stack(
                  children: [
                    // Layer 1: White Keys
                    Row(
                      children: List.generate(whiteNotesList.length, (i) {
                        final keyData = whiteNotesList[i];
                        final inChord = _isNoteInChord(keyData.midi);
                        final isPressed = _activePressedMidi == keyData.midi;
                        final role = _getRoleInChord(keyData.midi);

                        return Expanded(
                          child: InkWell(
                            onTap: () => _playKey(keyData.midi),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: isPressed
                                    ? const Color(0xFFD4D4D8)
                                    : inChord
                                        ? const Color(0xFFEDEDED)
                                        : Colors.white,
                                border: Border(
                                  right: BorderSide(color: Colors.grey.shade400, width: 1.0),
                                  bottom: BorderSide(color: Colors.grey.shade400, width: 2.0),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (inChord && role != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        role,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    keyData.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    // Layer 2: Black Keys
                    ...List.generate(2, (oct) {
                      return blackKeyRelativeIndex.map((relIdx) {
                        final whiteIdx = oct * 7 + relIdx;
                        final blackMidi = whiteNotesList[whiteIdx].midi + 1;
                        final inChord = _isNoteInChord(blackMidi);
                        final isPressed = _activePressedMidi == blackMidi;
                        final role = _getRoleInChord(blackMidi);
                        final noteName = MusicTheory.chromaticNotes[blackMidi % 12];

                        final leftPosition = (whiteIdx + 1) * whiteKeyWidth - (blackKeyWidth / 2);

                        return Positioned(
                          left: leftPosition,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => _playKey(blackMidi),
                            child: Container(
                              width: blackKeyWidth,
                              height: blackKeyHeight,
                              decoration: BoxDecoration(
                                color: isPressed
                                    ? Colors.grey.shade600
                                    : inChord
                                        ? const Color(0xFF4B5563)
                                        : const Color(0xFF1E1E1E),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                                border: Border.all(
                                  color: inChord ? Colors.white : Colors.black,
                                  width: inChord ? 1.5 : 0.8,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (inChord && role != null)
                                    Text(
                                      role,
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  Text(
                                    noteName,
                                    style: const TextStyle(fontSize: 8, color: Colors.white70),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ),
                        );
                      });
                    }).expand((e) => e),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Octave Controller Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OCTAVE RANGE: C$_baseOctave TO B${_baseOctave + 1}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.secondary),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    tooltip: 'Octave Down',
                    onPressed: _baseOctave > 1
                        ? () {
                            setState(() {
                              _baseOctave--;
                            });
                          }
                        : null,
                  ),
                  Text('Octave $_baseOctave', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: 'Octave Up',
                    onPressed: _baseOctave < 5
                        ? () {
                            setState(() {
                              _baseOctave++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyModel {
  final int midi;
  final String name;
  final bool isBlack;
  final int octave;

  const _KeyModel({
    required this.midi,
    required this.name,
    required this.isBlack,
    required this.octave,
  });
}
