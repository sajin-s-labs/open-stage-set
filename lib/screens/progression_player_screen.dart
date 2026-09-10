import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_synth.dart';
import '../services/audio_synth_service.dart';
import '../widgets/app_drawer.dart';

// =======================================================================
// MODELS
// =======================================================================

/// Represents a distinct section of a song (e.g. Intro, Verse, Chorus, Bridge)
class SongSection {
  String id;
  String name;
  List<ChordInfo> chords;
  int repeatCount; // Number of times this section repeats during song playback

  SongSection({
    required this.id,
    required this.name,
    required this.chords,
    this.repeatCount = 1,
  });

  SongSection copyWith({
    String? name,
    List<ChordInfo>? chords,
    int? repeatCount,
  }) {
    return SongSection(
      id: id,
      name: name ?? this.name,
      chords: chords ?? chords?.map((c) => c.copyWith()).toList() ?? this.chords,
      repeatCount: repeatCount ?? this.repeatCount,
    );
  }
}

/// Representation of a progression preset in the library
class ProgressionPreset {
  final String title;
  final String topic;
  final String subtopic;
  final int chordCount;
  final String timeSignature;
  final int defaultBpm;
  final int beatsPerChord;
  final String drumPattern;
  final String arpeggioStyle;
  final List<ChordInfo> chords;
  final String description;

  const ProgressionPreset({
    required this.title,
    required this.topic,
    required this.subtopic,
    required this.chordCount,
    required this.timeSignature,
    required this.defaultBpm,
    required this.beatsPerChord,
    this.drumPattern = 'Basic Rock',
    this.arpeggioStyle = 'Pad',
    required this.chords,
    required this.description,
  });
}

/// Representation of an intelligent next chord recommendation
class ChordRecommendation {
  final ChordInfo chord;
  final String role; // e.g. 'V7 (Dominant 7th)', 'IV (Subdominant)'
  final String category; // 'Resolutions & Cadences', 'Natural Flow', 'Emotional & Borrowed', 'Secondary Dominants', 'Color & Extensions'
  final String explanation;
  final String badge;

  const ChordRecommendation({
    required this.chord,
    required this.role,
    required this.category,
    required this.explanation,
    required this.badge,
  });
}

// =======================================================================
// MAIN SCREEN WIDGET
// =======================================================================

class ProgressionPlayerScreen extends StatefulWidget {
  const ProgressionPlayerScreen({super.key});

  @override
  State<ProgressionPlayerScreen> createState() => _ProgressionPlayerScreenState();
}

class _ProgressionPlayerScreenState extends State<ProgressionPlayerScreen> {
  // Song Sections Architecture
  final List<SongSection> _sections = [];
  int _activeSectionIndex = 0;
  int _selectedChordIndex = 0; // Currently focused chord for diagram inspection

  // Playback & Sequencer state
  bool _isPlaying = false;
  bool _playFullSong = false; // false = Loop Active Section, true = Sequential Song
  bool _isLooping = true;
  int _playbackSectionIndex = 0;
  int _playbackChordIndex = 0;
  int _playbackSectionIteration = 0;
  int _currentBeatInMeasure = 0;
  int _currentBeatInChord = 0;
  Timer? _playbackTimer;

  // Master Transport & Groove Controls
  double _bpm = 110.0;
  String _timeSignature = '4/4';
  int _beatsPerMeasure = 4;
  String _voicingPattern = 'Pad';
  String _drumPattern = 'Basic Rock';
  double _drumVolume = 0.35;

  // Chord Inspector Tab: 'piano' | 'guitar' | 'theory'
  String _inspectorTab = 'piano';
  int? _activePressedMidi;

  // Transition audition token to cancel pending delayed playback if a new chord is triggered
  int _transitionAudioToken = 0;

  /// Effective Root / Tonic Chord of the current section or song
  ChordInfo get _effectiveRootChord {
    if (_currentSection.chords.isNotEmpty) {
      return _currentSection.chords.first;
    }
    for (final sec in _sections) {
      if (sec.chords.isNotEmpty) {
        return sec.chords.first;
      }
    }
    return MusicTheory.buildChord('C', 'Major');
  }

