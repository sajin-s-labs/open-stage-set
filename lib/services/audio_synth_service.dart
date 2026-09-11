import 'dart:math';

/// Representation of a musical note
class NoteInfo {
  final String name; // e.g. 'C4', 'F#4'
  final int midi; // 60 for C4
  final double frequency; // 261.63 Hz
  final bool isBlackKey;

  const NoteInfo({
    required this.name,
    required this.midi,
    required this.frequency,
    required this.isBlackKey,
  });
}

/// Representation of a musical chord with rich metadata, duration, and passing attributes
class ChordInfo {
  final String name; // e.g. 'C', 'Am', 'G7', 'C/E', 'E7#9'
  final String root; // e.g. 'C'
  final String quality; // 'Major', 'Minor', '7th', 'Maj7', 'm7', 'Maj9', '7#9', etc.
  final String? bassNote; // e.g. 'E' in 'C/E'
  final List<int> midiNotes; // e.g. [48, 60, 64, 67]
  final List<String> noteNames; // ['C', 'E', 'G']
  final int beats; // Duration in beats for sequencer (e.g. 1, 2, 4 beats)
  final bool isPassing; // true if this is an injected passing chord

  const ChordInfo({
    required this.name,
    required this.root,
    required this.quality,
    this.bassNote,
    required this.midiNotes,
    required this.noteNames,
    this.beats = 4,
    this.isPassing = false,
  });

  ChordInfo copyWith({
    String? name,
    String? root,
    String? quality,
    String? bassNote,
    List<int>? midiNotes,
    List<String>? noteNames,
    int? beats,
    bool? isPassing,
  }) {
    return ChordInfo(
      name: name ?? this.name,
      root: root ?? this.root,
      quality: quality ?? this.quality,
      bassNote: bassNote ?? this.bassNote,
      midiNotes: midiNotes ?? this.midiNotes,
      noteNames: noteNames ?? this.noteNames,
      beats: beats ?? this.beats,
      isPassing: isPassing ?? this.isPassing,
    );
  }
}