  void _playKey(int midi) {
    setState(() {
      _activePressedMidi = midi;
    });
    _synth.playMidiNote(midi, durationSeconds: 0.8, volume: 0.4);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && _activePressedMidi == midi) {
        setState(() {
          _activePressedMidi = null;
        });
      }
    });
  }

  // Synth reference
  final AudioSynthesizer _synth = AudioSynthesizer.instance;

  // Helper shortcut to build chords
  static ChordInfo _c(String root, String quality, {int beats = 4, bool isPassing = false, String? bass}) {
    return MusicTheory.buildChord(root, quality, beats: beats, isPassing: isPassing, bassNote: bass);
  }

  @override
  void initState() {
    super.initState();
    _initDefaultSong();
  }

  @override
  void dispose() {
    _transitionAudioToken++;
    _stopPlayback();
    super.dispose();
  }

  /// Initial default song template: Intro, Verse, Chorus, Bridge
  void _initDefaultSong() {
    _sections.clear();
    _sections.addAll([
      SongSection(
        id: 'intro',
        name: 'Intro',
        repeatCount: 1,
        chords: [
          _c('C', 'Maj7', beats: 4),
          _c('A', 'm7', beats: 4),
          _c('F', 'Maj7', beats: 4),
          _c('G', '7th', beats: 4),
        ],
      ),
      SongSection(
        id: 'verse',
        name: 'Verse',
        repeatCount: 2,
        chords: [
          _c('C', 'Major', beats: 4),
          _c('G', 'Major', beats: 4),
          _c('A', 'Minor', beats: 4),
          _c('F', 'Major', beats: 4),
          _c('C', 'Major', beats: 4),
          _c('G', 'Major', beats: 4),
          _c('D', 'Minor', beats: 2),
          _c('G', '7th', beats: 2),
        ],
      ),
      SongSection(
        id: 'chorus',
        name: 'Chorus',
        repeatCount: 2,
        chords: [
          _c('F', 'Major', beats: 4),
          _c('G', 'Major', beats: 4),
          _c('E', 'Minor', beats: 4),
          _c('A', 'Minor', beats: 4),
          _c('D', 'Minor', beats: 4),
          _c('G', '7th', beats: 2),
          _c('G', '7b9', beats: 2, isPassing: true),
          _c('C', 'Major', beats: 4),
        ],
      ),
      SongSection(
        id: 'bridge',
        name: 'Bridge',
        repeatCount: 1,
        chords: [
          _c('D', 'm7', beats: 4),
          _c('G', '7th', beats: 4),
          _c('E', 'm7', beats: 4),
          _c('A', '7alt', beats: 2, isPassing: true),
          _c('A', '7th', beats: 2),
          _c('D', 'm7', beats: 4),
          _c('G', '7sus4', beats: 2),
          _c('G', '7th', beats: 2),
        ],
      ),
    ]);
    _activeSectionIndex = 1; // Default to verse
    _selectedChordIndex = 0;
  }

  SongSection get _currentSection {
    if (_activeSectionIndex < 0 || _activeSectionIndex >= _sections.length) {
      if (_sections.isEmpty) {
        _sections.add(SongSection(id: 'section_1', name: 'Section 1', chords: [_c('C', 'Major')]));
      }
      _activeSectionIndex = 0;
    }
    return _sections[_activeSectionIndex];
  }

  ChordInfo? get _selectedChord {
    final chords = _currentSection.chords;
    if (chords.isEmpty) return null;
    if (_selectedChordIndex < 0 || _selectedChordIndex >= chords.length) {
      _selectedChordIndex = 0;
    }
    return chords[_selectedChordIndex];
  }

  // =======================================================================
  // TRANSPORT & SEQUENCER ENGINE
  // =======================================================================

  void _togglePlay() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _stopPlayback() {
    _transitionAudioToken++;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentBeatInMeasure = 0;
        _currentBeatInChord = 0;
      });
    }
  }

  void _startPlayback() {
    if (_currentSection.chords.isEmpty && !_playFullSong) return;
    if (_sections.isEmpty) return;

    _playbackTimer?.cancel();

    setState(() {
      _isPlaying = true;
      _currentBeatInMeasure = 0;
      _currentBeatInChord = 0;
      if (_playFullSong) {
        _playbackSectionIndex = 0;
        _playbackChordIndex = 0;
        _playbackSectionIteration = 0;
      } else {
        _playbackSectionIndex = _activeSectionIndex;
        _playbackChordIndex = 0;
        _playbackSectionIteration = 0;
      }
    });

    // Execute first beat immediately
    _onSequencerTick();

    final intervalMs = (60000.0 / _bpm).round();
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _onSequencerTick();
    });
  }

  void _onSequencerTick() {
    if (!mounted) return;

    final targetSection = _playFullSong
        ? _sections[_playbackSectionIndex]
        : _sections[_activeSectionIndex];

    if (targetSection.chords.isEmpty) {
      _stopPlayback();
      return;
    }

    if (_playbackChordIndex >= targetSection.chords.length) {
      _playbackChordIndex = 0;
    }

    final currentChord = targetSection.chords[_playbackChordIndex];

    // 1. Play drums if pattern is active
    if (_drumPattern != 'Off') {
      _triggerDrumForBeat(_currentBeatInMeasure, _beatsPerMeasure, _drumPattern, _drumVolume);
    }

    // 2. Play chord harmonic accompaniment according to voicing pattern & chord beat
    _triggerVoicing(currentChord, _currentBeatInChord, _voicingPattern);

    // 3. Update active UI pointer and advance beats
    setState(() {
      _selectedChordIndex = _playbackChordIndex;
      _activeSectionIndex = _playbackSectionIndex;

      _currentBeatInMeasure = (_currentBeatInMeasure + 1) % _beatsPerMeasure;
      _currentBeatInChord++;

      // Check if chord duration in beats has elapsed
      if (_currentBeatInChord >= currentChord.beats) {
        _currentBeatInChord = 0;
        _playbackChordIndex++;

        // Check if section completed
        if (_playbackChordIndex >= targetSection.chords.length) {
          _playbackChordIndex = 0;

          if (_playFullSong) {
            _playbackSectionIteration++;
            if (_playbackSectionIteration >= targetSection.repeatCount) {
              _playbackSectionIteration = 0;
              _playbackSectionIndex++;

              // Check if entire song completed
              if (_playbackSectionIndex >= _sections.length) {
                if (_isLooping) {
                  _playbackSectionIndex = 0;
                } else {
                  _stopPlayback();
                  return;
                }
              }
            }
          } else {
            // Loop Section Mode
            if (!_isLooping) {
              _stopPlayback();
              return;
            }
          }
        }
      }
    });
  }

  /// Accompaniment voicing engine
  void _triggerVoicing(ChordInfo chord, int beatInChord, String pattern) {
    final notes = chord.midiNotes;
    if (notes.isEmpty) return;

    final beatSec = 60.0 / _bpm;

    switch (pattern) {
      case 'Pad':
        // Sustained warm polyphonic chord on beat 0
        if (beatInChord == 0) {
          _synth.playChord(notes, durationSeconds: beatSec * chord.beats.clamp(1, 8), volume: 0.32);
        }
        break;

      case 'Strummed Roll':
        // Strum roll across strings on beat 0, with subtle restrike if chord is 4+ beats
        if (beatInChord == 0 || (chord.beats >= 4 && beatInChord == 2)) {
          _synth.playArpeggio(notes, delayMs: 22, durationSeconds: beatSec * 1.8, volume: 0.28);
        }
        break;

      case 'Arpeggio Up ▲':
        // Step ascending through notes
        final noteIdx = beatInChord % notes.length;
        _synth.playMidiNote(notes[noteIdx], durationSeconds: beatSec * 1.5, volume: 0.35);
        break;

      case 'Arpeggio Down ▼':
        // Step descending through notes
        final noteIdx = (notes.length - 1) - (beatInChord % notes.length);
        _synth.playMidiNote(notes[noteIdx], durationSeconds: beatSec * 1.5, volume: 0.35);
        break;

      case 'Arpeggio Sweep ▲▼':
        final cycleLen = (notes.length * 2) - 2;
        int idx = beatInChord % (cycleLen > 0 ? cycleLen : 1);
        if (idx >= notes.length) {
          idx = cycleLen - idx;
        }
        _synth.playMidiNote(notes[idx.clamp(0, notes.length - 1)], durationSeconds: beatSec * 1.5, volume: 0.35);
        break;

      case 'Fingerpick (P-I-M-A)':
        // Acoustic fingerstyle: Low Bass Root on 0, then middle/high notes
        if (beatInChord == 0) {
          _synth.playMidiNote(notes.first, durationSeconds: beatSec * 2.2, volume: 0.42); // Bass
        } else {
          final upperNotes = notes.length > 1 ? notes.sublist(1) : notes;
          final note = upperNotes[(beatInChord - 1) % upperNotes.length];
          _synth.playMidiNote(note, durationSeconds: beatSec * 1.2, volume: 0.30);
        }
        break;

      case 'Piano Comp (Boom-Chick)':
        // Bass root on 0 & 2, syncopated chord stab on 1 & 3
        if (beatInChord % 2 == 0) {
          _synth.playMidiNote(notes.first, durationSeconds: beatSec * 1.2, volume: 0.42);
        } else {
          final upperNotes = notes.length > 1 ? notes.sublist(1) : notes;
          _synth.playChord(upperNotes, durationSeconds: beatSec * 0.7, volume: 0.28);
        }
        break;

      case 'Pulse 8ths':
      default:
        // Pumping chord hits
        _synth.playChord(notes, durationSeconds: beatSec * 0.85, volume: 0.30);
        break;
    }
  }

  /// Drum rhythm engine
  void _triggerDrumForBeat(int beat, int totalBeats, String pattern, double volume) {
    if (volume <= 0.01) return;

    switch (pattern) {
      case 'Metronome':
        if (beat == 0) {
          _synth.playDrum('click_accent', volume: volume);
        } else {
          _synth.playDrum('click_regular', volume: volume * 0.7);
        }
        break;

      case 'Basic Rock':
        // Kick on 1 & 3, Snare on 2 & 4
        if (beat == 0 || beat == 2) {
          _synth.playDrum('kick', volume: volume * 0.9);
        } else if (beat == 1 || beat == 3) {
          _synth.playDrum('snare', volume: volume * 0.85);
        }
        _synth.playDrum('hihat', volume: volume * 0.4);
        break;

      case 'Four-on-the-Floor':
        // Kick on every beat, Snare on 2 & 4
        _synth.playDrum('kick', volume: volume * 0.9);
        if (beat % 2 == 1) {
          _synth.playDrum('snare', volume: volume * 0.75);
        }
        _synth.playDrum('hihat', volume: volume * 0.45);
        break;

      case 'Half-Time':
        // Kick on 1, Snare on 3
        if (beat == 0) {
          _synth.playDrum('kick', volume: volume * 0.95);
        } else if (beat == 2) {
          _synth.playDrum('snare', volume: volume * 0.9);
        }
        _synth.playDrum('hihat', volume: volume * 0.4);
        break;

      case 'Ballad Waltz (3/4)':
        // Kick on 1, Hihat/Rim on 2 & 3
        if (beat == 0) {
          _synth.playDrum('kick', volume: volume * 0.9);
        } else {
          _synth.playDrum('hihat', volume: volume * 0.6);
        }
        break;

      case '6/8 Slow Jam':
        // Kick on 1, Snare on 4 in 6/8
        if (beat == 0) {
          _synth.playDrum('kick', volume: volume * 0.95);
        } else if (beat == 3) {
          _synth.playDrum('snare', volume: volume * 0.85);
        }
        _synth.playDrum('hihat', volume: volume * 0.35);
        break;

      case 'Jazz Swing':
        if (beat == 0 || beat == 2) {
          _synth.playDrum('kick', volume: volume * 0.5);
        }
        _synth.playDrum('hihat', volume: volume * 0.7);
        break;

      case 'Funk & R&B':
        if (beat == 0) {
          _synth.playDrum('kick', volume: volume);
        } else if (beat == 1 || beat == 3) {
          _synth.playDrum('snare', volume: volume * 0.85);
        } else if (beat == 2) {
          _synth.playDrum('kick', volume: volume * 0.7);
        }
        _synth.playDrum('hihat', volume: volume * 0.45);
        break;

      case 'Latin Bossa':
        if (beat == 0 || beat == 3) {
          _synth.playDrum('kick', volume: volume * 0.8);
        }
        if (beat == 1 || beat == 2) {
          _synth.playDrum('click_regular', volume: volume * 0.6);
        }
        _synth.playDrum('hihat', volume: volume * 0.35);
        break;
    }
  }

  void _playSingleChord(ChordInfo chord) {
    _transitionAudioToken++;
    _synth.playChord(chord.midiNotes, durationSeconds: 1.8, volume: 0.35);
  }

  Future<void> _playChordTransition(ChordInfo first, ChordInfo second) async {
    final token = ++_transitionAudioToken;
    _synth.playChord(first.midiNotes, durationSeconds: 0.95, volume: 0.34);
    await Future.delayed(const Duration(milliseconds: 650));
    if (token != _transitionAudioToken || !mounted) return;
    _synth.playChord(second.midiNotes, durationSeconds: 1.4, volume: 0.38);
  }

  // =======================================================================
  // SECTION & CHORD MUTATIONS
  // =======================================================================

  void _addSectionDialog() {
    final textController = TextEditingController(text: 'Section ${_sections.length + 1}');
    int repeats = 1;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('New Song Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Section Name:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Intro, Verse 2, Pre-Chorus, Solo',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Common Section Names:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['Intro', 'Verse', 'Pre-Chorus', 'Chorus', 'Bridge', 'Solo', 'Outro'].map((presetName) {
                    return InkWell(
                      onTap: () => setDlgState(() => textController.text = presetName),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(presetName, style: const TextStyle(fontSize: 11)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Repeat Count:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: repeats,
                      isDense: true,
                      items: [1, 2, 3, 4, 8].map((r) => DropdownMenuItem(value: r, child: Text('${r}x'))).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => repeats = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = textController.text.trim().isEmpty ? 'Section ${_sections.length + 1}' : textController.text.trim();
                  setState(() {
                    _sections.add(SongSection(
                      id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      repeatCount: repeats,
                      chords: [_c('C', 'Major', beats: 4), _c('G', 'Major', beats: 4)],
                    ));
                    _activeSectionIndex = _sections.length - 1;
                    _selectedChordIndex = 0;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Create Section'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showSectionMenu(int sectionIdx) {
    final section = _sections[sectionIdx];
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SECTION: ${section.name.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0),
                    ),
                    IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit, size: 20),
                  title: const Text('Rename Section', style: TextStyle(fontSize: 13)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _renameSectionDialog(sectionIdx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.repeat, size: 20),
                  title: Text('Repeat Count (${section.repeatCount}x)', style: const TextStyle(fontSize: 13)),
                  trailing: DropdownButton<int>(
                    value: section.repeatCount,
                    isDense: true,
                    items: [1, 2, 3, 4, 8].map((r) => DropdownMenuItem(value: r, child: Text('${r}x'))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => section.repeatCount = val);
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.copy, size: 20),
                  title: const Text('Duplicate Section', style: TextStyle(fontSize: 13)),
                  onTap: () {
                    setState(() {
                      _sections.insert(
                        sectionIdx + 1,
                        SongSection(
                          id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
                          name: '${section.name} (Copy)',
                          repeatCount: section.repeatCount,
                          chords: section.chords.map((c) => c.copyWith()).toList(),
                        ),
                      );
                      _activeSectionIndex = sectionIdx + 1;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.clear_all, size: 20),
                  title: const Text('Clear All Chords in Section', style: TextStyle(fontSize: 13)),
                  onTap: () {
                    setState(() {
                      section.chords.clear();
                      _selectedChordIndex = 0;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                if (_sections.length > 1)
                  ListTile(
                    leading: Icon(Icons.delete_outline, size: 20, color: colorScheme.onSurface),
                    title: Text('Delete Section', style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
                    onTap: () {
                      setState(() {
                        _sections.removeAt(sectionIdx);
                        if (_activeSectionIndex >= _sections.length) {
                          _activeSectionIndex = _sections.length - 1;
                        }
                        _selectedChordIndex = 0;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _renameSectionDialog(int sectionIdx) {
    final textController = TextEditingController(text: _sections[sectionIdx].name);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Rename Section', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  setState(() => _sections[sectionIdx].name = textController.text.trim());
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removeChordAt(int index) {
    final chords = _currentSection.chords;
    if (index >= 0 && index < chords.length) {
      setState(() {
        chords.removeAt(index);
        if (_selectedChordIndex >= chords.length) {
          _selectedChordIndex = chords.isNotEmpty ? chords.length - 1 : 0;
        }
      });
    }
  }

  void _transposeSection(int semitones) {
    setState(() {
      final updated = _currentSection.chords.map((chord) {
        return MusicTheory.transposeChord(chord, semitones);
      }).toList();
      _currentSection.chords = updated;
    });
  }

  // =======================================================================
  // PASSING CHORDS ENGINE (Up to 3 Passing Chords)
  // =======================================================================

  void _showPassingChordsDialog() {
    final chords = _currentSection.chords;
    if (chords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one chord to the section before injecting passing chords.')),
      );
      return;
    }

    int targetIdx = (_selectedChordIndex < chords.length) ? _selectedChordIndex : 0;
    final targetChord = chords[targetIdx];
    final targetRoot = targetChord.root;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDlgState) {
          final colorScheme = Theme.of(context).colorScheme;

          // Helper to calculate passing chords leading into targetRoot
          // 1. Quick ii - V -> Target (2 chords)
          final iiRoot = MusicTheory.transposeNote(targetRoot, 2);
          final vRoot = MusicTheory.transposeNote(targetRoot, 7);
          final isTargetMinor = targetChord.quality.contains('Minor') || targetChord.quality.contains('m');
          final iiChord = MusicTheory.buildChord(iiRoot, isTargetMinor ? 'm7b5' : 'm7', beats: 1, isPassing: true);
          final vChord = MusicTheory.buildChord(vRoot, isTargetMinor ? '7alt' : '7th', beats: 1, isPassing: true);

          // 2. Secondary Dominant (V of Target, 1 chord)
          final secDomChord = MusicTheory.buildChord(vRoot, '7th', beats: 2, isPassing: true);

          // 3. Half-Step Chromatic Slide Down (1 chord)
          final halfStepAboveRoot = MusicTheory.transposeNote(targetRoot, 1);
          final slideDownChord = MusicTheory.buildChord(halfStepAboveRoot, '7th', beats: 1, isPassing: true);

          // 4. Half-Step Chromatic Slide Up (1 chord)
          final halfStepBelowRoot = MusicTheory.transposeNote(targetRoot, -1);
          final slideUpChord = MusicTheory.buildChord(halfStepBelowRoot, 'Dim7', beats: 1, isPassing: true);

          // 5. Passing Diminished 7th (1 chord)
          final dimPassRoot = MusicTheory.transposeNote(targetRoot, 1);
          final dimPassChord = MusicTheory.buildChord(dimPassRoot, 'Dim7', beats: 1, isPassing: true);

          // 6. Tritone Substitution (1 chord)
          final tritoneRoot = MusicTheory.transposeNote(vRoot, 6);
          final tritoneChord = MusicTheory.buildChord(tritoneRoot, '7th', beats: 1, isPassing: true);

          // 7. Backdoor Cadence iv7 - bVII7 (2 chords)
          final ivRoot = MusicTheory.transposeNote(targetRoot, 5);
          final bViiRoot = MusicTheory.transposeNote(targetRoot, 10);
          final ivChord = MusicTheory.buildChord(ivRoot, 'm7', beats: 1, isPassing: true);
          final bViiChord = MusicTheory.buildChord(bViiRoot, '7th', beats: 1, isPassing: true);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt, color: colorScheme.onSurface, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'PASSING CHORD ASSISTANT',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.2, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),

                  // Target Selector
                  Row(
                    children: [
                      const Text('Target Chord: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: targetIdx,
                        isDense: true,
                        dropdownColor: colorScheme.surface,
                        items: List.generate(chords.length, (i) {
                          return DropdownMenuItem(
                            value: i,
                            child: Text('${i + 1}. ${chords[i].name} (${chords[i].quality})', style: const TextStyle(fontSize: 12)),
                          );
                        }),
                        onChanged: (v) {
                          if (v != null) setDlgState(() => targetIdx = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select a harmonic passing strategy to inject immediately before ${chords[targetIdx].name}:',
                    style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                  ),
                  const SizedBox(height: 14),

                  // Option 1: Quick ii - V (2 chords)
                  _buildPassingOptionTile(
                    title: 'Quick ii - V  ➔  ${targetChord.name} (2 Chords)',
                    badge: '2 Chords • 1 Beat Each',
                    formula: '${iiChord.name} (1b) ➔ ${vChord.name} (1b) ➔ ${targetChord.name}',
                    description: 'The definitive jazz & pop transition. Creates rapid forward harmonic momentum.',
                    chordsToInsert: [iiChord, vChord],
                    targetIdx: targetIdx,
                    colorScheme: colorScheme,
                  ),

                  // Option 2: Secondary Dominant V of Target (1 chord)
                  _buildPassingOptionTile(
                    title: 'Secondary Dominant (V7 / ${targetChord.name})',
                    badge: '1 Chord • 2 Beats',
                    formula: '${secDomChord.name} (2b) ➔ ${targetChord.name}',
                    description: 'Classic pull towards the target root with strong leading-tone resolution.',
                    chordsToInsert: [secDomChord],
                    targetIdx: targetIdx,
                    colorScheme: colorScheme,
                  ),

                  // Option 3: Chromatic Half-Step Slide Down (1 chord)
                  _buildPassingOptionTile(
                    title: 'Half-Step Chromatic Slide Down (♭II7)',
                    badge: '1 Chord • 1 Beat',
                    formula: '${slideDownChord.name} (1b) ➔ ${targetChord.name}',
                    description: 'Silky smooth semitone slide from above into target.',
                    chordsToInsert: [slideDownChord],
                    targetIdx: targetIdx,
                    colorScheme: colorScheme,
                  ),

                  // Option 4: Chromatic Half-Step Slide Up (1 chord)
                  _buildPassingOptionTile(
                    title: 'Half-Step Diminished Slide Up (♯Idim7)',
                    badge: '1 Chord • 1 Beat',
                    formula: '${slideUpChord.name} (1b) ➔ ${targetChord.name}',
                    description: 'Ascending half-step chromatic tension resolving directly upwards.',
                    chordsToInsert: [slideUpChord],
                    targetIdx: targetIdx,
                    colorScheme: colorScheme,
                  ),

                  // Option 5: Passing Diminished 7th (1 chord)
                  _buildPassingOptionTile(
                    title: 'Passing Diminished 7th',
                    badge: '1 Chord • 1 Beat',
                    formula: '${dimPassChord.name} (1b) ➔ ${targetChord.name}',
                    description: 'Classic gospel and R&B chromatic bridge connecting two scale degrees.',
                    chordsToInsert: [dimPassChord],
                    targetIdx: targetIdx,
                    colorScheme: colorScheme,
                  ),

                  // Option 6: Tritone Substitution (1 chord)
                  _buildPassingOptionTile(
                    title: 'Tritone Sub (♭II7 replacing V7)',
                    badge: '1 Chord • 1 Beat',
                    formula: '${tritoneChord.name} (1b) ➔ ${targetChord.name}',
                    description: 'Shares the same tritone interval as the dominant V, resolving with jazz color.',
                    chordsToInsert: [tritoneChord],
                    targetIdx: targetIdx,
                    colorScheme: colorScheme,
                  ),

                  // Option 7: Backdoor Cadence iv7 - ♭VII7 (2 chords)
                  _buildPassingOptionTile(
                    title: 'Backdoor Resolution (iv7 - ♭VII7)',
                    badge: '2 Chords • 1 Beat Each',
                    formula: '${ivChord.name} (1b) ➔ ${bViiChord.name} (1b) ➔ ${targetChord.name}',
                    description: 'Neo-soul & R&B favorite: approaches the tonic from minor iv to flat-VII.',
                    chordsToInsert: [ivChord, bViiChord],
                    targetIdx: targetIdx,
                    colorScheme: colorScheme,
                  ),

                  // Option 8: Custom 1 to 3 Passing Chords
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 42),
                      side: BorderSide(color: colorScheme.outline),
                    ),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Build Custom 1 - 3 Passing Chords', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCustomPassingChordBuilder(targetIdx);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildPassingOptionTile({
    required String title,
    required String badge,
    required String formula,
    required String description,
    required List<ChordInfo> chordsToInsert,
    required int targetIdx,
    required ColorScheme colorScheme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colorScheme.outline, width: 0.8),
                ),
                child: Text(badge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(formula, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary)),
          const SizedBox(height: 2),
          Text(description, style: TextStyle(fontSize: 10, color: colorScheme.secondary)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.onSurface,
                foregroundColor: colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Inject Here', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() {
                  _currentSection.chords.insertAll(targetIdx, chordsToInsert);
                  _selectedChordIndex = targetIdx;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Injected ${chordsToInsert.length} passing chords before chord ${targetIdx + 1}!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomPassingChordBuilder(int targetIdx) {
    int count = 2;
    final roots = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
    final qualities = ['7th', 'm7', 'Maj7', 'm7b5', 'Dim7', '7alt', '7b9', '7#9', 'Sus4'];

    String r1 = 'D', q1 = 'm7';
    int b1 = 1;
    String r2 = 'G', q2 = '7th';
    int b2 = 1;
    String r3 = 'Ab', q3 = '7th';
    int b3 = 1;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Custom Passing Chords', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Number of Passing Chords (1 - 3):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [1, 2, 3].map((n) {
                      final isSelected = count == n;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text('$n Chord${n > 1 ? 's' : ''}', style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (_) => setDlgState(() => count = n),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Chord 1
                  _buildCustomChordPickerRow(
                    label: 'Passing Chord 1',
                    selectedRoot: r1,
                    selectedQuality: q1,
                    selectedBeats: b1,
                    roots: roots,
                    qualities: qualities,
                    onRootChanged: (v) => setDlgState(() => r1 = v),
                    onQualityChanged: (v) => setDlgState(() => q1 = v),
                    onBeatsChanged: (v) => setDlgState(() => b1 = v),
                  ),

                  // Chord 2
                  if (count >= 2) ...[
                    const SizedBox(height: 8),
                    _buildCustomChordPickerRow(
                      label: 'Passing Chord 2',
                      selectedRoot: r2,
                      selectedQuality: q2,
                      selectedBeats: b2,
                      roots: roots,
                      qualities: qualities,
                      onRootChanged: (v) => setDlgState(() => r2 = v),
                      onQualityChanged: (v) => setDlgState(() => q2 = v),
                      onBeatsChanged: (v) => setDlgState(() => b2 = v),
                    ),
                  ],

                  // Chord 3
                  if (count >= 3) ...[
                    const SizedBox(height: 8),
                    _buildCustomChordPickerRow(
                      label: 'Passing Chord 3',
                      selectedRoot: r3,
                      selectedQuality: q3,
                      selectedBeats: b3,
                      roots: roots,
                      qualities: qualities,
                      onRootChanged: (v) => setDlgState(() => r3 = v),
                      onQualityChanged: (v) => setDlgState(() => q3 = v),
                      onBeatsChanged: (v) => setDlgState(() => b3 = v),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final list = <ChordInfo>[];
                  list.add(MusicTheory.buildChord(r1, q1, beats: b1, isPassing: true));
                  if (count >= 2) {
                    list.add(MusicTheory.buildChord(r2, q2, beats: b2, isPassing: true));
                  }
                  if (count >= 3) {
                    list.add(MusicTheory.buildChord(r3, q3, beats: b3, isPassing: true));
                  }

                  setState(() {
                    _currentSection.chords.insertAll(targetIdx, list);
                    _selectedChordIndex = targetIdx;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Inject Chords'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildCustomChordPickerRow({
    required String label,
    required String selectedRoot,
    required String selectedQuality,
    required int selectedBeats,
    required List<String> roots,
    required List<String> qualities,
    required ValueChanged<String> onRootChanged,
    required ValueChanged<String> onQualityChanged,
    required ValueChanged<int> onBeatsChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButton<String>(
                  value: selectedRoot,
                  isDense: true,
                  isExpanded: true,
                  items: roots.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (v) {
                    if (v != null) onRootChanged(v);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: DropdownButton<String>(
                  value: selectedQuality,
                  isDense: true,
                  isExpanded: true,
                  items: qualities.map((q) => DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (v) {
                    if (v != null) onQualityChanged(v);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: DropdownButton<int>(
                  value: selectedBeats,
                  isDense: true,
                  isExpanded: true,
                  items: [1, 2, 4].map((b) => DropdownMenuItem(value: b, child: Text('${b}b', style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (v) {
                    if (v != null) onBeatsChanged(v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // ADD CHORD DIALOG (Triads, 7ths, Extended 9/11/13, Altered, Slash Chords)
  // =======================================================================

  void _showAddChordDialog({int? insertIndex}) {
    final roots = ['C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B'];
    final qualityCategories = {
      'Standard Triads': ['Major', 'Minor', 'Sus4', 'Sus2', 'Dim', 'Aug'],
      '7ths & 6ths': ['7th', 'Maj7', 'm7', 'mMaj7', 'm7b5', 'Dim7', 'Aug7', '6th', 'm6', '6/9', '7sus4'],
      'Extended (9, 11, 13)': ['9th', 'Maj9', 'm9', 'Add9', '11th', 'm11', 'Maj11', '13th', 'Maj13', 'm13'],
      'Altered & Modern Jazz': ['7b9', '7#9', '7#11', 'Maj7#11', '7b13', '7alt'],
    };

    String selectedRoot = 'C';
    String selectedQuality = 'Major';
    String? selectedBass;
    int selectedBeats = 4;
    bool isPassing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDlgState) {
          final colorScheme = Theme.of(context).colorScheme;

          final previewChord = MusicTheory.buildChord(
            selectedRoot,
            selectedQuality,
            bassNote: selectedBass,
            beats: selectedBeats,
            isPassing: isPassing,
          );

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        insertIndex != null ? 'INSERT CHORD AT POSITION ${insertIndex + 1}' : 'ADD CHORD TO ${_currentSection.name.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.0),
                      ),
                      IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),

                  // Live Preview Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  previewChord.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Notes: ${previewChord.noteNames.join(' - ')}',
                                  style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.onSurface,
                                foregroundColor: colorScheme.surface,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (insertIndex != null && insertIndex <= _currentSection.chords.length) {
                                    _currentSection.chords.insert(insertIndex, previewChord);
                                    _selectedChordIndex = insertIndex;
                                  } else {
                                    _currentSection.chords.add(previewChord);
                                    _selectedChordIndex = _currentSection.chords.length - 1;
                                  }
                                });
                                Navigator.pop(ctx);
                              },
                              child: const Text('Add Chord', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        // Cadence & Transition Audition Toolbar
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // 1. Play Alone
                            InkWell(
                              onTap: () => _playSingleChord(previewChord),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.volume_up, size: 11, color: colorScheme.onSurface),
                                    const SizedBox(width: 3),
                                    Text('Hear Alone', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                            ),
                            // 2. Root ➔ Preview
                            InkWell(
                              onTap: () => _playChordTransition(_effectiveRootChord, previewChord),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(4),
                                  color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_forward, size: 10, color: colorScheme.onSurface),
                                    const SizedBox(width: 3),
                                    Text('${_effectiveRootChord.name} ➔ ${previewChord.name}', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                            ),
                            // 3. Preview ➔ Root
                            InkWell(
                              onTap: () => _playChordTransition(previewChord, _effectiveRootChord),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(4),
                                  color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back, size: 10, color: colorScheme.onSurface),
                                    const SizedBox(width: 3),
                                    Text('${previewChord.name} ➔ ${_effectiveRootChord.name}', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                            ),
                            // 4. Selected ➔ Preview (if different from root)
                            if (_selectedChord != null && _selectedChord!.name != _effectiveRootChord.name)
                              InkWell(
                                onTap: () => _playChordTransition(_selectedChord!, previewChord),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(4),
                                    color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.fast_forward, size: 10, color: colorScheme.onSurface),
                                      const SizedBox(width: 3),
                                      Text('${_selectedChord!.name} ➔ ${previewChord.name}', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showChordRecommendationsModal(sourceChord: _selectedChord, insertIndex: insertIndex);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 11, color: colorScheme.onSurface),
                              const SizedBox(width: 4),
                              Text(
                                'Need chord ideas? Explore Smart Chord Recommendations ➔',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface, decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1. Root Selector
                  const Text('ROOT NOTE:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: roots.map((root) {
                        final isSel = selectedRoot == root;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(root, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            selected: isSel,
                            onSelected: (_) => setDlgState(() => selectedRoot = root),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Chord Quality Categories
                  const Text('CHORD QUALITY & EXTENSIONS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  ...qualityCategories.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: TextStyle(fontSize: 10, color: colorScheme.secondary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: entry.value.map((q) {
                              final isSel = selectedQuality == q;
                              return ChoiceChip(
                                label: Text(q, style: const TextStyle(fontSize: 11)),
                                selected: isSel,
                                onSelected: (_) => setDlgState(() => selectedQuality = q),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

                  // 3. Slash Chord / Bass Note & Duration
                  Row(
                    children: [
                      // Slash Bass Note
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SLASH BASS (Optional):', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            DropdownButton<String?>(
                              value: selectedBass,
                              isDense: true,
                              isExpanded: true,
                              dropdownColor: colorScheme.surface,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('None (Root)', style: TextStyle(fontSize: 11))),
                                ...roots.map((r) => DropdownMenuItem(value: r, child: Text('/$r', style: const TextStyle(fontSize: 11)))),
                              ],
                              onChanged: (v) => setDlgState(() => selectedBass = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Beats Duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DURATION (Beats):', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            DropdownButton<int>(
                              value: selectedBeats,
                              isDense: true,
                              isExpanded: true,
                              dropdownColor: colorScheme.surface,
                              items: [1, 2, 3, 4, 6, 8].map((b) => DropdownMenuItem(value: b, child: Text('$b Beats', style: const TextStyle(fontSize: 11)))).toList(),
                              onChanged: (v) {
                                if (v != null) setDlgState(() => selectedBeats = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Passing Flag Toggle
                  CheckboxListTile(
                    title: const Text('Mark as Passing Chord', style: TextStyle(fontSize: 12)),
                    subtitle: const Text('Highlights chord with amber passing indicator', style: TextStyle(fontSize: 10)),
                    value: isPassing,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setDlgState(() => isPassing = v ?? false),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // =======================================================================
  // SMART CHORD RECOMMENDATIONS ENGINE & MODAL
  // =======================================================================

  List<ChordRecommendation> _generateChordRecommendations({
    required ChordInfo sourceChord,
    required String keyRoot,
    required String keyScale,
  }) {
    final recs = <ChordRecommendation>[];
    const roots = MusicTheory.chromaticNotes;

    int rootIdx(String r) {
      String clean = r.replaceAll('♯', '#').replaceAll('♭', 'b').trim();
      int i = roots.indexOf(clean);
      if (i == -1) i = MusicTheory.flatNotes.indexOf(clean);
      return i != -1 ? i : 0;
    }

    final kIdx = rootIdx(keyRoot);
    final sIdx = rootIdx(sourceChord.root);

    String kNote(int semitones) => roots[(kIdx + semitones) % 12];
    String sNote(int semitones) => roots[(sIdx + semitones) % 12];

    final isMajorKey = !keyScale.toLowerCase().contains('min');

    // 1. RESOLUTIONS & CADENCES
    final tonicQuality = isMajorKey ? 'Major' : 'Minor';
    recs.add(ChordRecommendation(
      chord: MusicTheory.buildChord(kNote(0), tonicQuality),
      role: isMajorKey ? 'I (Home Tonic)' : 'i (Tonic Minor)',
      category: 'Resolutions & Cadences',
      explanation: 'Home tonic resolution providing total rest and emotional release.',
      badge: 'Resolution',
    ));

    if (isMajorKey) {
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(7), '7th'),
        role: 'V7 (Dominant 7th)',
        category: 'Resolutions & Cadences',
        explanation: 'Magnetic dominant tension pulling inevitably toward ${kNote(0)} Tonic.',
        badge: 'Cadence',
      ));
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(5), 'Major'),
        role: 'IV (Subdominant / Amen)',
        category: 'Resolutions & Cadences',
        explanation: 'Open, reverent plagal cadence that gently settles into the home key.',
        badge: 'Plagal',
      ));
    } else {
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(7), '7th'),
        role: 'V7 (Harmonic Minor Dominant)',
        category: 'Resolutions & Cadences',
        explanation: 'Electrifying classical tension demanding resolution into ${kNote(0)} minor.',
        badge: 'Cadence',
      ));
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(10), 'Major'),
        role: 'bVII (Subtonic Lift)',
        category: 'Resolutions & Cadences',
        explanation: 'Uplifting natural minor pop resolution moving smoothly into tonic.',
        badge: 'Natural Minor',
      ));
    }

    // 2. NATURAL FLOW & CIRCLE OF FIFTHS (From Source Chord)
    // Circle of 5ths (+5 semitones / 4th up)
    final circleRoot = sNote(5);
    String circleQuality = 'Major';
    if (isMajorKey) {
      final semi = (rootIdx(circleRoot) - kIdx + 12) % 12;
      if (semi == 2 || semi == 4 || semi == 9) {
        circleQuality = 'Minor';
      } else if (semi == 11) {
        circleQuality = 'Dim';
      }
    }
    recs.add(ChordRecommendation(
      chord: MusicTheory.buildChord(circleRoot, circleQuality),
      role: 'Circle 5th ($circleRoot $circleQuality)',
      category: 'Natural Flow',
      explanation: 'Root motion up a 4th / down a 5th is the most natural flow in Western harmony.',
      badge: 'Circle of 5ths',
    ));

    // Stepwise Up (+2 semitones from source)
    final stepUpRoot = sNote(2);
    String stepUpQuality = 'Major';
    if (isMajorKey) {
      final semi = (rootIdx(stepUpRoot) - kIdx + 12) % 12;
      if (semi == 2 || semi == 4 || semi == 9) stepUpQuality = 'Minor';
    }
    recs.add(ChordRecommendation(
      chord: MusicTheory.buildChord(stepUpRoot, stepUpQuality),
      role: 'Step Up (+2st to $stepUpRoot)',
      category: 'Natural Flow',
      explanation: 'Ascending stepwise lift building forward energy and pop momentum.',
      badge: 'Stepwise',
    ));

    // Stepwise Down (-2 semitones from source)
    final stepDownRoot = sNote(10);
    String stepDownQuality = 'Major';
    if (isMajorKey) {
      final semi = (rootIdx(stepDownRoot) - kIdx + 12) % 12;
      if (semi == 2 || semi == 4 || semi == 9) stepDownQuality = 'Minor';
    }
    recs.add(ChordRecommendation(
      chord: MusicTheory.buildChord(stepDownRoot, stepDownQuality),
      role: 'Step Down (-2st to $stepDownRoot)',
      category: 'Natural Flow',
      explanation: 'Smooth stepwise descent releasing harmonic tension between phrases.',
      badge: 'Passing',
    ));

    // Third Shift (-4 semitones from source)
    final thirdDownRoot = sNote(8);
    recs.add(ChordRecommendation(
      chord: MusicTheory.buildChord(thirdDownRoot, 'Major'),
      role: 'Third Shift ($thirdDownRoot)',
      category: 'Natural Flow',
      explanation: 'Shares common harmonic tones; the foundation of iconic 4-chord pop anthems.',
      badge: 'Voice Leading',
    ));

    // 3. EMOTIONAL & MODAL INTERCHANGE (Borrowed)
    if (isMajorKey) {
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(5), 'Minor'),
        role: 'iv (Minor IV - Tear Jerker)',
        category: 'Emotional & Borrowed',
        explanation: 'The bittersweet chord (Beatles, Radiohead) melting tenderly into tonic.',
        badge: 'Borrowed',
      ));
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(8), 'Major'),
        role: 'bVI (Flat Six Epic Lift)',
        category: 'Emotional & Borrowed',
        explanation: 'Cinematic film trailer wonder and sudden breathtaking grandeur.',
        badge: 'Borrowed',
      ));
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(10), 'Major'),
        role: 'bVII (Subtonic Backdoor)',
        category: 'Emotional & Borrowed',
        explanation: 'Classic rock swagger (AC/DC, Zeppelin) providing soulful cadence.',
        badge: 'Borrowed',
      ));
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(3), 'Major'),
        role: 'bIII (Chromatic Mediant)',
        category: 'Emotional & Borrowed',
        explanation: 'Sci-fi awe and dramatic shift into an emotional parallel universe.',
        badge: 'Borrowed',
      ));
    } else {
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(0), 'Major'),
        role: 'I (Picardy Third)',
        category: 'Emotional & Borrowed',
        explanation: 'Sudden radiant sunshine bursting through dark minor clouds.',
        badge: 'Classical',
      ));
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(8), 'Major'),
        role: 'bVI (Aeolian Climax)',
        category: 'Emotional & Borrowed',
        explanation: 'Hans Zimmer-style emotional peak with sweeping filmic drama.',
        badge: 'Natural Minor',
      ));
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(5), 'Minor'),
        role: 'iv (Minor Subdominant)',
        category: 'Emotional & Borrowed',
        explanation: 'Nocturnal midnight introspection and rainy contemplation.',
        badge: 'Natural Minor',
      ));
    }

    // 4. SECONDARY DOMINANTS & JAZZ
    final secDomRoot = sNote(7);
    recs.add(ChordRecommendation(
      chord: MusicTheory.buildChord(secDomRoot, '7th'),
      role: 'V7 of ${sourceChord.root}',
      category: 'Secondary Dominants',
      explanation: 'Secondary dominant generating strong chromatic pull toward ${sourceChord.name}.',
      badge: 'Secondary V7',
    ));

    if (isMajorKey) {
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(2), '7th'),
        role: 'V7/V (Secondary Dominant)',
        category: 'Secondary Dominants',
        explanation: 'Bright jazz-pop push targeting the dominant ${kNote(7)} chord.',
        badge: 'Secondary V7',
      ));
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(4), '7th'),
        role: 'V7/vi (Bluesy Minor Pull)',
        category: 'Secondary Dominants',
        explanation: 'Passionate blues pull diving straight into the relative minor.',
        badge: 'Secondary V7',
      ));
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(kNote(1), '7th'),
        role: 'subV7 (Tritone Substitution)',
        category: 'Secondary Dominants',
        explanation: 'Sleek chromatic jazz bass slide descending a half-step into home tonic.',
        badge: 'Tritone Sub',
      ));
    }

    // 5. COLOR EXTENSIONS & SUSPENSIONS
    recs.add(ChordRecommendation(
      chord: MusicTheory.buildChord(sourceChord.root, 'Sus4'),
      role: '${sourceChord.root}sus4 (Suspended Fourth)',
      category: 'Color & Extensions',
      explanation: 'Hovering tension that delays resolution with airy elegance.',
      badge: 'Suspension',
    ));
    recs.add(ChordRecommendation(
      chord: MusicTheory.buildChord(sourceChord.root, 'Sus2'),
      role: '${sourceChord.root}sus2 (Suspended Second)',
      category: 'Color & Extensions',
      explanation: 'Modern ambient openness, serene and breathy.',
      badge: 'Suspension',
    ));
    recs.add(ChordRecommendation(
      chord: MusicTheory.buildChord(sourceChord.root, 'Add9'),
      role: '${sourceChord.root}add9 (Sparkle Extension)',
      category: 'Color & Extensions',
      explanation: 'Glistening acoustic texture adding rich sparkle to the root triad.',
      badge: 'Extension',
    ));
    if (sourceChord.quality.toLowerCase().contains('min')) {
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(sourceChord.root, 'm7'),
        role: '${sourceChord.root}m7 (Soulful Minor 7th)',
        category: 'Color & Extensions',
        explanation: 'Velvety lofi, R&B, and neo-soul warmth.',
        badge: 'Extension',
      ));
    } else {
      recs.add(ChordRecommendation(
        chord: MusicTheory.buildChord(sourceChord.root, 'Maj7'),
        role: '${sourceChord.root}maj7 (Dreamy Major 7th)',
        category: 'Color & Extensions',
        explanation: 'Floating, sunrise warmth with sophisticated pop and jazz color.',
        badge: 'Extension',
      ));
    }

    // Deduplicate by chord.name while preserving rich explanations
    final seen = <String>{};
    final unique = <ChordRecommendation>[];
    for (final r in recs) {
      if (!seen.contains(r.chord.name)) {
        seen.add(r.chord.name);
        unique.add(r);
      }
    }
    return unique;
  }

  void _showChordRecommendationsModal({ChordInfo? sourceChord, int? insertIndex}) {
    ChordInfo activeSource = sourceChord ?? _selectedChord ?? _effectiveRootChord;
    String activeKeyRoot = _effectiveRootChord.root;
    String activeKeyScale = _effectiveRootChord.quality.toLowerCase().contains('min') ? 'Minor' : 'Major';
    String selectedCategory = 'All';

    const roots = MusicTheory.chromaticNotes;
    const categories = [
      'All',
      'Resolutions & Cadences',
      'Natural Flow',
      'Emotional & Borrowed',
      'Secondary Dominants',
      'Color & Extensions',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDlgState) {
          final colorScheme = Theme.of(context).colorScheme;
          final rootChord = MusicTheory.buildChord(activeKeyRoot, activeKeyScale);

          final allRecs = _generateChordRecommendations(
            sourceChord: activeSource,
            keyRoot: activeKeyRoot,
            keyScale: activeKeyScale,
          );

          final displayedRecs = selectedCategory == 'All'
              ? allRecs
              : allRecs.where((r) => r.category == selectedCategory).toList();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 12,
              left: 16,
              right: 16,
              top: 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title + insert position + close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: colorScheme.onSurface),
                        const SizedBox(width: 8),
                        const Text(
                          'CHORD RECOMMENDATIONS',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  insertIndex != null
                      ? 'Finding chords to follow ${activeSource.name} (will insert at position ${insertIndex + 1})'
                      : 'Finding chords to follow ${activeSource.name} (will append to ${_currentSection.name})',
                  style: TextStyle(fontSize: 10.5, color: colorScheme.secondary),
                ),
                const SizedBox(height: 10),

                // Source Chord & Key Selector Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      // "Following Chord:" selector
                      Expanded(
                        child: Row(
                          children: [
                            Text('Following: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                            Flexible(
                              child: DropdownButton<ChordInfo>(
                                value: _currentSection.chords.contains(activeSource)
                                    ? activeSource
                                    : (_currentSection.chords.isNotEmpty ? _currentSection.chords.first : null),
                                isDense: true,
                                underline: const SizedBox.shrink(),
                                dropdownColor: colorScheme.surface,
                                hint: Text(activeSource.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                items: _currentSection.chords.map((c) {
                                  final idx = _currentSection.chords.indexOf(c);
                                  return DropdownMenuItem<ChordInfo>(
                                    value: c,
                                    child: Text('${idx + 1}. ${c.name}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  );
                                }).toList(),
                                onChanged: (newChord) {
                                  if (newChord != null) {
                                    setDlgState(() => activeSource = newChord);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Home Key selector
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Key: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                          DropdownButton<String>(
                            value: activeKeyRoot,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            dropdownColor: colorScheme.surface,
                            items: roots.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
                            onChanged: (k) {
                              if (k != null) setDlgState(() => activeKeyRoot = k);
                            },
                          ),
                          const SizedBox(width: 4),
                          DropdownButton<String>(
                            value: activeKeyScale,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            dropdownColor: colorScheme.surface,
                            items: ['Major', 'Minor'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (s) {
                              if (s != null) setDlgState(() => activeKeyScale = s);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSel = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          selected: isSel,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setDlgState(() => selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Scrollable Recommendations List
                Expanded(
                  child: displayedRecs.isEmpty
                      ? Center(
                          child: Text('No chords found for this category.', style: TextStyle(color: colorScheme.secondary, fontSize: 12)),
                        )
                      : ListView.separated(
                          itemCount: displayedRecs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final rec = displayedRecs[idx];
                            final isDifferentFromRoot = activeSource.name != rootChord.name;

                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Name, Role Badge, + Add Button
                                  Row(
                                    children: [
                                      Text(
                                        rec.chord.name,
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: colorScheme.outline.withOpacity(0.6), width: 0.8),
                                        ),
                                        child: Text(
                                          rec.role,
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: colorScheme.outline.withOpacity(0.4), width: 0.6),
                                        ),
                                        child: Text(
                                          rec.badge,
                                          style: TextStyle(fontSize: 8.5, color: colorScheme.secondary),
                                        ),
                                      ),
                                      const Spacer(),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.onSurface,
                                          foregroundColor: colorScheme.surface,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (insertIndex != null && insertIndex <= _currentSection.chords.length) {
                                              _currentSection.chords.insert(insertIndex, rec.chord);
                                              _selectedChordIndex = insertIndex;
                                            } else {
                                              _currentSection.chords.add(rec.chord);
                                              _selectedChordIndex = _currentSection.chords.length - 1;
                                            }
                                          });
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Added ${rec.chord.name} to ${_currentSection.name}'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          insertIndex != null ? '+ Insert' : '+ Add',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Explanation
                                  Text(
                                    rec.explanation,
                                    style: TextStyle(fontSize: 10.5, color: colorScheme.onSurface.withOpacity(0.85), height: 1.25),
                                  ),
                                  const SizedBox(height: 8),

                                  // Audition buttons: Root before/after, Source transition, Single play
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 5,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      // 1. Play Alone
                                      InkWell(
                                        onTap: () => _playSingleChord(rec.chord),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.volume_up, size: 11, color: colorScheme.onSurface),
                                              const SizedBox(width: 3),
                                              Text('Hear Alone', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 2. Root ➔ Candidate
                                      InkWell(
                                        onTap: () => _playChordTransition(rootChord, rec.chord),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                                            borderRadius: BorderRadius.circular(4),
                                            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.arrow_forward, size: 10, color: colorScheme.onSurface),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${rootChord.name} ➔ ${rec.chord.name}',
                                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 3. Candidate ➔ Root
                                      InkWell(
                                        onTap: () => _playChordTransition(rec.chord, rootChord),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                                            borderRadius: BorderRadius.circular(4),
                                            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.arrow_back, size: 10, color: colorScheme.onSurface),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${rec.chord.name} ➔ ${rootChord.name}',
                                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 4. Source ➔ Candidate (if source != root)
                                      if (isDifferentFromRoot)
                                        InkWell(
                                          onTap: () => _playChordTransition(activeSource, rec.chord),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                                              borderRadius: BorderRadius.circular(4),
                                              color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.fast_forward, size: 10, color: colorScheme.onSurface),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${activeSource.name} ➔ ${rec.chord.name}',
                                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // =======================================================================
  // PRESET LIBRARY MODAL (32 Presets Categorized)
  // =======================================================================

  void _showPresetsLibraryModal() {
    String selectedTopic = 'All';
    int? selectedLength;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDlgState) {
          final colorScheme = Theme.of(context).colorScheme;

          final topics = ['All', 'Pop & Anthems', 'Rock & Grunge', 'Jazz & Swing', 'R&B & Soul', 'Blues & Roots', 'EDM & Synthwave', 'Cinema & Epic'];

          final filtered = _allPresets.where((p) {
            if (selectedTopic != 'All' && p.topic != selectedTopic) return false;
            if (selectedLength != null && p.chordCount != selectedLength) return false;
            if (searchQuery.isNotEmpty) {
              final q = searchQuery.toLowerCase();
              return p.title.toLowerCase().contains(q) ||
                  p.subtopic.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q) ||
                  p.chords.any((c) => c.name.toLowerCase().contains(q));
            }
            return true;
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_stories, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'SONG TEMPLATES & PRESETS (${filtered.length})',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Search input
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search 32+ presets by title, genre, or chords...',
                        hintStyle: TextStyle(fontSize: 11, color: colorScheme.secondary.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (q) => setDlgState(() => searchQuery = q),
                    ),
                    const SizedBox(height: 8),

                    // Topic filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: topics.map((t) {
                          final isSel = selectedTopic == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(t, style: const TextStyle(fontSize: 10)),
                              selected: isSel,
                              onSelected: (_) => setDlgState(() => selectedTopic = t),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Chord length filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All Lengths', style: TextStyle(fontSize: 10)),
                            selected: selectedLength == null,
                            onSelected: (_) => setDlgState(() => selectedLength = null),
                          ),
                          const SizedBox(width: 6),
                          ...[4, 6, 8, 16].map((l) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text('$l Chords', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                selected: selectedLength == l,
                                onSelected: (_) => setDlgState(() => selectedLength = l),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(),

                    // Preset List
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text('No presets found.', style: TextStyle(color: colorScheme.secondary, fontSize: 12)),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filtered.length,
                              itemBuilder: (context, idx) {
                                final preset = filtered[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              preset.title,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Wrap(
                                            spacing: 4,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: colorScheme.outline, width: 0.8),
                                                ),
                                                child: Text('${preset.chordCount} Chords', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: colorScheme.outline, width: 0.8),
                                                ),
                                                child: Text(preset.timeSignature, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${preset.topic.toUpperCase()} • ${preset.subtopic}',
                                        style: TextStyle(fontSize: 10, color: colorScheme.secondary, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(preset.description, style: TextStyle(fontSize: 11, color: colorScheme.secondary)),
                                      const SizedBox(height: 8),

                                      // Chord chips preview
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: preset.chords.map((c) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                                            ),
                                            child: Text(c.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 8),

                                      // Actions
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _sections.add(SongSection(
                                                  id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
                                                  name: preset.title.split('(').first.trim(),
                                                  chords: preset.chords.map((c) => c.copyWith()).toList(),
                                                ));
                                                _activeSectionIndex = _sections.length - 1;
                                                _selectedChordIndex = 0;
                                                _bpm = preset.defaultBpm.toDouble();
                                                _timeSignature = preset.timeSignature;
                                                _beatsPerMeasure = int.tryParse(preset.timeSignature.split('/').first) ?? 4;
                                                _drumPattern = preset.drumPattern;
                                              });
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Created new section from "${preset.title}"')),
                                              );
                                            },
                                            child: const Text('Add as New Section', style: TextStyle(fontSize: 10)),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: colorScheme.onSurface,
                                              foregroundColor: colorScheme.surface,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _currentSection.chords = preset.chords.map((c) => c.copyWith()).toList();
                                                _selectedChordIndex = 0;
                                                _bpm = preset.defaultBpm.toDouble();
                                                _timeSignature = preset.timeSignature;
                                                _beatsPerMeasure = int.tryParse(preset.timeSignature.split('/').first) ?? 4;
                                                _drumPattern = preset.drumPattern;
                                              });
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Loaded "${preset.title}" into ${_currentSection.name}')),
                                              );
                                            },
                                            child: const Text('Load into Section', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
        });
      },
    );
  }

  // =======================================================================
  // BUILD METHOD & SCREEN LAYOUT
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeSection = _currentSection;
    final selectedChord = _selectedChord;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Song Studio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colorScheme.outline, width: 0.8),
              ),
              child: Text(
                'EXPERIMENTAL',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories, size: 20),
            tooltip: 'Song Templates & Presets Library',
            onPressed: _showPresetsLibraryModal,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'reset') {
                _stopPlayback();
                setState(() => _initDefaultSong());
              } else if (val == 'add_section') {
                _addSectionDialog();
              } else if (val == 'exit') {
                _stopPlayback();
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'add_section', child: Text('Add New Song Section')),
              PopupMenuItem(value: 'reset', child: Text('Reset to Default Template')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'exit', child: Text('Exit to Dashboard')),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // 1. MINIMALIST DAW TRANSPORT BAR
            _buildDawTransportBar(colorScheme),

            // 2. SONG SECTIONS TABS
            _buildSongSectionsBar(colorScheme),

            // 3. MAIN WORKSPACE (Chord Sequencer + Inspector)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Section Header & Fast Actions
                    _buildActiveSectionHeader(colorScheme, activeSection),
                    const SizedBox(height: 10),

                    // Chord Sequencer Timeline
                    _buildChordSequencerTimeline(colorScheme, activeSection),
                    const SizedBox(height: 14),

                    // Workspace Action Bar (+ Chord, Passing, Presets, Transpose)
                    _buildWorkspaceActionBar(colorScheme),
                    const SizedBox(height: 16),

                    // CHORD DIAGRAM INSPECTOR (Piano & Guitar & Theory)
                    if (selectedChord != null) ...[
                      _buildChordInspector(colorScheme, selectedChord),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                        ),
                        child: Text(
                          'No chords in this section. Tap "+ Add Chord" or "📚 Presets" to begin.',
                          style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // UI COMPONENT: DAW TRANSPORT BAR
  // =======================================================================

  Widget _buildDawTransportBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Main Play / Stop Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.onSurface,
                          foregroundColor: colorScheme.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, size: 18),
                        label: Text(
                          _isPlaying ? 'STOP' : 'PLAY',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8),
                        ),
                        onPressed: _togglePlay,
                      ),
                      const SizedBox(width: 8),

                      // Mode Toggle: Loop Section vs Full Song
                      InkWell(
                        onTap: () {
                          setState(() => _playFullSong = !_playFullSong);
                          if (_isPlaying) _startPlayback();
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_playFullSong ? Icons.playlist_play : Icons.format_list_numbered, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                _playFullSong ? 'SONG MODE' : 'SECTION MODE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Loop toggle pill
                      InkWell(
                        onTap: () => setState(() => _isLooping = !_isLooping),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isLooping ? colorScheme.onSurface.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _isLooping ? colorScheme.primary : colorScheme.outline.withOpacity(0.4)),
                          ),
                          child: Icon(
                            _isLooping ? Icons.repeat : Icons.repeat_one,
                            size: 14,
                            color: _isLooping ? colorScheme.primary : colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Live Measure Beat Pulse Dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_beatsPerMeasure, (b) {
                  final isCurrent = _isPlaying && _currentBeatInMeasure == b;
                  final isDownbeat = b == 0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isCurrent ? 10 : 7,
                    height: isCurrent ? 10 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? (isDownbeat ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.75))
                          : colorScheme.outline.withOpacity(0.3),
                      border: isDownbeat ? Border.all(color: colorScheme.onSurface, width: 1.0) : null,
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Secondary Transport Pills: Tempo, Time Sig, Voicing, Drums
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Tempo Pill
                InkWell(
                  onTap: _showTempoDialog,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, size: 12),
                        const SizedBox(width: 4),
                        Text('${_bpm.toInt()} BPM', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Time Signature Pill
                InkWell(
                  onTap: _showTimeSignatureDialog,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.straighten, size: 12),
                        const SizedBox(width: 4),
                        Text(_timeSignature, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Voicing Pattern Pill
                InkWell(
                  onTap: _showVoicingDialog,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.music_note, size: 12),
                        const SizedBox(width: 4),
                        Text(_voicingPattern, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Drum Groove Pill
                InkWell(
                  onTap: _showDrumPatternDialog,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.album, size: 12),
                        const SizedBox(width: 4),
                        Text(_drumPattern, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // UI COMPONENT: SONG SECTIONS BAR
  // =======================================================================

  Widget _buildSongSectionsBar(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...List.generate(_sections.length, (idx) {
              final section = _sections[idx];
              final isActive = _activeSectionIndex == idx;
              final isPlayingThis = _isPlaying && _playbackSectionIndex == idx;

              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _activeSectionIndex = idx;
                      _selectedChordIndex = 0;
                    });
                    if (_isPlaying && !_playFullSong) {
                      _playbackSectionIndex = idx;
                      _playbackChordIndex = 0;
                      _currentBeatInChord = 0;
                    }
                  },
                  onLongPress: () => _showSectionMenu(idx),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.onSurface
                          : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPlayingThis
                            ? colorScheme.primary
                            : (isActive ? colorScheme.surface : colorScheme.outline.withOpacity(0.4)),
                        width: isPlayingThis ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPlayingThis) ...[
                          Icon(Icons.volume_up, size: 12, color: isActive ? colorScheme.surface : colorScheme.onSurface),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          section.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? colorScheme.surface : colorScheme.onSurface,
                          ),
                        ),
                        if (section.repeatCount > 1) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${section.repeatCount}x)',
                            style: TextStyle(
                              fontSize: 9,
                              color: isActive ? colorScheme.surface.withOpacity(0.7) : colorScheme.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Add Section Pill
            InkWell(
              onTap: _addSectionDialog,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.4), style: BorderStyle.solid),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14),
                    SizedBox(width: 4),
                    Text('Section', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // UI COMPONENT: ACTIVE SECTION HEADER
  // =======================================================================

  Widget _buildActiveSectionHeader(ColorScheme colorScheme, SongSection activeSection) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              activeSection.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.2),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${activeSection.chords.length} Chords • ${activeSection.chords.fold<int>(0, (sum, c) => sum + c.beats)} Beats',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.secondary),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings, size: 16),
          tooltip: 'Section Options',
          onPressed: () => _showSectionMenu(_activeSectionIndex),
        ),
      ],
    );
  }

  // =======================================================================
  // UI COMPONENT: CHORD SEQUENCER TIMELINE
  // =======================================================================

  Widget _buildChordSequencerTimeline(ColorScheme colorScheme, SongSection activeSection) {
    if (activeSection.chords.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Text('Section is empty. Add a chord or load a preset.', style: TextStyle(color: colorScheme.secondary, fontSize: 12)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(activeSection.chords.length, (idx) {
        final chord = activeSection.chords[idx];
        final isSelected = _selectedChordIndex == idx;
        final isPlayingChord = _isPlaying && _playbackSectionIndex == _activeSectionIndex && _playbackChordIndex == idx;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedChordIndex = idx;
            });
            _playSingleChord(chord);
          },
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isPlayingChord
                  ? colorScheme.onSurface
                  : (isSelected
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.surface),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPlayingChord
                    ? colorScheme.primary
                    : (isSelected ? colorScheme.onSurface : colorScheme.outline.withOpacity(0.5)),
                width: isPlayingChord ? 2.0 : (isSelected ? 1.6 : 1.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Chord Name + Passing Tag + Delete
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chord.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isPlayingChord ? colorScheme.surface : colorScheme.onSurface,
                      ),
                    ),
                    if (chord.isPassing) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isPlayingChord
                              ? colorScheme.surface.withOpacity(0.25)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isPlayingChord
                                ? colorScheme.surface.withOpacity(0.5)
                                : colorScheme.outline,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '⚡',
                          style: TextStyle(
                            fontSize: 8,
                            color: isPlayingChord ? colorScheme.surface : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        setState(() => _selectedChordIndex = idx);
                        _showChordRecommendationsModal(sourceChord: chord, insertIndex: idx + 1);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 11,
                        color: isPlayingChord ? colorScheme.surface.withOpacity(0.85) : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _removeChordAt(idx),
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: isPlayingChord ? colorScheme.surface.withOpacity(0.7) : colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Subtitle: Quality + Duration Pill
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chord.quality,
                      style: TextStyle(
                        fontSize: 9,
                        color: isPlayingChord ? colorScheme.surface.withOpacity(0.8) : colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Tap to quick-change beats duration (1, 2, 3, 4 beats)
                    InkWell(
                      onTap: () {
                        setState(() {
                          final currentBeats = chord.beats;
                          final nextBeats = currentBeats == 4 ? 2 : (currentBeats == 2 ? 1 : (currentBeats == 1 ? 3 : 4));
                          activeSection.chords[idx] = chord.copyWith(beats: nextBeats);
                        });
                      },
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isPlayingChord ? colorScheme.surface.withOpacity(0.5) : colorScheme.outline,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${chord.beats}b',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: isPlayingChord ? colorScheme.surface : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // =======================================================================
  // UI COMPONENT: WORKSPACE ACTION BAR
  // =======================================================================

  Widget _buildWorkspaceActionBar(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // + Add Chord
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.onSurface,
            foregroundColor: colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Add Chord', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          onPressed: () => _showAddChordDialog(),
        ),

        // ✨ Smart Suggestions (What chords can I add)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: colorScheme.outline),
          ),
          icon: Icon(Icons.auto_awesome, size: 14, color: colorScheme.onSurface),
          label: Text(
            _selectedChord != null ? 'Next Chords (${_selectedChord!.name})' : 'Suggest Chords',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          onPressed: () => _showChordRecommendationsModal(
            sourceChord: _selectedChord,
            insertIndex: _selectedChord != null ? _selectedChordIndex + 1 : null,
          ),
        ),

        // ⚡ Passing Chords
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: colorScheme.outline),
          ),
          icon: Icon(Icons.bolt, size: 14, color: colorScheme.onSurface),
          label: Text('Passing Chords', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          onPressed: _showPassingChordsDialog,
        ),

        // 📚 Song Templates & Presets Library
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.auto_stories, size: 14),
          label: const Text('Library', style: TextStyle(fontSize: 11)),
          onPressed: _showPresetsLibraryModal,
        ),

        // Transpose Controls (-1 / +1)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _transposeSection(-1),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('♭ -1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _transposeSection(1),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('♯ +1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =======================================================================
  // UI COMPONENT: CHORD INSPECTOR (Piano & Guitar Diagrams)
  // =======================================================================

  Widget _buildChordInspector(ColorScheme colorScheme, ChordInfo chord) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inspector Header + Tab Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              chord.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chord.isPassing) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colorScheme.outline, width: 0.8),
                              ),
                              child: Text('PASSING', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Notes: ${chord.noteNames.join(' • ')}',
                        style: TextStyle(fontSize: 10, color: colorScheme.secondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Diagram Tab Switcher: Piano | Guitar | Theory
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInspectorTabButton('piano', '🎹 Piano', colorScheme),
                      _buildInspectorTabButton('guitar', '🎸 Guitar', colorScheme),
                      _buildInspectorTabButton('theory', 'ℹ Theory', colorScheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Inspector Action Bar: Find Chords After [chord.name] + Play
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: colorScheme.outline.withOpacity(0.6)),
                  ),
                  icon: Icon(Icons.auto_awesome, size: 12, color: colorScheme.onSurface),
                  label: Text(
                    'What chords can follow ${chord.name}?',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  onPressed: () => _showChordRecommendationsModal(
                    sourceChord: chord,
                    insertIndex: _selectedChordIndex + 1,
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: colorScheme.outline.withOpacity(0.6)),
                  ),
                  icon: Icon(Icons.volume_up, size: 12, color: colorScheme.onSurface),
                  label: Text(
                    'Play ${chord.name}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  onPressed: () => _playSingleChord(chord),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Diagram Content Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: _inspectorTab == 'piano'
                ? _buildPianoDiagram(colorScheme, chord)
                : (_inspectorTab == 'guitar'
                    ? _buildGuitarDiagram(colorScheme, chord)
                    : _buildTheoryDetails(colorScheme, chord)),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorTabButton(String id, String label, ColorScheme colorScheme) {
    final isSelected = _inspectorTab == id;
    return InkWell(
      onTap: () => setState(() => _inspectorTab = id),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? colorScheme.surface : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // =======================================================================
  // PIANO KEYBOARD DIAGRAM (2 Octaves: C3 to B4)
  // =======================================================================

  Widget _buildPianoDiagram(ColorScheme colorScheme, ChordInfo chord) {
    // 2 Octaves: 14 white keys starting from C3 (MIDI 48) to B4 (MIDI 71)
    const whiteSemitones = [0, 2, 4, 5, 7, 9, 11];
    final whiteNotesList = <_StudioKeyModel>[];
    const startMidi = 48; // C3

    for (int oct = 0; oct < 2; oct++) {
      for (int i = 0; i < whiteSemitones.length; i++) {
        final midi = startMidi + (oct * 12) + whiteSemitones[i];
        final name = MusicTheory.chromaticNotes[midi % 12];
        whiteNotesList.add(_StudioKeyModel(
          midi: midi,
          name: name,
          octave: (midi ~/ 12) - 1,
        ));
      }
    }

    // Black keys relative offsets that exist after white keys in octave:
    // C#(1), D#(3), none after E(4), F#(6), G#(8), A#(10), none after B(11)
    const blackKeyRelativeIndex = [0, 1, 3, 4, 5];

    final chordPitchClasses = chord.midiNotes.map((m) => m % 12).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INTERACTIVE PIANO KEYBED (2 OCTAVES)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.secondary),
            ),
            Text(
              'Tap any key to play note',
              style: TextStyle(fontSize: 9, color: colorScheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Piano Keybed Container (matching Chord Helper architecture)
        Container(
          height: 180,
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
              const blackKeyHeight = 108.0;

              return Stack(
                children: [
                  // Layer 1: White Keys
                  Row(
                    children: List.generate(whiteNotesList.length, (i) {
                      final keyData = whiteNotesList[i];
                      final pc = keyData.midi % 12;
                      final inChord = chordPitchClasses.contains(pc);
                      final isPressed = _activePressedMidi == keyData.midi;
                      final isRoot = keyData.name == chord.root;
                      final role = _getRoleInChord(pc, chord.root);

                      return Expanded(
                        child: InkWell(
                          onTap: () => _playKey(keyData.midi),
                          child: Container(
                            height: 180,
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
                                      color: isRoot ? Colors.black : const Color(0xFF2E2E2E),
                                      borderRadius: BorderRadius.circular(4),
                                      border: isRoot ? Border.all(color: Colors.grey.shade700, width: 0.8) : null,
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
                      final pc = blackMidi % 12;
                      final inChord = chordPitchClasses.contains(pc);
                      final isPressed = _activePressedMidi == blackMidi;
                      final isRoot = MusicTheory.chromaticNotes[pc] == chord.root;
                      final role = _getRoleInChord(pc, chord.root);
                      final noteName = MusicTheory.chromaticNotes[pc];

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
                                      ? (isRoot ? const Color(0xFF6B7280) : const Color(0xFF4B5563))
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
        const SizedBox(height: 10),

        // Note interval legend
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: chord.noteNames.map((name) {
            int pc = MusicTheory.chromaticNotes.indexOf(name);
            if (pc == -1) pc = MusicTheory.flatNotes.indexOf(name);
            final isRoot = name == chord.root;
            final role = pc != -1 ? _getRoleInChord(pc, chord.root) : null;
            final labelText = role != null ? '$name ($role)' : name;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isRoot ? colorScheme.onSurface : colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: isRoot ? colorScheme.onSurface : colorScheme.outline,
                  width: 0.8,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isRoot ? colorScheme.surface : colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String? _getRoleInChord(int pitchClass, String rootName) {
    final rootPc = MusicTheory.chromaticNotes.indexOf(rootName);
    if (rootPc == -1) return null;
    final interval = (pitchClass - rootPc) % 12;
    final normalized = interval >= 0 ? interval : interval + 12;

    switch (normalized) {
      case 0:
        return 'Root';
      case 1:
        return '♭9';
      case 2:
        return '9';
      case 3:
        return '♭3';
      case 4:
        return '3';
      case 5:
        return '4';
      case 6:
        return '♭5';
      case 7:
        return '5';
      case 8:
        return '♯5';
      case 9:
        return '6';
      case 10:
        return '♭7';
      case 11:
        return '7';
      default:
        return null;
    }
  }

  // =======================================================================
  // GUITAR FRETBOARD CHORD BOX DIAGRAM (6 Strings, Nut to Fret 5)
  // =======================================================================

  Widget _buildGuitarDiagram(ColorScheme colorScheme, ChordInfo chord) {
    final shape = _getGuitarChordShape(chord);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '6-STRING GUITAR CHORD BOX',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.secondary),
            ),
            Text(
              shape.baseFret > 1 ? 'Starting Fret: ${shape.baseFret}' : 'Open Position',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Center(
          child: SizedBox(
            width: 220,
            height: 140,
            child: CustomPaint(
              size: const Size(220, 140),
              painter: _GuitarChordBoxPainter(
                frets: shape.frets,
                baseFret: shape.baseFret,
                chordName: chord.name,
                colorScheme: colorScheme,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Guitar chord shapes database with intelligent algorithmic fallback
  _GuitarShape _getGuitarChordShape(ChordInfo chord) {
    final key = '${chord.root}_${chord.quality}';

    const lookup = <String, _GuitarShape>{
      // C Shapes
      'C_Major': _GuitarShape([-1, 3, 2, 0, 1, 0]),
      'C_Minor': _GuitarShape([-1, 3, 5, 5, 4, 3], baseFret: 3),
      'C_7th': _GuitarShape([-1, 3, 2, 3, 1, 0]),
      'C_Maj7': _GuitarShape([-1, 3, 2, 0, 0, 0]),
      'C_m7': _GuitarShape([-1, 3, 5, 3, 4, 3], baseFret: 3),
      'C_Add9': _GuitarShape([-1, 3, 2, 0, 3, 0]),
      'C_9th': _GuitarShape([-1, 3, 2, 3, 3, 0]),

      // D Shapes
      'D_Major': _GuitarShape([-1, -1, 0, 2, 3, 2]),
      'D_Minor': _GuitarShape([-1, -1, 0, 2, 3, 1]),
      'D_7th': _GuitarShape([-1, -1, 0, 2, 1, 2]),
      'D_Maj7': _GuitarShape([-1, -1, 0, 2, 2, 2]),
      'D_m7': _GuitarShape([-1, -1, 0, 2, 1, 1]),
      'D_Sus4': _GuitarShape([-1, -1, 0, 2, 3, 3]),

      // E Shapes
      'E_Major': _GuitarShape([0, 2, 2, 1, 0, 0]),
      'E_Minor': _GuitarShape([0, 2, 2, 0, 0, 0]),
      'E_7th': _GuitarShape([0, 2, 0, 1, 0, 0]),
      'E_Maj7': _GuitarShape([0, 2, 1, 1, 0, 0]),
      'E_m7': _GuitarShape([0, 2, 0, 0, 0, 0]),
      'E_7#9': _GuitarShape([0, 7, 6, 7, 8, -1], baseFret: 5), // Hendrix chord

      // F Shapes
      'F_Major': _GuitarShape([1, 3, 3, 2, 1, 1]),
      'F_Minor': _GuitarShape([1, 3, 3, 1, 1, 1]),
      'F_Maj7': _GuitarShape([-1, -1, 3, 2, 1, 0]),
      'F_7th': _GuitarShape([1, 3, 1, 2, 1, 1]),
      'F_m7': _GuitarShape([1, 3, 1, 1, 1, 1]),

      // G Shapes
      'G_Major': _GuitarShape([3, 2, 0, 0, 0, 3]),
      'G_Minor': _GuitarShape([3, 5, 5, 3, 3, 3], baseFret: 3),
      'G_7th': _GuitarShape([3, 2, 0, 0, 0, 1]),
      'G_Maj7': _GuitarShape([3, -1, 0, 0, 0, 2]),
      'G_m7': _GuitarShape([3, 5, 3, 3, 3, 3], baseFret: 3),

      // A Shapes
      'A_Major': _GuitarShape([-1, 0, 2, 2, 2, 0]),
      'A_Minor': _GuitarShape([-1, 0, 2, 2, 1, 0]),
      'A_7th': _GuitarShape([-1, 0, 2, 0, 2, 0]),
      'A_Maj7': _GuitarShape([-1, 0, 2, 1, 2, 0]),
      'A_m7': _GuitarShape([-1, 0, 2, 0, 1, 0]),
      'A_7alt': _GuitarShape([-1, 0, 1, 0, 2, 1]),

      // B & Bb Shapes
      'B_Major': _GuitarShape([-1, 2, 4, 4, 4, 2]),
      'B_Minor': _GuitarShape([-1, 2, 4, 4, 3, 2]),
      'B_7th': _GuitarShape([-1, 2, 1, 2, 0, 2]),
      'B_m7': _GuitarShape([-1, 2, 0, 2, 0, 2]),
      'Bb_Major': _GuitarShape([-1, 1, 3, 3, 3, 1]),
      'Bb_7th': _GuitarShape([-1, 1, 3, 1, 3, 1]),
      'Bb_Maj7': _GuitarShape([-1, 1, 3, 2, 3, 1]),
    };

    if (lookup.containsKey(key)) {
      return lookup[key]!;
    }

    // Algorithmic Voicing Fallback for Extended & Altered chords
    // Guitar tuning MIDI: E2(40), A2(45), D3(50), G3(55), B3(59), E4(64)
    final tuning = [40, 45, 50, 55, 59, 64];
    final pitchClasses = chord.midiNotes.map((m) => m % 12).toSet();
    final frets = <int>[];

    for (int string = 0; string < 6; string++) {
      int openMidi = tuning[string];
      int bestFret = -1;
      for (int f = 0; f <= 4; f++) {
        if (pitchClasses.contains((openMidi + f) % 12)) {
          bestFret = f;
          break;
        }
      }
      frets.add(bestFret);
    }

    return _GuitarShape(frets);
  }

  // =======================================================================
  // THEORY & INTERVAL DETAILS TAB
  // =======================================================================

  Widget _buildTheoryDetails(ColorScheme colorScheme, ChordInfo chord) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HARMONIC FORMULA & INTERVALS',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.secondary),
        ),
        const SizedBox(height: 8),
        Text(
          'Root: ${chord.root} • Quality: ${chord.quality} ${chord.bassNote != null ? '• Bass Inversion: /${chord.bassNote}' : ''}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Constituent Notes: ${chord.noteNames.join(' — ')}',
          style: TextStyle(fontSize: 11, color: colorScheme.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Synthesizer MIDI Tones: ${chord.midiNotes.join(', ')}',
          style: TextStyle(fontSize: 10, color: colorScheme.secondary.withOpacity(0.8)),
        ),
        const SizedBox(height: 10),
        Text(
          chord.isPassing
              ? '⚡ PASSING CHORD: Configured for rapid resolution (${chord.beats} beat${chord.beats > 1 ? 's' : ''}) into the subsequent harmony.'
              : 'MEASURE CHORD: Sustains for ${chord.beats} beats in the active section sequencer.',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // =======================================================================
  // MODAL DIALOGS: TEMPO, TIME SIGNATURE, VOICING, DRUMS
  // =======================================================================

  void _showTempoDialog() {
    double tempBpm = _bpm;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Tempo (BPM)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${tempBpm.toInt()} BPM', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Slider(
                  value: tempBpm,
                  min: 40,
                  max: 220,
                  divisions: 36,
                  onChanged: (v) => setDlgState(() => tempBpm = v),
                ),
                Wrap(
                  spacing: 6,
                  children: [60, 80, 100, 110, 120, 140, 160].map((presetBpm) {
                    return ActionChip(
                      label: Text('$presetBpm', style: const TextStyle(fontSize: 10)),
                      onPressed: () => setDlgState(() => tempBpm = presetBpm.toDouble()),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  setState(() => _bpm = tempBpm);
                  if (_isPlaying) _startPlayback();
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showTimeSignatureDialog() {
    final signatures = ['4/4', '3/4', '2/4', '5/4', '6/8', '7/8', '12/8'];
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Select Time Signature', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          children: signatures.map((sig) {
            final isSel = _timeSignature == sig;
            return SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _timeSignature = sig;
                  _beatsPerMeasure = int.tryParse(sig.split('/').first) ?? 4;
                });
                if (_isPlaying) _startPlayback();
                Navigator.pop(ctx);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sig, style: TextStyle(fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  if (isSel) const Icon(Icons.check, size: 16),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showVoicingDialog() {
    final styles = [
      'Pad',
      'Strummed Roll',
      'Arpeggio Up ▲',
      'Arpeggio Down ▼',
      'Arpeggio Sweep ▲▼',
      'Fingerpick (P-I-M-A)',
      'Piano Comp (Boom-Chick)',
      'Pulse 8ths',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Accompaniment Voicing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          children: styles.map((style) {
            final isSel = _voicingPattern == style;
            return SimpleDialogOption(
              onPressed: () {
                setState(() => _voicingPattern = style);
                Navigator.pop(ctx);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(style, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  if (isSel) const Icon(Icons.check, size: 16),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showDrumPatternDialog() {
    final patterns = [
      'Off',
      'Metronome',
      'Basic Rock',
      'Four-on-the-Floor',
      'Half-Time',
      'Ballad Waltz (3/4)',
      '6/8 Slow Jam',
      'Jazz Swing',
      'Funk & R&B',
      'Latin Bossa',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Drum Groove & Volume', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Volume: ${(_drumVolume * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: _drumVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        onChanged: (v) {
                          setDlgState(() => _drumVolume = v);
                          setState(() => _drumVolume = v);
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ...patterns.map((p) {
                  final isSel = _drumPattern == p;
                  return InkWell(
                    onTap: () {
                      setState(() => _drumPattern = p);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          if (isSel) const Icon(Icons.check, size: 16),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        });
      },
    );
  }

  // =======================================================================
  // 32 EXTENSIVE PRESET TEMPLATES
  // =======================================================================

  static final List<ProgressionPreset> _allPresets = [
    // --- Pop & Anthems ---
    ProgressionPreset(
      title: 'Stadium Anthem (I - V - vi - IV)',
      topic: 'Pop & Anthems',
      subtopic: 'Four-Chord Stadium',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 118,
      beatsPerChord: 4,
      drumPattern: 'Basic Rock',
      chords: [_c('C', 'Major'), _c('G', 'Major'), _c('A', 'Minor'), _c('F', 'Major')],
      description: 'The definitive pop anthem progression (Journey, Adele, U2, Beatles).',
    ),
    ProgressionPreset(
      title: 'Sensational Loop (vi - IV - I - V)',
      topic: 'Pop & Anthems',
      subtopic: 'Moody Pop Anthem',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 120,
      beatsPerChord: 4,
      drumPattern: 'Four-on-the-Floor',
      chords: [_c('A', 'Minor'), _c('F', 'Major'), _c('C', 'Major'), _c('G', 'Major')],
      description: 'Driving minor-first progression used across modern dance-pop and indie radio.',
    ),
    ProgressionPreset(
      title: 'Rising Radiance (6 Chords)',
      topic: 'Pop & Anthems',
      subtopic: 'Uplifting Verse-Lift',
      chordCount: 6,
      timeSignature: '4/4',
      defaultBpm: 104,
      beatsPerChord: 4,
      drumPattern: 'Basic Rock',
      chords: [_c('C', 'Major'), _c('G', 'Major'), _c('A', 'Minor'), _c('E', 'Minor'), _c('F', 'Major'), _c('G', 'Major')],
      description: 'Expands the 4-chord loop with iii (Em) before ascending back home to tonic.',
    ),
    ProgressionPreset(
      title: 'Tears to Triumph (6 Chords)',
      topic: 'Pop & Anthems',
      subtopic: 'Emotional Power Ballad',
      chordCount: 6,
      timeSignature: '4/4',
      defaultBpm: 92,
      beatsPerChord: 4,
      drumPattern: 'Basic Rock',
      chords: [_c('A', 'Minor'), _c('E', 'Minor'), _c('F', 'Major'), _c('C', 'Major'), _c('D', 'Minor'), _c('G', 'Major')],
      description: 'Heartfelt minor descent resolving through a dramatic pre-chorus cadence.',
    ),
    ProgressionPreset(
      title: 'Classic 50s Doo-Wop (8 Chords)',
      topic: 'Pop & Anthems',
      subtopic: 'Doo-Wop & Songwriter',
      chordCount: 8,
      timeSignature: '4/4',
      defaultBpm: 108,
      beatsPerChord: 4,
      drumPattern: 'Basic Rock',
      chords: [_c('C', 'Major'), _c('A', 'Minor'), _c('F', 'Major'), _c('G', 'Major'), _c('C', 'Major'), _c('A', 'Minor'), _c('D', 'Minor'), _c('G', '7th')],
      description: 'Enduring 1950s two-cycle doo-wop progression with secondary ii-V substitution.',
    ),
    ProgressionPreset(
      title: 'Ethereal Dream-Pop (8 Chords)',
      topic: 'Pop & Anthems',
      subtopic: 'Lush Indie Dream',
      chordCount: 8,
      timeSignature: '4/4',
      defaultBpm: 94,
      beatsPerChord: 4,
      drumPattern: 'Half-Time',
      chords: [_c('F', 'Maj7'), _c('G', 'Major'), _c('E', 'm7'), _c('A', 'm7'), _c('D', 'm7'), _c('G', '7th'), _c('C', 'Maj7'), _c('C', '7th')],
      description: 'Dreamy 7th extensions descending through the circle of fifths with smooth voice leading.',
    ),
    ProgressionPreset(
      title: 'Radio Hit Epic Suite (16 Chords)',
      topic: 'Pop & Anthems',
      subtopic: 'Full Verse + Chorus Suite',
      chordCount: 16,
      timeSignature: '4/4',
      defaultBpm: 120,
      beatsPerChord: 4,
      drumPattern: 'Four-on-the-Floor',
      chords: [
        _c('C', 'Major'), _c('G', 'Major'), _c('A', 'Minor'), _c('F', 'Major'),
        _c('C', 'Major'), _c('G', 'Major'), _c('F', 'Major'), _c('G', 'Major'),
        _c('A', 'Minor'), _c('F', 'Major'), _c('C', 'Major'), _c('G', 'Major'),
        _c('A', 'Minor'), _c('F', 'Major'), _c('G', 'Major'), _c('C', 'Major'),
      ],
      description: 'A complete pop song structure containing a cohesive 8-bar verse and 8-bar soaring chorus.',
    ),

    // --- Rock & Grunge ---
    ProgressionPreset(
      title: 'Seattle Grunge Power (I - ♭VII - IV - I)',
      topic: 'Rock & Grunge',
      subtopic: 'Grunge & Alternative',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 126,
      beatsPerChord: 4,
      drumPattern: 'Basic Rock',
      chords: [_c('E', 'Major'), _c('D', 'Major'), _c('A', 'Major'), _c('E', 'Major')],
      description: 'Raw modal Mixolydian power progression inspired by Nirvana and Pearl Jam.',
    ),
    ProgressionPreset(
      title: 'Punk Blast (I - IV - V - IV)',
      topic: 'Rock & Grunge',
      subtopic: 'Punk & Garage Rock',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 148,
      beatsPerChord: 2,
      drumPattern: 'Basic Rock',
      chords: [_c('A', 'Major'), _c('D', 'Major'), _c('E', 'Major'), _c('D', 'Major')],
      description: 'High-octane Ramones / Green Day punk energy with punchy 2-beat changes.',
    ),
    ProgressionPreset(
      title: 'Creep Modal Shift (I - III - IV - iv)',
      topic: 'Rock & Grunge',
      subtopic: 'Chromatic Parallel Minor',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 92,
      beatsPerChord: 4,
      drumPattern: 'Basic Rock',
      chords: [_c('G', 'Major'), _c('B', 'Major'), _c('C', 'Major'), _c('C', 'Minor')],
      description: 'Radiohead harmonic device: major III tonicization followed by minor iv tear-jerker.',
    ),
    ProgressionPreset(
      title: 'Hard Rock Descent (6 Chords)',
      topic: 'Rock & Grunge',
      subtopic: 'Arena Hard Rock',
      chordCount: 6,
      timeSignature: '4/4',
      defaultBpm: 112,
      beatsPerChord: 4,
      drumPattern: 'Basic Rock',
      chords: [_c('A', 'Minor'), _c('G', 'Major'), _c('F', 'Major'), _c('E', '7th'), _c('F', 'Major'), _c('G', 'Major')],
      description: 'Classic Andalusian rock cadence culminating in dominant E7 before looping back.',
    ),

    // --- Jazz & Swing ---
    ProgressionPreset(
      title: 'Jazz Standard (ii - V - I - VI)',
      topic: 'Jazz & Swing',
      subtopic: 'The Foundation Turnaround',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 124,
      beatsPerChord: 4,
      drumPattern: 'Jazz Swing',
      chords: [_c('D', 'm7'), _c('G', '7th'), _c('C', 'Maj7'), _c('A', '7th')],
      description: 'The supreme foundation of jazz harmony. Employs secondary dominant A7.',
    ),
    ProgressionPreset(
      title: 'Minor Jazz ii - V - i',
      topic: 'Jazz & Swing',
      subtopic: 'Dark Melancholic Cadence',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 108,
      beatsPerChord: 4,
      drumPattern: 'Jazz Swing',
      chords: [_c('D', 'm7b5'), _c('G', '7b9'), _c('C', 'm7'), _c('C', 'm7')],
      description: 'Half-diminished ii leading into altered dominant G7b9 and minor tonic.',
    ),
    ProgressionPreset(
      title: 'Autumn Cadence (8 Chords)',
      topic: 'Jazz & Swing',
      subtopic: 'Circle of Fifths Standard',
      chordCount: 8,
      timeSignature: '4/4',
      defaultBpm: 116,
      beatsPerChord: 4,
      drumPattern: 'Jazz Swing',
      chords: [_c('C', 'm7'), _c('F', '7th'), _c('Bb', 'Maj7'), _c('Eb', 'Maj7'), _c('A', 'm7b5'), _c('D', '7th'), _c('G', 'm7'), _c('G', '7th')],
      description: 'Autumn Leaves progression migrating seamlessly between relative major and minor.',
    ),
    ProgressionPreset(
      title: 'Rhythm Changes A-Section (8 Chords)',
      topic: 'Jazz & Swing',
      subtopic: 'Gershwin Bebop Vehicle',
      chordCount: 8,
      timeSignature: '4/4',
      defaultBpm: 160,
      beatsPerChord: 2,
      drumPattern: 'Jazz Swing',
      chords: [_c('Bb', 'Maj7'), _c('G', '7th'), _c('C', 'm7'), _c('F', '7th'), _c('D', 'm7'), _c('G', '7th'), _c('C', 'm7'), _c('F', '7th')],
      description: 'Rapid-fire 2-beat changes powering hundreds of bebop anthems.',
    ),
    ProgressionPreset(
      title: 'Coltrane Giant Steps Matrix (16 Chords)',
      topic: 'Jazz & Swing',
      subtopic: 'Chromatic Thirds Masterpiece',
      chordCount: 16,
      timeSignature: '4/4',
      defaultBpm: 130,
      beatsPerChord: 2,
      drumPattern: 'Jazz Swing',
      chords: [
        _c('B', 'Maj7'), _c('D', '7th'), _c('G', 'Maj7'), _c('Bb', '7th'),
        _c('Eb', 'Maj7'), _c('A', 'm7'), _c('D', '7th'), _c('G', 'Maj7'),
        _c('Bb', '7th'), _c('Eb', 'Maj7'), _c('F#', '7th'), _c('B', 'Maj7'),
        _c('F', 'm7'), _c('Bb', '7th'), _c('Eb', 'Maj7'), _c('C#', 'm7'),
      ],
      description: 'John Coltrane revolutionary 3-key system cycling across equidistant major thirds.',
    ),

    // --- R&B & Soul ---
    ProgressionPreset(
      title: 'Neo-Soul Groove (IV - iii - vi - I)',
      topic: 'R&B & Soul',
      subtopic: 'Silky Smooth Extensions',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 88,
      beatsPerChord: 4,
      drumPattern: 'Funk & R&B',
      chords: [_c('F', 'Maj9'), _c('E', 'm7'), _c('A', 'm9'), _c('C', 'Maj7')],
      description: 'Lush 9th voicings inspired by D Angelo, Erykah Badu, and Robert Glasper.',
    ),
    ProgressionPreset(
      title: 'Gospel Passing Step (6 Chords)',
      topic: 'R&B & Soul',
      subtopic: 'Gospel & Church Harmony',
      chordCount: 6,
      timeSignature: '4/4',
      defaultBpm: 76,
      beatsPerChord: 4,
      drumPattern: 'Funk & R&B',
      chords: [_c('C', 'Major'), _c('C#', 'Dim7'), _c('D', 'Minor'), _c('D#', 'Dim7'), _c('E', 'Minor'), _c('A', '7th')],
      description: 'Chromatic diminished passing chords moving stepwise between diatonic scale degrees.',
    ),
    ProgressionPreset(
      title: 'Backdoor Neo-Soul Resolution (4 Chords)',
      topic: 'R&B & Soul',
      subtopic: 'Backdoor Cadence (iv - ♭VII - I)',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 86,
      beatsPerChord: 4,
      drumPattern: 'Funk & R&B',
      chords: [_c('C', 'Maj7'), _c('F', 'm7'), _c('Bb', '7th'), _c('C', 'Maj7')],
      description: 'The famous backdoor turnaround approaching the tonic from flat-VII.',
    ),

    // --- Blues & Roots ---
    ProgressionPreset(
      title: '12-Bar Blues in C (12 Chords)',
      topic: 'Blues & Roots',
      subtopic: 'Authentic 12-Bar Shuffle',
      chordCount: 12,
      timeSignature: '4/4',
      defaultBpm: 104,
      beatsPerChord: 4,
      drumPattern: 'Basic Rock',
      chords: [
        _c('C', '7th'), _c('F', '7th'), _c('C', '7th'), _c('C', '7th'),
        _c('F', '7th'), _c('F', '7th'), _c('C', '7th'), _c('C', '7th'),
        _c('G', '7th'), _c('F', '7th'), _c('C', '7th'), _c('G', '7th'),
      ],
      description: 'The historic twelve-bar blues with quick-change to IV in measure two.',
    ),
    ProgressionPreset(
      title: '6/8 Slow Blues Master (12 Chords)',
      topic: 'Blues & Roots',
      subtopic: 'Compound Time Slow Blues',
      chordCount: 12,
      timeSignature: '6/8',
      defaultBpm: 60,
      beatsPerChord: 6,
      drumPattern: '6/8 Slow Jam',
      chords: [
        _c('A', '7th', beats: 6), _c('D', '7th', beats: 6), _c('A', '7th', beats: 6), _c('A', '7th', beats: 6),
        _c('D', '7th', beats: 6), _c('D', '7th', beats: 6), _c('A', '7th', beats: 6), _c('F#', '7th', beats: 6),
        _c('B', 'm7', beats: 6), _c('E', '7th', beats: 6), _c('A', '7th', beats: 6), _c('E', '7th', beats: 6),
      ],
      description: 'Soulful 6/8 slow blues in A inspired by B.B. King and Stevie Ray Vaughan.',
    ),

    // --- EDM & Synthwave ---
    ProgressionPreset(
      title: 'Cyberpunk Synthwave (i - ♭VI - ♭VII - i)',
      topic: 'EDM & Synthwave',
      subtopic: 'Dark Retro Synthwave',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 110,
      beatsPerChord: 4,
      drumPattern: 'Four-on-the-Floor',
      chords: [_c('D', 'Minor'), _c('Bb', 'Major'), _c('C', 'Major'), _c('D', 'Minor')],
      description: '80s analog synthesizer driving progression with punchy minor Aeolian power.',
    ),
    ProgressionPreset(
      title: 'Festival Uplift (IV - I - V - vi)',
      topic: 'EDM & Synthwave',
      subtopic: 'Melodic House & EDM',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 128,
      beatsPerChord: 4,
      drumPattern: 'Four-on-the-Floor',
      chords: [_c('F', 'Major'), _c('C', 'Major'), _c('G', 'Major'), _c('A', 'Minor')],
      description: 'Euphorically lifting sub-dominant start found across Avicii and Calvin Harris.',
    ),

    // --- Cinema & Epic ---
    ProgressionPreset(
      title: 'Epic Hero Odyssey (i - ♭VI - ♭III - ♭VII)',
      topic: 'Cinema & Epic',
      subtopic: 'Hans Zimmer Heroic Theme',
      chordCount: 4,
      timeSignature: '4/4',
      defaultBpm: 84,
      beatsPerChord: 4,
      drumPattern: 'Half-Time',
      chords: [_c('D', 'Minor'), _c('Bb', 'Major'), _c('F', 'Major'), _c('C', 'Major')],
      description: 'Massive Hollywood film score progression powering blockbuster themes.',
    ),
    ProgressionPreset(
      title: 'Sad Waltz Requiem (3/4 Time)',
      topic: 'Cinema & Epic',
      subtopic: 'Classical Film Score Waltz',
      chordCount: 6,
      timeSignature: '3/4',
      defaultBpm: 96,
      beatsPerChord: 3,
      drumPattern: 'Ballad Waltz (3/4)',
      chords: [
        _c('A', 'Minor', beats: 3), _c('D', 'Minor', beats: 3), _c('G', 'Major', beats: 3),
        _c('C', 'Major', beats: 3), _c('F', 'Major', beats: 3), _c('E', '7th', beats: 3),
      ],
      description: 'Haunting cinematic minor waltz descending through minor key degrees.',
    ),
  ];
}

// =======================================================================
// KEY MODEL FOR PIANO KEYBED
// =======================================================================

class _StudioKeyModel {
  final int midi;
  final String name;
  final int octave;

  const _StudioKeyModel({
    required this.midi,
    required this.name,
    required this.octave,
  });
}

// =======================================================================
// CUSTOM PAINTER: GUITAR CHORD BOX
// =======================================================================

class _GuitarShape {
  final List<int> frets; // Length 6: -1 for mute (X), 0 for open (O), 1..5 for fret
  final int baseFret;

  const _GuitarShape(this.frets, {this.baseFret = 1});
}

class _GuitarChordBoxPainter extends CustomPainter {
  final List<int> frets;
  final int baseFret;
  final String chordName;
  final ColorScheme colorScheme;

  _GuitarChordBoxPainter({
    required this.frets,
    required this.baseFret,
    required this.chordName,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const numStrings = 6;
    const numFrets = 4;

    const topMargin = 22.0;
    const bottomMargin = 16.0;
    const leftMargin = 30.0;
    const rightMargin = 24.0;

    final gridWidth = size.width - leftMargin - rightMargin;
    final gridHeight = size.height - topMargin - bottomMargin;
    final stringSpacing = gridWidth / (numStrings - 1);
    final fretSpacing = gridHeight / numFrets;

    final wirePaint = Paint()
      ..color = colorScheme.outline.withOpacity(0.6)
      ..strokeWidth = 1.0;

    final nutPaint = Paint()
      ..color = colorScheme.onSurface
      ..strokeWidth = (baseFret == 1) ? 3.5 : 1.5;

    // 1. Draw Nut / Top Fret Line
    canvas.drawLine(
      const Offset(leftMargin, topMargin),
      Offset(leftMargin + gridWidth, topMargin),
      nutPaint,
    );

    // 2. Draw Fret Wires
    for (int f = 1; f <= numFrets; f++) {
      final y = topMargin + f * fretSpacing;
      canvas.drawLine(Offset(leftMargin, y), Offset(leftMargin + gridWidth, y), wirePaint);
    }

    // 3. Draw 6 Strings
    for (int s = 0; s < numStrings; s++) {
      final x = leftMargin + s * stringSpacing;
      // String gauge thickness
      final sPaint = Paint()
        ..color = colorScheme.outline
        ..strokeWidth = 1.0 + (5 - s) * 0.3;
      canvas.drawLine(Offset(x, topMargin), Offset(x, topMargin + gridHeight), sPaint);
    }

    // 4. Draw Starting Fret Label if > 1
    if (baseFret > 1) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${baseFret}fr',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.secondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 6, topMargin + fretSpacing * 0.3));
    }

    // 5. Draw Open / Mute Markers above Nut
    for (int s = 0; s < numStrings; s++) {
      if (s >= frets.length) break;
      final f = frets[s];
      final x = leftMargin + s * stringSpacing;

      if (f == -1) {
        // Muted (X)
        final tp = TextPainter(
          text: TextSpan(
            text: '✕',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.secondary),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, topMargin - 16));
      } else if (f == 0) {
        // Open (O)
        final tp = TextPainter(
          text: TextSpan(
            text: '○',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, topMargin - 16));
      } else {
        // Finger Dot on Fret
        int fretNumberOnGrid = f - (baseFret - 1);
        if (fretNumberOnGrid >= 1 && fretNumberOnGrid <= numFrets) {
          final dotY = topMargin + (fretNumberOnGrid - 0.5) * fretSpacing;
          final dotPaint = Paint()..color = colorScheme.onSurface;
          canvas.drawCircle(Offset(x, dotY), 6.5, dotPaint);

          // Dot text or finger mark
          final tp = TextPainter(
            text: TextSpan(
              text: '$f',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colorScheme.surface),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(x - tp.width / 2, dotY - tp.height / 2));
        }
      }
    }

    // 6. Draw String Names at bottom (E A D G B E)
    const stringNames = ['E', 'A', 'D', 'G', 'B', 'E'];
    for (int s = 0; s < numStrings; s++) {
      final x = leftMargin + s * stringSpacing;
      final tp = TextPainter(
        text: TextSpan(
          text: stringNames[s],
          style: TextStyle(fontSize: 9, color: colorScheme.secondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, topMargin + gridHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _GuitarChordBoxPainter oldDelegate) {
    return oldDelegate.frets != frets ||
        oldDelegate.baseFret != baseFret ||
        oldDelegate.colorScheme != colorScheme;
  }
}