/// Helper for music theory calculations, comprehensive chord construction, and voicings
class MusicTheory {
  static const List<String> chromaticNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static const List<String> flatNotes = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'
  ];

  /// Standard musical keys including natural, sharp, and common flat keys matching Circle of Fifths
  static const List<String> standardKeys = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'
  ];

  /// Calculate frequency in Hz from MIDI note number (A4 = 69 = 440Hz)
  static double midiToFrequency(int midi) {
    return 440.0 * pow(2.0, (midi - 69) / 12.0);
  }

  /// Whether a chromatic semitone index is a black piano key
  static bool isBlackKey(int chromaticIndex) {
    final noteInOctave = chromaticIndex % 12;
    return noteInOctave == 1 || noteInOctave == 3 || noteInOctave == 6 || noteInOctave == 8 || noteInOctave == 10;
  }

  /// Get MIDI note for root note name and octave (e.g. 'C', 4 -> 60, 'Am', 3 -> 57)
  static int getMidiForNote(String noteName, int octave) {
    String clean = noteName.replaceAll('♯', '#').replaceAll('♭', 'b').trim();
    if (clean.length > 1 && clean.endsWith('m') && !clean.endsWith('dim')) {
      clean = clean.substring(0, clean.length - 1);
    }
    int index = chromaticNotes.indexOf(clean);
    if (index == -1) {
      index = flatNotes.indexOf(clean);
    }
    if (index == -1) index = 0;
    return 12 * (octave + 1) + index;
  }

  /// Comprehensive chord intervals relative to root including standard, extended, and altered jazz chords
  static const Map<String, List<int>> chordIntervals = {
    // Triads
    'Major': [0, 4, 7],
    'Minor': [0, 3, 7],
    'Sus4': [0, 5, 7],
    'Sus2': [0, 2, 7],
    'Dim': [0, 3, 6],
    'Aug': [0, 4, 8],

    // 6ths & 7ths
    '6th': [0, 4, 7, 9],
    'm6': [0, 3, 7, 9],
    '6/9': [0, 4, 7, 9, 14],
    '7th': [0, 4, 7, 10],
    'Maj7': [0, 4, 7, 11],
    'm7': [0, 3, 7, 10],
    'mMaj7': [0, 3, 7, 11],
    'm7b5': [0, 3, 6, 10],
    'Dim7': [0, 3, 6, 9],
    'Aug7': [0, 4, 8, 10],
    '7sus4': [0, 5, 7, 10],

    // 9ths & Extensions
    'Add9': [0, 4, 7, 14],
    '9th': [0, 4, 7, 10, 14],
    'Maj9': [0, 4, 7, 11, 14],
    'm9': [0, 3, 7, 10, 14],
    '11th': [0, 4, 7, 10, 14, 17],
    'm11': [0, 3, 7, 10, 14, 17],
    'Maj11': [0, 4, 7, 11, 14, 17],
    '13th': [0, 4, 7, 10, 14, 21],
    'Maj13': [0, 4, 7, 11, 14, 21],
    'm13': [0, 3, 7, 10, 14, 21],

    // Altered & Modern Jazz Voicings
    '7b9': [0, 4, 7, 10, 13],
    '7#9': [0, 4, 7, 10, 15], // Jimi Hendrix Chord
    '7#11': [0, 4, 7, 10, 18],
    'Maj7#11': [0, 4, 7, 11, 18], // Lydian Sound
    '7b13': [0, 4, 7, 10, 20],
    '7alt': [0, 4, 10, 13, 15, 20], // Altered Dominant
  };

  /// Build ChordInfo from root name, quality, optional bass note, beats, and passing flag
  static ChordInfo buildChord(
    String root,
    String quality, {
    int octave = 4,
    String? bassNote,
    int beats = 4,
    bool isPassing = false,
  }) {
    String cleanRoot = root.replaceAll('♯', '#').replaceAll('♭', 'b').trim();
    if (cleanRoot.length > 1 && cleanRoot.endsWith('m') && !cleanRoot.endsWith('dim')) {
      cleanRoot = cleanRoot.substring(0, cleanRoot.length - 1);
    }
    final rootMidi = getMidiForNote(cleanRoot, octave);
    final intervals = chordIntervals[quality] ?? [0, 4, 7];

    final midiList = <int>[];

    // Handle slash chord bass or standard sub-bass root
    if (bassNote != null && bassNote.isNotEmpty) {
      final bassMidi = getMidiForNote(bassNote, octave - 1);
      midiList.add(bassMidi);
    } else {
      midiList.add(rootMidi - 12); // Acoustic sub-bass root
    }

    final noteNamesList = <String>[];
    if (bassNote != null && bassNote.isNotEmpty && !noteNamesList.contains(bassNote)) {
      noteNamesList.add(bassNote);
    }

    for (final interval in intervals) {
      final noteMidi = rootMidi + interval;
      midiList.add(noteMidi);
      final noteName = chromaticNotes[noteMidi % 12];
      if (!noteNamesList.contains(noteName)) {
        noteNamesList.add(noteName);
      }
    }

    // Determine clean musical display string
    String displayName = cleanRoot;
    switch (quality) {
      case 'Minor': displayName += 'm'; break;
      case '6th': displayName += '6'; break;
      case 'm6': displayName += 'm6'; break;
      case '6/9': displayName += '6/9'; break;
      case '7th': displayName += '7'; break;
      case 'Maj7': displayName += 'maj7'; break;
      case 'm7': displayName += 'm7'; break;
      case 'mMaj7': displayName += 'm(maj7)'; break;
      case 'Sus4': displayName += 'sus4'; break;
      case 'Sus2': displayName += 'sus2'; break;
      case '7sus4': displayName += '7sus4'; break;
      case 'Dim': displayName += 'dim'; break;
      case 'Dim7': displayName += 'dim7'; break;
      case 'Aug': displayName += 'aug'; break;
      case 'Aug7': displayName += '7#5'; break;
      case 'm7b5': displayName += 'm7b5'; break;
      case 'Add9': displayName += 'add9'; break;
      case '9th': displayName += '9'; break;
      case 'Maj9': displayName += 'maj9'; break;
      case 'm9': displayName += 'm9'; break;
      case '11th': displayName += '11'; break;
      case 'm11': displayName += 'm11'; break;
      case 'Maj11': displayName += 'maj11'; break;
      case '13th': displayName += '13'; break;
      case 'Maj13': displayName += 'maj13'; break;
      case 'm13': displayName += 'm13'; break;
      case '7b9': displayName += '7b9'; break;
      case '7#9': displayName += '7#9'; break;
      case '7#11': displayName += '7#11'; break;
      case 'Maj7#11': displayName += 'maj7#11'; break;
      case '7b13': displayName += '7b13'; break;
      case '7alt': displayName += '7alt'; break;
    }

    if (bassNote != null && bassNote.isNotEmpty && bassNote != root) {
      displayName += '/$bassNote';
    }

    return ChordInfo(
      name: displayName,
      root: root,
      quality: quality,
      bassNote: bassNote,
      midiNotes: midiList,
      noteNames: noteNamesList,
      beats: beats,
      isPassing: isPassing,
    );
  }

  /// Transpose note name by semitones
  static String transposeNote(String noteName, int semitones) {
    int idx = chromaticNotes.indexOf(noteName);
    if (idx == -1) idx = flatNotes.indexOf(noteName);
    if (idx == -1) return noteName;
    int newIdx = (idx + semitones) % 12;
    if (newIdx < 0) newIdx += 12;
    return chromaticNotes[newIdx];
  }

  /// Transpose an entire chord by semitones
  static ChordInfo transposeChord(ChordInfo chord, int semitones) {
    final newRoot = transposeNote(chord.root, semitones);
    final newBass = chord.bassNote != null && chord.bassNote!.isNotEmpty
        ? transposeNote(chord.bassNote!, semitones)
        : null;
    return buildChord(
      newRoot,
      chord.quality,
      bassNote: newBass,
      beats: chord.beats,
      isPassing: chord.isPassing,
    );
  }
}
