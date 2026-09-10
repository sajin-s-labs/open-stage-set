import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_synth.dart';
import '../services/audio_synth_service.dart';

class ChordRecommenderScreen extends StatefulWidget {
  const ChordRecommenderScreen({super.key});

  @override
  State<ChordRecommenderScreen> createState() => _ChordRecommenderScreenState();
}

class _ChordRecommenderScreenState extends State<ChordRecommenderScreen> {
  String _selectedKey = 'C';
  String _selectedScaleType = 'Major'; // 'Major' or 'Minor'
  final List<ChordInfo> _progression = [];
  int _selectedChordIndex = 0; // Currently focused chord for recommendations context

  bool _isPlaying = false;
  int? _currentlyPlayingIndex;
  Timer? _playbackTimer;
  double _bpm = 100.0;
  bool _loop = false;

  int _transitionAudioToken = 0;

  String _selectedFeelingFilter = 'All';
  String _groupingMode = 'Feeling'; // 'Feeling' or 'Theory'

  /// Currently active chord context for suggestions
  ChordInfo get _activeChord {
    if (_selectedChordIndex >= 0 && _selectedChordIndex < _progression.length) {
      return _progression[_selectedChordIndex];
    }
    if (_progression.isNotEmpty) return _progression.last;
    return MusicTheory.buildChord(_selectedKey, _selectedScaleType);
  }

  /// Current root / key tonic chord
  ChordInfo get _rootChord {
    return MusicTheory.buildChord(_selectedKey, _selectedScaleType);
  }

  static const List<Map<String, String>> _feelingOptions = [
    {'id': 'All', 'label': 'All Options', 'emoji': '🌟'},
    {'id': 'Simple', 'label': 'Simple & Essential', 'emoji': '🌱'},
    {'id': 'Uplifting', 'label': 'Uplifting & Hopeful', 'emoji': '✨'},
    {'id': 'Bittersweet', 'label': 'Bittersweet & Nostalgic', 'emoji': '🌧️'},
    {'id': 'Soulful', 'label': 'Soulful & Dreamy', 'emoji': '☕'},
    {'id': 'Bluesy', 'label': 'Bluesy Swagger', 'emoji': '🎸'},
    {'id': 'Epic', 'label': 'Dramatic & Epic', 'emoji': '⚡'},
    {'id': 'Dark', 'label': 'Dark & Mysterious', 'emoji': '🌑'},
    {'id': 'Tension', 'label': 'Tension & Suspense', 'emoji': '🌪️'},
    {'id': 'Modulation', 'label': 'Modulation & Scale Change', 'emoji': '🔄'},
    {'id': 'Experimental', 'label': 'Experimental & Modern', 'emoji': '🧪'},
  ];

  static const Map<String, String> _feelingDescriptions = {
    'All': 'Explore all chord options tailored to your active chord, starting with simple diatonic chords up to modern colors.',
    'Simple': 'Foundational diatonic chords (I, IV, V, vi, ii, iii) that naturally sound harmonious and form the backbone of songs.',
    'Uplifting': 'Major subdominant lifts, sparkling add9s, and soaring resolutions that inspire hope and joy.',
    'Bittersweet': 'Tear-jerker minor-iv borrowed chords and relative minors that invoke deep nostalgia and longing.',
    'Soulful': 'Weightless major-7ths, silky minor-7ths, and suspended ambient clouds for lofi and neo-soul.',
    'Bluesy': 'Gritty blues-tonic 7ths, mixolydian rock chords, and raw attitude with magnetic groove.',
    'Epic': 'Hollywood cinematic bVI lifts, stadium rock bVIIs, and explosive dominant tension for goosebumps.',
    'Dark': 'Phrygian Neapolitan shadows, half-diminished tension, and cold minor dominants for noir suspense.',
    'Tension': 'High-gravity altered dominants (7b9, 7#9, 7alt), diminished vertigo, and augmented suspense demanding release.',
    'Modulation': 'Gateway secondary dominants (V/V, V/vi, V/IV) and pivot chords to transition to new scales and keys.',
    'Experimental': 'Avant-garde Lydian Maj7#11, quartal stacks, tritone substitutions, and unexpected filmic mediants.',
  };

  @override
  void initState() {
    super.initState();
    // Default initial chord
    _progression.add(MusicTheory.buildChord('C', 'Major'));
    _selectedChordIndex = 0;
  }

  @override
  void dispose() {
    _transitionAudioToken++;
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _playChord(ChordInfo chord) {
    _transitionAudioToken++;
    AudioSynthesizer.instance.playChord(chord.midiNotes, durationSeconds: 1.5, volume: 0.35);
  }

  Future<void> _playChordTransition(ChordInfo first, ChordInfo second) async {
    final token = ++_transitionAudioToken;
    AudioSynthesizer.instance.playChord(first.midiNotes, durationSeconds: 0.95, volume: 0.34);
    await Future.delayed(const Duration(milliseconds: 650));
    if (token != _transitionAudioToken || !mounted) return;
    AudioSynthesizer.instance.playChord(second.midiNotes, durationSeconds: 1.4, volume: 0.38);
  }

  void _addChordToProgression(ChordInfo chord, {required bool isPrefix}) {
    _playChord(chord);
    setState(() {
      int insertIdx;
      if (_progression.isEmpty) {
        insertIdx = 0;
        _progression.add(chord);
      } else {
        if (isPrefix) {
          insertIdx = (_selectedChordIndex >= 0 && _selectedChordIndex < _progression.length)
              ? _selectedChordIndex
              : 0;
          _progression.insert(insertIdx, chord);
        } else {
          insertIdx = (_selectedChordIndex >= 0 && _selectedChordIndex < _progression.length)
              ? _selectedChordIndex + 1
              : _progression.length;
          if (insertIdx > _progression.length) insertIdx = _progression.length;
          _progression.insert(insertIdx, chord);
        }
      }
      _selectedChordIndex = insertIdx;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${chord.name} as ${isPrefix ? "prefix (before)" : "suffix (after)"}'),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _showChordPatternModal(ChordInfo chord) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChordPatternSheet(
        chord: chord,
        activeChord: _activeChord,
        onAddPrefix: () {
          Navigator.pop(ctx);
          _addChordToProgression(chord, isPrefix: true);
        },
        onAddSuffix: () {
          Navigator.pop(ctx);
          _addChordToProgression(chord, isPrefix: false);
        },
        onPlayTransition: (first, second) => _playChordTransition(first, second),
      ),
    );
  }

  void _removeFromProgression(int index) {
    setState(() {
      _progression.removeAt(index);
      if (_selectedChordIndex >= _progression.length) {
        _selectedChordIndex = _progression.isNotEmpty ? _progression.length - 1 : 0;
      }
      if (_currentlyPlayingIndex != null && _currentlyPlayingIndex! >= _progression.length) {
        _currentlyPlayingIndex = null;
      }
    });
  }

  void _clearProgression() {
    _stopPlayback();
    setState(() {
      _progression.clear();
      _selectedChordIndex = 0;
    });
  }

  void _togglePlayProgression() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_progression.isEmpty) return;

    setState(() {
      _isPlaying = true;
      _currentlyPlayingIndex = 0;
    });

    _playChord(_progression[0]);

    final beatIntervalMs = (60000 / _bpm * 2).round(); // 2 beats per chord

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(Duration(milliseconds: beatIntervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextIndex = (_currentlyPlayingIndex ?? 0) + 1;
      if (nextIndex < _progression.length) {
        setState(() {
          _currentlyPlayingIndex = nextIndex;
        });
        _playChord(_progression[nextIndex]);
      } else {
        if (_loop) {
          setState(() {
            _currentlyPlayingIndex = 0;
          });
          _playChord(_progression[0]);
        } else {
          _stopPlayback();
        }
      }
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentlyPlayingIndex = null;
    });
  }

  void _copyProgressionText() {
    if (_progression.isEmpty) return;
    final text = _progression.map((c) => c.name).join(' - ');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Progression copied: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// All rich suggestions annotated with feeling, role, theory and emotional descriptions,
  /// evaluated dynamically relative to the active chord and the song's key center.
  List<_SuggestionChord> _getAllSuggestions() {
    final active = _activeChord;
    const roots = MusicTheory.chromaticNotes;
    final rootIdx = roots.indexOf(_selectedKey);
    final safeRootIdx = rootIdx != -1 ? rootIdx : 0;
    String noteAt(int semitones) => roots[(safeRootIdx + semitones) % 12];

    String cleanActive = active.root.replaceAll('♯', '#').replaceAll('♭', 'b').trim();
    if (cleanActive.length > 1 && cleanActive.endsWith('m') && !cleanActive.endsWith('dim')) {
      cleanActive = cleanActive.substring(0, cleanActive.length - 1);
    }
    int activeIdx = roots.indexOf(cleanActive);
    if (activeIdx == -1) activeIdx = MusicTheory.flatNotes.indexOf(cleanActive);
    if (activeIdx == -1) activeIdx = 0;
    String activeNoteAt(int semitones) => roots[(activeIdx + semitones) % 12];

    final isMajorKey = _selectedScaleType == 'Major';
    final suggestions = <_SuggestionChord>[];

    // =======================================================================
    // 1. SIMPLE & ESSENTIAL DIATONIC HARMONY (FOUNDATIONAL CHORDS)
    // =======================================================================
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(0), isMajorKey ? 'Major' : 'Minor'),
      role: isMajorKey ? 'I (Home Tonic)' : 'i (Home Tonic)',
      feeling: 'Simple',
      feelingEmoji: '🌱',
      feelingLabel: 'Simple & Essential',
      reason: 'Home sweet home. Provides total emotional release, pure resolution, and stable grounding.',
      harmonicCategory: 'Essential Diatonic Harmony',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(5), isMajorKey ? 'Major' : 'Minor'),
      role: isMajorKey ? 'IV (Subdominant Lift)' : 'iv (Subdominant Minor)',
      feeling: 'Simple',
      feelingEmoji: '🌱',
      feelingLabel: 'Simple & Essential',
      reason: 'A warm, open-hearted lift that breathes fresh air and forward movement into any progression.',
      harmonicCategory: 'Essential Diatonic Harmony',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(7), 'Major'),
      role: 'V (Dominant Major)',
      feeling: 'Simple',
      feelingEmoji: '🌱',
      feelingLabel: 'Simple & Essential',
      reason: 'The ultimate forward-moving chord, pulling naturally and powerfully back toward the home tonic.',
      harmonicCategory: 'Essential Diatonic Harmony',
    ));
    suggestions.add(_SuggestionChord(
      chord: isMajorKey
          ? MusicTheory.buildChord(noteAt(9), 'Minor')
          : MusicTheory.buildChord(noteAt(3), 'Major'),
      role: isMajorKey ? 'vi (Relative Minor)' : 'bIII (Relative Major)',
      feeling: 'Simple',
      feelingEmoji: '🌱',
      feelingLabel: 'Simple & Essential',
      reason: isMajorKey
          ? 'Adds tender emotion and soulful depth while remaining completely within the song key.'
          : 'Brings bright, uplifting daylight into a minor progression without changing key center.',
      harmonicCategory: 'Essential Diatonic Harmony',
    ));
    suggestions.add(_SuggestionChord(
      chord: isMajorKey
          ? MusicTheory.buildChord(noteAt(2), 'Minor')
          : MusicTheory.buildChord(noteAt(2), 'Dim'),
      role: isMajorKey ? 'ii (Supertonic Setup)' : 'ii° (Supertonic Dim)',
      feeling: 'Simple',
      feelingEmoji: '🌱',
      feelingLabel: 'Simple & Essential',
      reason: 'The smoothest stepping stone to lead into dominant (V) or subdominant (IV).',
      harmonicCategory: 'Essential Diatonic Harmony',
    ));
    suggestions.add(_SuggestionChord(
      chord: isMajorKey
          ? MusicTheory.buildChord(noteAt(4), 'Minor')
          : MusicTheory.buildChord(noteAt(8), 'Major'),
      role: isMajorKey ? 'iii (Mediant)' : 'bVI (Submediant)',
      feeling: 'Simple',
      feelingEmoji: '🌱',
      feelingLabel: 'Simple & Essential',
      reason: 'Gentle, introspective bridge that softens the movement between chords.',
      harmonicCategory: 'Essential Diatonic Harmony',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(activeNoteAt(5), active.quality.contains('Minor') ? 'Minor' : 'Major'),
      role: 'Circle 5th from ${active.root}',
      feeling: 'Simple',
      feelingEmoji: '🌱',
      feelingLabel: 'Simple & Essential',
      reason: 'Moving up a 4th / down a 5th is nature\'s most satisfying and organic acoustic transition.',
      harmonicCategory: 'Essential Diatonic Harmony',
    ));

    // =======================================================================
    // 2. UPLIFTING & HOPEFUL
    // =======================================================================
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(5), 'Major'),
      role: 'IV (Subdominant)',
      feeling: 'Uplifting',
      feelingEmoji: '✨',
      feelingLabel: 'Uplifting & Hopeful',
      reason: 'Lifts harmonic energy skyward with open-hearted joy and optimism.',
      harmonicCategory: 'Strong Natural Resolutions',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(0), isMajorKey ? 'Major' : 'Minor'),
      role: isMajorKey ? 'I (Home Tonic)' : 'i (Tonic Minor)',
      feeling: 'Uplifting',
      feelingEmoji: '✨',
      feelingLabel: 'Uplifting & Hopeful',
      reason: 'Pure, satisfying resolution landing with complete peace on the home root.',
      harmonicCategory: 'Strong Natural Resolutions',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(0), 'Add9'),
      role: 'Iadd9 (Sparkle Tonic)',
      feeling: 'Uplifting',
      feelingEmoji: '✨',
      feelingLabel: 'Uplifting & Hopeful',
      reason: 'Shimmering acoustic brightness, inspiring and euphoric.',
      harmonicCategory: 'Color Extensions & Textures',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(0), 'Maj7'),
      role: 'Imaj7 (Dreamy Tonic)',
      feeling: 'Uplifting',
      feelingEmoji: '✨',
      feelingLabel: 'Uplifting & Hopeful',
      reason: 'Lush, serene warmth that feels like a peaceful morning sunrise.',
      harmonicCategory: 'Color Extensions & Textures',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(7), 'Major'),
      role: 'V (Dominant Major)',
      feeling: 'Uplifting',
      feelingEmoji: '✨',
      feelingLabel: 'Uplifting & Hopeful',
      reason: 'Bright, triumphant forward momentum driving toward victory.',
      harmonicCategory: 'Strong Natural Resolutions',
    ));

    // =======================================================================
    // 3. BITTERSWEET & NOSTALGIC
    // =======================================================================
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(5), 'Minor'),
      role: 'iv (Minor IV)',
      feeling: 'Bittersweet',
      feelingEmoji: '🌧️',
      feelingLabel: 'Bittersweet & Nostalgic',
      reason: 'The classic bittersweet "tear-jerker" cadence (The Beatles \'In My Life\', Radiohead \'Creep\').',
      harmonicCategory: 'Modal Interchange (Borrowed)',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(9), 'Minor'),
      role: 'vi (Relative Minor)',
      feeling: 'Bittersweet',
      feelingEmoji: '🌧️',
      feelingLabel: 'Bittersweet & Nostalgic',
      reason: 'Shifts a bright progression into reflective, autumn-rain contemplation.',
      harmonicCategory: 'Strong Natural Resolutions',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(4), 'Minor'),
      role: 'iii (Mediant Minor)',
      feeling: 'Bittersweet',
      feelingEmoji: '🌧️',
      feelingLabel: 'Bittersweet & Nostalgic',
      reason: 'Soft, bittersweet passing chord between tonic and relative minor.',
      harmonicCategory: 'Smooth Transitions & Setup',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(2), 'm7'),
      role: 'ii7 (Supertonic 7th)',
      feeling: 'Bittersweet',
      feelingEmoji: '🌧️',
      feelingLabel: 'Bittersweet & Nostalgic',
      reason: 'Tender romantic melancholy, setting up a poignant release.',
      harmonicCategory: 'Smooth Transitions & Setup',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(activeNoteAt(5), 'Minor'),
      role: 'iv of ${active.root} (Minor Subdominant)',
      feeling: 'Bittersweet',
      feelingEmoji: '🌧️',
      feelingLabel: 'Bittersweet & Nostalgic',
      reason: 'Plunges deeper into minor emotional depths relative to ${active.name}.',
      harmonicCategory: 'Smooth Transitions & Setup',
    ));

    // =======================================================================
    // 4. SOULFUL & DREAMY
    // =======================================================================
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(5), 'Maj7'),
      role: 'IVmaj7 (Lush Subdominant)',
      feeling: 'Soulful',
      feelingEmoji: '☕',
      feelingLabel: 'Soulful & Dreamy',
      reason: 'Weightless floating sensation; quintessential lofi, neo-soul & bedroom pop.',
      harmonicCategory: 'Color Extensions & Textures',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(9), 'm7'),
      role: 'vi7 (Soulful Minor 7th)',
      feeling: 'Soulful',
      feelingEmoji: '☕',
      feelingLabel: 'Soulful & Dreamy',
      reason: 'Velvet-smooth coffeehouse texture with mellow warmth.',
      harmonicCategory: 'Color Extensions & Textures',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(active.root, 'Sus2'),
      role: '${active.root}sus2 (Suspended 2nd)',
      feeling: 'Soulful',
      feelingEmoji: '☕',
      feelingLabel: 'Soulful & Dreamy',
      reason: 'Airy, ambient space hovering peacefully without major/minor bias.',
      harmonicCategory: 'Color Extensions & Textures',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(active.root, 'Sus4'),
      role: '${active.root}sus4 (Suspended 4th)',
      feeling: 'Soulful',
      feelingEmoji: '☕',
      feelingLabel: 'Soulful & Dreamy',
      reason: 'Yearning, contemplative delay before floating back down to root.',
      harmonicCategory: 'Color Extensions & Textures',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(activeNoteAt(5), active.quality.contains('Minor') ? 'Minor' : 'Major'),
      role: 'Circle 5th from ${active.root}',
      feeling: 'Soulful',
      feelingEmoji: '☕',
      feelingLabel: 'Soulful & Dreamy',
      reason: 'Natural acoustic gravity moving up a 4th / down a 5th from ${active.name}.',
      harmonicCategory: 'Smooth Transitions & Setup',
    ));

    // =======================================================================
    // 5. BLUESY SWAGGER
    // =======================================================================
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(0), '7th'),
      role: 'I7 (Blues Tonic 7th)',
      feeling: 'Bluesy',
      feelingEmoji: '🎸',
      feelingLabel: 'Bluesy Swagger',
      reason: 'Raw blues attitude that turns the home root into a driving launchpad to IV.',
      harmonicCategory: 'Color Extensions & Textures',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(5), '7th'),
      role: 'IV7 (Funk / Blues IV)',
      feeling: 'Bluesy',
      feelingEmoji: '🎸',
      feelingLabel: 'Bluesy Swagger',
      reason: 'Gritty, stanky groove with dirty rock-and-roll attitude.',
      harmonicCategory: 'Color Extensions & Textures',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(10), 'Major'),
      role: 'bVII (Mixolydian Rock)',
      feeling: 'Bluesy',
      feelingEmoji: '🎸',
      feelingLabel: 'Bluesy Swagger',
      reason: 'Classic rock swagger (AC/DC, Lynyrd Skynyrd, Rolling Stones).',
      harmonicCategory: 'Modal Interchange (Borrowed)',
    ));

    // =======================================================================
    // 6. DRAMATIC & EPIC
    // =======================================================================
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(8), 'Major'),
      role: 'bVI (Flat Six)',
      feeling: 'Epic',
      feelingEmoji: '⚡',
      feelingLabel: 'Dramatic & Epic',
      reason: 'The Hollywood cinematic hero lift (film trailers, Lord of the Rings, John Williams).',
      harmonicCategory: 'Modal Interchange (Borrowed)',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(10), 'Major'),
      role: 'bVII (Subtonic Major)',
      feeling: 'Epic',
      feelingEmoji: '⚡',
      feelingLabel: 'Dramatic & Epic',
      reason: 'Anthemic stadium rock triumph, epic and larger-than-life.',
      harmonicCategory: 'Modal Interchange (Borrowed)',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(3), 'Major'),
      role: 'bIII (Chromatic Mediant)',
      feeling: 'Epic',
      feelingEmoji: '⚡',
      feelingLabel: 'Dramatic & Epic',
      reason: 'A breathtaking sci-fi wonder leap; shocking and magnificent.',
      harmonicCategory: 'Modal Interchange (Borrowed)',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(7), '7th'),
      role: 'V7 (Dominant 7th)',
      feeling: 'Epic',
      feelingEmoji: '⚡',
      feelingLabel: 'Dramatic & Epic',
      reason: 'Maximum harmonic gravity and explosive resolve into the home key.',
      harmonicCategory: 'Strong Natural Resolutions',
    ));

    // =======================================================================
    // 7. DARK & MYSTERIOUS
    // =======================================================================
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(1), 'Major'),
      role: 'bII (Neapolitan Sixth)',
      feeling: 'Dark',
      feelingEmoji: '🌑',
      feelingLabel: 'Dark & Mysterious',
      reason: 'Haunting Phrygian dread and shadowy cinematic suspense.',
      harmonicCategory: 'Modal Interchange (Borrowed)',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(11), 'm7b5'),
      role: 'viiø7 (Half-Diminished)',
      feeling: 'Dark',
      feelingEmoji: '🌑',
      feelingLabel: 'Dark & Mysterious',
      reason: 'Dark neo-noir alley tension; brooding, unsettled, and questioning.',
      harmonicCategory: 'Smooth Transitions & Setup',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(7), 'Minor'),
      role: 'v (Minor Dominant)',
      feeling: 'Dark',
      feelingEmoji: '🌑',
      feelingLabel: 'Dark & Mysterious',
      reason: 'Strips all warmth and brightness, cloaking the melody in cold gray mist.',
      harmonicCategory: 'Modal Interchange (Borrowed)',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(2), 'Dim'),
      role: 'ii° (Diminished Triad)',
      feeling: 'Dark',
      feelingEmoji: '🌑',
      feelingLabel: 'Dark & Mysterious',
      reason: 'Tight claustrophobic suspense waiting in the dark.',
      harmonicCategory: 'Smooth Transitions & Setup',
    ));

    // =======================================================================
    // 8. TENSION & SUSPENSE (KEEP LAST AS REQUESTED)
    // =======================================================================
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(activeNoteAt(7), '7b9'),
      role: 'V7b9 of ${active.root}',
      feeling: 'Tension',
      feelingEmoji: '🌪️',
      feelingLabel: 'Tension & Suspense',
      reason: 'Intense altered minor-ninth dissonance creating immense gravitational pull toward ${active.name}.',
      harmonicCategory: 'Tension & Altered Dominants',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(7), '7#9'),
      role: 'V7#9 (Hendrix Dominant)',
      feeling: 'Tension',
      feelingEmoji: '🌪️',
      feelingLabel: 'Tension & Suspense',
      reason: 'Clashing major 3rd and minor 3rd frequencies produce a biting, explosive grit.',
      harmonicCategory: 'Tension & Altered Dominants',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(activeNoteAt(11), 'Dim7'),
      role: 'vii°7 (Diminished Vertigo)',
      feeling: 'Tension',
      feelingEmoji: '🌪️',
      feelingLabel: 'Tension & Suspense',
      reason: 'Symmetrical stack of minor thirds creating unsettling suspense with four possible resolution paths.',
      harmonicCategory: 'Tension & Altered Dominants',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(2), 'm7b5'),
      role: 'iiø7 (Half-Diminished)',
      feeling: 'Tension',
      feelingEmoji: '🌪️',
      feelingLabel: 'Tension & Suspense',
      reason: 'Dark neo-noir alley tension, brooding and questioning before an unresolved turnaround.',
      harmonicCategory: 'Tension & Altered Dominants',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(active.root, 'Aug'),
      role: '${active.root}aug (Augmented Suspension)',
      feeling: 'Tension',
      feelingEmoji: '🌪️',
      feelingLabel: 'Tension & Suspense',
      reason: 'Floating, dreamlike vertigo that blurs tonality with sharp whole-tone mystery.',
      harmonicCategory: 'Tension & Altered Dominants',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(7), '7alt'),
      role: 'V7alt (Altered Scale Dominant)',
      feeling: 'Tension',
      feelingEmoji: '🌪️',
      feelingLabel: 'Tension & Suspense',
      reason: 'Altered 5ths and 9ths generate maximum modern jazz tension demanding resolution.',
      harmonicCategory: 'Tension & Altered Dominants',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(activeNoteAt(1), '7th'),
      role: 'subV7 (Tritone Sub to ${active.root})',
      feeling: 'Tension',
      feelingEmoji: '🌪️',
      feelingLabel: 'Tension & Suspense',
      reason: 'Half-step chromatic glide above ${active.root} that slides sleekly into resolution.',
      harmonicCategory: 'Tension & Altered Dominants',
    ));

    // =======================================================================
    // 9. MODULATION & KEY CHANGES (CHORDS TO CHANGE TO DIFFERENT SCALE)
    // =======================================================================
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(2), '7th'),
      role: 'V7/V (Modulate to Dominant)',
      feeling: 'Modulation',
      feelingEmoji: '🔄',
      feelingLabel: 'Modulation & Key Change',
      reason: 'Secondary dominant pivoting from $_selectedKey into the brighter scale of ${noteAt(7)} Major.',
      harmonicCategory: 'Modulation & Scale Changes',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(4), '7th'),
      role: 'V7/vi (Modulate to Relative Minor)',
      feeling: 'Modulation',
      feelingEmoji: '🔄',
      feelingLabel: 'Modulation & Key Change',
      reason: 'Dramatic classical gateway plunging into the introspective realm of ${noteAt(9)} Minor.',
      harmonicCategory: 'Modulation & Scale Changes',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(0), '7th'),
      role: 'V7/IV (Modulate to Subdominant)',
      feeling: 'Modulation',
      feelingEmoji: '🔄',
      feelingLabel: 'Modulation & Key Change',
      reason: 'Transforms the tonic into a bluesy dominant launching pad to shift scale to ${noteAt(5)} Major.',
      harmonicCategory: 'Modulation & Scale Changes',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(9), '7th'),
      role: 'V7/ii (Modulate to Dorian ii)',
      feeling: 'Modulation',
      feelingEmoji: '🔄',
      feelingLabel: 'Modulation & Key Change',
      reason: 'Chromatic pivot opening the door to ${noteAt(2)} Dorian and jazz-pop ii-V territory.',
      harmonicCategory: 'Modulation & Scale Changes',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(1), 'Major'),
      role: 'bII (Neapolitan Phrygian Shift)',
      feeling: 'Modulation',
      feelingEmoji: '🔄',
      feelingLabel: 'Modulation & Key Change',
      reason: 'Chilling chromatic pivot shifting into dark Spanish Phrygian or Neapolitan scale color.',
      harmonicCategory: 'Modulation & Scale Changes',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(activeNoteAt(3), 'Major'),
      role: 'bIII of ${active.root} (Relative Mod)',
      feeling: 'Modulation',
      feelingEmoji: '🔄',
      feelingLabel: 'Modulation & Key Change',
      reason: 'Bridges tonality into the parallel/relative major world of ${active.name}.',
      harmonicCategory: 'Modulation & Scale Changes',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(activeNoteAt(5), 'Major'),
      role: 'Circle Pivot (${activeNoteAt(5)})',
      feeling: 'Modulation',
      feelingEmoji: '🔄',
      feelingLabel: 'Modulation & Key Change',
      reason: 'Advances one step forward around the Circle of Fifths to travel smoothly into a neighboring key.',
      harmonicCategory: 'Modulation & Scale Changes',
    ));

    // =======================================================================
    // 10. EXPERIMENTAL & MODERN HARMONY
    // =======================================================================
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(active.root, 'Maj7#11'),
      role: '${active.root}maj7#11 (Lydian Wonder)',
      feeling: 'Experimental',
      feelingEmoji: '🧪',
      feelingLabel: 'Experimental & Modern',
      reason: 'The mystical filmic sound (John Williams, Ghibli); raised 4th creates weightless floating awe.',
      harmonicCategory: 'Experimental & Modern Color',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(active.root, '6/9'),
      role: '${active.root}6/9 (Impressionist Color)',
      feeling: 'Experimental',
      feelingEmoji: '🧪',
      feelingLabel: 'Experimental & Modern',
      reason: 'Lush watercolor texture without semitone dissonance; beloved in Debussy and modern neo-soul.',
      harmonicCategory: 'Experimental & Modern Color',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(active.root, '7sus4'),
      role: '${active.root}7sus4 (Quartal Stack)',
      feeling: 'Experimental',
      feelingEmoji: '🧪',
      feelingLabel: 'Experimental & Modern',
      reason: 'Modern fusion suspension floating between dominant pull and subdominant rest.',
      harmonicCategory: 'Experimental & Modern Color',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(6), 'm7b5'),
      role: '#ivø7 (Tritone Dissonance)',
      feeling: 'Experimental',
      feelingEmoji: '🧪',
      feelingLabel: 'Experimental & Modern',
      reason: 'Angular, unexpected chromatic pivot producing sci-fi cinematic shock.',
      harmonicCategory: 'Experimental & Modern Color',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(active.root, '11th'),
      role: '${active.root}11 (Extended Polyphony)',
      feeling: 'Experimental',
      feelingEmoji: '🧪',
      feelingLabel: 'Experimental & Modern',
      reason: 'Complex modern vertical stack spanning multiple octaves with acoustic sheen.',
      harmonicCategory: 'Experimental & Modern Color',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(3), 'Maj7'),
      role: 'bIIImaj7 (Chromatic Mediant)',
      feeling: 'Experimental',
      feelingEmoji: '🧪',
      feelingLabel: 'Experimental & Modern',
      reason: 'Unexpected leap to parallel scale degree creating breathtaking cinematic wonder.',
      harmonicCategory: 'Experimental & Modern Color',
    ));
    suggestions.add(_SuggestionChord(
      chord: MusicTheory.buildChord(noteAt(7), '13th'),
      role: 'V13 (Luxurious Dominant)',
      feeling: 'Experimental',
      feelingEmoji: '🧪',
      feelingLabel: 'Experimental & Modern',
      reason: 'Rich multi-octave acoustic spectrum adding sophistication and swagger.',
      harmonicCategory: 'Experimental & Modern Color',
    ));

    return suggestions;
  }

  /// Groups suggestions by Feeling or Theory, filtering by selected feeling
  Map<String, List<_SuggestionChord>> _getGroupedSuggestions() {
    var all = _getAllSuggestions();

    // Filter by feeling if selected
    if (_selectedFeelingFilter != 'All') {
      all = all.where((s) => s.feeling == _selectedFeelingFilter).toList();
    } else {
      // In 'All' mode, deduplicate so chords appear once starting from simple essentials down to tension
      final seen = <String>{};
      final unique = <_SuggestionChord>[];
      for (final s in all) {
        if (!seen.contains(s.chord.name)) {
          seen.add(s.chord.name);
          unique.add(s);
        }
      }
      all = unique;
    }

    final Map<String, List<_SuggestionChord>> grouped = {};

    for (final s in all) {
      final key = _groupingMode == 'Feeling' ? '${s.feelingEmoji} ${s.feelingLabel.toUpperCase()}' : s.harmonicCategory;
      grouped.putIfAbsent(key, () => []).add(s);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final suggestions = _getGroupedSuggestions();
    final totalChordsCount = suggestions.values.fold(0, (sum, list) => sum + list.length);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Chord Helper',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('WHAT CHORD TO ADD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy Progression',
            onPressed: _progression.isNotEmpty ? _copyProgressionText : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Progression',
            onPressed: _progression.isNotEmpty ? _clearProgression : null,
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
          // 1. Key & Scale Selector Bar
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SONG KEY CENTER',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: colorScheme.secondary),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedKey,
                        isDense: true,
                        isExpanded: true,
                        dropdownColor: colorScheme.surface,
                        underline: const SizedBox(),
                        items: MusicTheory.chromaticNotes.map((k) {
                          return DropdownMenuItem(value: k, child: Text(k, style: const TextStyle(fontWeight: FontWeight.bold)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedKey = val;
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
                        'SCALE TYPE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: colorScheme.secondary),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedScaleType,
                        isDense: true,
                        isExpanded: true,
                        dropdownColor: colorScheme.surface,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'Major', child: Text('Major (Diatonic)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'Minor', child: Text('Natural Minor', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedScaleType = val;
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
          const SizedBox(height: 18),

          // 2. Progression Queue Card
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
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.queue_music, size: 16, color: colorScheme.onSurface),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'YOUR PROGRESSION (${_progression.length} CHORDS)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_loop ? Icons.repeat_one : Icons.repeat, size: 18),
                          tooltip: _loop ? 'Looping enabled' : 'Looping disabled',
                          color: _loop ? colorScheme.onSurface : colorScheme.secondary,
                          onPressed: () {
                            setState(() {
                              _loop = !_loop;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, size: 22),
                          tooltip: _isPlaying ? 'Stop' : 'Play Progression',
                          color: colorScheme.onSurface,
                          onPressed: _progression.isNotEmpty ? _togglePlayProgression : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_progression.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'Progression is empty. Tap any suggestion below to add chords.',
                        style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_progression.length, (idx) {
                      final chord = _progression[idx];
                      final isCurrentlySounding = _currentlyPlayingIndex == idx;
                      final isSelected = _selectedChordIndex == idx;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedChordIndex = idx;
                          });
                          _playChord(chord);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCurrentlySounding
                                ? colorScheme.onSurface
                                : isSelected
                                    ? colorScheme.onSurface.withOpacity(0.12)
                                    : colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: isCurrentlySounding
                                  ? colorScheme.surface
                                  : isSelected
                                      ? colorScheme.onSurface
                                      : colorScheme.outline,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(
                                  Icons.check_circle,
                                  size: 13,
                                  color: isCurrentlySounding ? colorScheme.surface : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                chord.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentlySounding ? colorScheme.surface : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _removeFromProgression(idx),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: isCurrentlySounding ? colorScheme.surface : colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.6), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.near_me, size: 13, color: colorScheme.onSurface),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
                            children: [
                              const TextSpan(text: 'Active focus: '),
                              TextSpan(
                                text: _activeChord.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: ' • Suggestions below connect to this chord. Tap any chord above to change focus.',
                                style: TextStyle(color: colorScheme.secondary, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showChordPatternModal(_activeChord),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline, width: 0.8),
                            borderRadius: BorderRadius.circular(4),
                            color: colorScheme.surface,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.piano, size: 11),
                              const SizedBox(width: 3),
                              Text('Pattern', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 6),

                // Tempo / BPM Slider
                Row(
                  children: [
                    Text(
                      'TEMPO: ${_bpm.toInt()} BPM',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: colorScheme.secondary),
                    ),
                    Expanded(
                      child: Slider(
                        value: _bpm,
                        min: 60,
                        max: 180,
                        divisions: 24,
                        activeColor: colorScheme.onSurface,
                        inactiveColor: colorScheme.outline,
                        onChanged: (val) {
                          setState(() {
                            _bpm = val;
                          });
                          if (_isPlaying) {
                            _startPlayback(); // restart timer with new interval
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Emotional Vibe / Feeling Filter Bar
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline, width: 1.0),
              borderRadius: BorderRadius.circular(10.0),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.mood, size: 16, color: colorScheme.onSurface),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'SUGGEST CHORDS BY FEELING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _groupingMode = _groupingMode == 'Feeling' ? 'Theory' : 'Feeling';
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          border: Border.all(color: colorScheme.outline, width: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _groupingMode == 'Feeling' ? Icons.theater_comedy : Icons.menu_book,
                              size: 13,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _groupingMode == 'Feeling' ? 'BY FEELING' : 'BY THEORY',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Horizontally Scrollable Feeling Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _feelingOptions.map((f) {
                      final isSelected = _selectedFeelingFilter == f['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          showCheckmark: false,
                          avatar: Text(f['emoji']!, style: const TextStyle(fontSize: 12)),
                          label: Text(f['label']!),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? colorScheme.surface : colorScheme.onSurface,
                          ),
                          selected: isSelected,
                          selectedColor: colorScheme.onSurface,
                          backgroundColor: colorScheme.surface,
                          side: BorderSide(
                            color: isSelected ? colorScheme.onSurface : colorScheme.outline,
                            width: 1.0,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFeelingFilter = f['id']!;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  _feelingDescriptions[_selectedFeelingFilter] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 4. Recommendations Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedFeelingFilter == 'All'
                      ? 'SUGGESTED CHORDS FOR ${_activeChord.name.toUpperCase()} ($totalChordsCount)'
                      : '${_selectedFeelingFilter.toUpperCase()} CHORDS FOR ${_activeChord.name.toUpperCase()} ($totalChordsCount)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: colorScheme.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_selectedFeelingFilter != 'All') ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedFeelingFilter = 'All';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline, width: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SHOW ALL',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          if (suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No chords found for this filter in the current key.',
                  style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                ),
              ),
            )
          else
            ...suggestions.entries.map((entry) {
              final categoryName = entry.key;
              final chordList = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...chordList.map((suggestion) {
                      final chord = suggestion.chord;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline, width: 1.0),
                            borderRadius: BorderRadius.circular(8.0),
                            color: colorScheme.surface,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Chord Badge, Role & Reason, Prefix & Suffix Add Buttons
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Chord Badge (Interactive - Tap to see Piano & Guitar Chord Pattern)
                                  InkWell(
                                    onTap: () => _showChordPatternModal(chord),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Tooltip(
                                      message: 'Tap to see Piano & Guitar chord pattern',
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest,
                                          border: Border.all(color: colorScheme.outline, width: 0.8),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              chord.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.piano, size: 10, color: colorScheme.secondary),
                                                const SizedBox(width: 2),
                                                Icon(Icons.music_note, size: 10, color: colorScheme.secondary),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Role, Feeling Badge & Reason
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              suggestion.role,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.surfaceContainerHighest,
                                                border: Border.all(color: colorScheme.outline, width: 0.7),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${suggestion.feelingEmoji} ${suggestion.feeling.toUpperCase()}',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          suggestion.reason,
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.35,
                                            color: colorScheme.secondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: () => _showChordPatternModal(chord),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.visibility_outlined, size: 12, color: colorScheme.onSurface),
                                              const SizedBox(width: 4),
                                              Text(
                                                'View Piano / Guitar pattern',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurface,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Add Prefix / Suffix Buttons
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Tooltip(
                                        message: 'Insert before ${_activeChord.name}',
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: colorScheme.outline),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: const Size(82, 28),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            foregroundColor: colorScheme.onSurface,
                                          ),
                                          icon: const Icon(Icons.arrow_back, size: 11),
                                          label: const Text('+ Prefix', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          onPressed: () => _addChordToProgression(chord, isPrefix: true),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Tooltip(
                                        message: 'Insert after ${_activeChord.name}',
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: colorScheme.outline),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: const Size(82, 28),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            foregroundColor: colorScheme.onSurface,
                                          ),
                                          icon: const Icon(Icons.arrow_forward, size: 11),
                                          label: const Text('+ Suffix', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          onPressed: () => _addChordToProgression(chord, isPrefix: false),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),
                              Divider(height: 1.0, color: colorScheme.outline.withOpacity(0.4)),
                              const SizedBox(height: 8),

                              // Audition Cadence Toolbar
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'HEAR:',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                  // View Pattern Chip
                                  InkWell(
                                    onTap: () => _showChordPatternModal(chord),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: colorScheme.onSurface, width: 0.9),
                                        borderRadius: BorderRadius.circular(4),
                                        color: colorScheme.surface,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.piano, size: 12, color: colorScheme.onSurface),
                                          const SizedBox(width: 3),
                                          Text('Pattern', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Hear Alone
                                  InkWell(
                                    onTap: () => _playChord(chord),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: colorScheme.outline, width: 0.8),
                                        borderRadius: BorderRadius.circular(4),
                                        color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.volume_up, size: 12),
                                          const SizedBox(width: 4),
                                          Text('Alone', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Active -> Candidate (e.g. C -> Fm)
                                  InkWell(
                                    onTap: () => _playChordTransition(_activeChord, chord),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: colorScheme.outline, width: 0.8),
                                        borderRadius: BorderRadius.circular(4),
                                        color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.play_circle_outline, size: 11),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_activeChord.name} ➔ ${chord.name}',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Candidate -> Active (e.g. Fm -> C)
                                  InkWell(
                                    onTap: () => _playChordTransition(chord, _activeChord),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: colorScheme.outline, width: 0.8),
                                        borderRadius: BorderRadius.circular(4),
                                        color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.play_circle_outline, size: 11),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${chord.name} ➔ ${_activeChord.name}',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // If active chord != root chord, also allow Root -> Candidate
                                  if (_activeChord.name != _rootChord.name)
                                    InkWell(
                                      onTap: () => _playChordTransition(_rootChord, chord),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: colorScheme.outline, width: 0.8),
                                          borderRadius: BorderRadius.circular(4),
                                          color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.play_circle_outline, size: 11),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_rootChord.name} ➔ ${chord.name}',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                                            ),
                                          ],
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
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SuggestionChord {
  final ChordInfo chord;
  final String role;
  final String feeling;
  final String feelingEmoji;
  final String feelingLabel;
  final String reason;
  final String harmonicCategory;

  const _SuggestionChord({
    required this.chord,
    required this.role,
    required this.feeling,
    required this.feelingEmoji,
    required this.feelingLabel,
    required this.reason,
    required this.harmonicCategory,
  });
}

// =======================================================================
// CHORD PATTERN MODAL (PIANO & GUITAR VISUALIZERS)
// =======================================================================

class _ChordPatternSheet extends StatefulWidget {
  final ChordInfo chord;
  final ChordInfo activeChord;
  final VoidCallback onAddPrefix;
  final VoidCallback onAddSuffix;
  final Function(ChordInfo, ChordInfo) onPlayTransition;

  const _ChordPatternSheet({
    required this.chord,
    required this.activeChord,
    required this.onAddPrefix,
    required this.onAddSuffix,
    required this.onPlayTransition,
  });

  @override
  State<_ChordPatternSheet> createState() => _ChordPatternSheetState();
}

class _ChordPatternSheetState extends State<_ChordPatternSheet> {
  String _selectedInstrument = 'Piano'; // 'Piano' or 'Guitar'
  int? _activePressedMidi;

  void _playKey(int midi) {
    setState(() => _activePressedMidi = midi);
    AudioSynthesizer.instance.playMidiNote(midi, durationSeconds: 1.0, volume: 0.45);
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted && _activePressedMidi == midi) {
        setState(() => _activePressedMidi = null);
      }
    });
  }

  void _playChord() {
    AudioSynthesizer.instance.playChord(widget.chord.midiNotes, durationSeconds: 1.5, volume: 0.38);
  }

  void _playArpeggio() {
    AudioSynthesizer.instance.playArpeggio(
      widget.chord.midiNotes,
      delayMs: _selectedInstrument == 'Guitar' ? 45 : 120,
      durationSeconds: 1.3,
      volume: 0.38,
    );
  }

  static String? _getRoleInChord(int pitchClass, String rootName) {
    String cleanRoot = rootName.replaceAll('♯', '#').replaceAll('♭', 'b').trim();
    if (cleanRoot.length > 1 && cleanRoot.endsWith('m') && !cleanRoot.endsWith('dim')) {
      cleanRoot = cleanRoot.substring(0, cleanRoot.length - 1);
    }
    int rootPc = MusicTheory.chromaticNotes.indexOf(cleanRoot);
    if (rootPc == -1) rootPc = MusicTheory.flatNotes.indexOf(cleanRoot);
    if (rootPc == -1) return null;

    final interval = (pitchClass - rootPc) % 12;
    final normalized = interval >= 0 ? interval : interval + 12;

    switch (normalized) {
      case 0:
        return 'R';
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

  Widget _buildPianoView(ColorScheme colorScheme) {
    const whiteSemitones = [0, 2, 4, 5, 7, 9, 11];
    final whiteNotesList = <_PianoKeyModel>[];
    const baseOctave = 3;
    const startMidi = 12 * (baseOctave + 1); // C3 = 48

    for (int oct = 0; oct < 2; oct++) {
      for (int i = 0; i < whiteSemitones.length; i++) {
        final midi = startMidi + (oct * 12) + whiteSemitones[i];
        final name = MusicTheory.chromaticNotes[midi % 12];
        whiteNotesList.add(_PianoKeyModel(
          midi: midi,
          name: name,
        ));
      }
    }

    const blackKeyRelativeIndex = [0, 1, 3, 4, 5];
    final chordPitchClasses = widget.chord.midiNotes.map((m) => m % 12).toSet();
    String cleanRoot = widget.chord.root.replaceAll('♯', '#').replaceAll('♭', 'b').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2-Octave Interactive Piano Keyboard
        Container(
          height: 155,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: colorScheme.outline, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final whiteKeyWidth = totalWidth / 14;
              final blackKeyWidth = whiteKeyWidth * 0.64;
              const blackKeyHeight = 92.0;

              return Stack(
                children: [
                  // Layer 1: White Keys
                  Row(
                    children: List.generate(whiteNotesList.length, (i) {
                      final keyData = whiteNotesList[i];
                      final pc = keyData.midi % 12;
                      final inChord = chordPitchClasses.contains(pc);
                      final isPressed = _activePressedMidi == keyData.midi;
                      final isRoot = (MusicTheory.chromaticNotes[pc] == cleanRoot) ||
                          (MusicTheory.flatNotes[pc] == cleanRoot);
                      final role = _getRoleInChord(pc, widget.chord.root);

                      return Expanded(
                        child: InkWell(
                          onTap: () => _playKey(keyData.midi),
                          child: Container(
                            height: 155,
                            decoration: BoxDecoration(
                              color: isPressed
                                  ? colorScheme.surfaceContainerHighest
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
                                if (inChord && role != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isRoot ? Colors.black : const Color(0xFF2E2E2E),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      role,
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                ],
                                Text(
                                  keyData.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: inChord ? FontWeight.bold : FontWeight.w500,
                                    color: inChord ? Colors.black : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
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
                      final isRoot = (MusicTheory.chromaticNotes[pc] == cleanRoot) ||
                          (MusicTheory.flatNotes[pc] == cleanRoot);
                      final role = _getRoleInChord(pc, widget.chord.root);
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
                                      ? (isRoot ? const Color(0xFF555555) : const Color(0xFF383838))
                                      : const Color(0xFF1E1E1E),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                              border: Border.all(
                                color: inChord ? Colors.white : Colors.black,
                                width: inChord ? 1.5 : 0.8,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (inChord && role != null)
                                  Text(
                                    role,
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                Text(
                                  noteName,
                                  style: const TextStyle(fontSize: 7.5, color: Colors.white70),
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

        const SizedBox(height: 12),

        // Constituent Note Badges
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.chord.noteNames.map((name) {
            int pc = MusicTheory.chromaticNotes.indexOf(name);
            if (pc == -1) pc = MusicTheory.flatNotes.indexOf(name);
            final isRoot = name == widget.chord.root;
            final role = pc != -1 ? _getRoleInChord(pc, widget.chord.root) : null;
            final labelText = role != null ? '$name ($role)' : name;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isRoot ? colorScheme.onSurface : colorScheme.surfaceContainerHighest,
                border: Border.all(color: colorScheme.outline, width: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isRoot ? colorScheme.surface : colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Piano Play Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.outline),
                  foregroundColor: colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.music_note, size: 16),
                label: const Text('ARPEGGIO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: _playArpeggio,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.onSurface,
                  foregroundColor: colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.volume_up, size: 16),
                label: const Text('PLAY CHORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: _playChord,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuitarView(ColorScheme colorScheme) {
    final shape = _getGuitarChordShape(widget.chord);

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
              shape.baseFret > 1 ? 'Starting Fret: ${shape.baseFret}fr' : 'Open Position',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
              width: 220,
              height: 140,
              child: CustomPaint(
                size: const Size(220, 140),
                painter: _GuitarChordBoxPainter(
                  frets: shape.frets,
                  baseFret: shape.baseFret,
                  chordName: widget.chord.name,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Strum Guitar Chord Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.onSurface,
              foregroundColor: colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.volume_up, size: 16),
            label: const Text('STRUM GUITAR CHORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: _playArpeggio,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: colorScheme.outline, width: 1.0),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.chord.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                border: Border.all(color: colorScheme.outline, width: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.chord.quality.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Notes: ${widget.chord.noteNames.join(" - ")}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Segmented Control: Piano vs Guitar
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline, width: 0.8),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedInstrument = 'Piano'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedInstrument == 'Piano' ? colorScheme.onSurface : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.piano,
                                size: 16,
                                color: _selectedInstrument == 'Piano' ? colorScheme.surface : colorScheme.onSurface,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PIANO KEYBED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedInstrument == 'Piano' ? colorScheme.surface : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedInstrument = 'Guitar'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedInstrument == 'Guitar' ? colorScheme.onSurface : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_note,
                                size: 16,
                                color: _selectedInstrument == 'Guitar' ? colorScheme.surface : colorScheme.onSurface,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'GUITAR FRETBOARD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedInstrument == 'Guitar' ? colorScheme.surface : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Instrument Pattern View
              if (_selectedInstrument == 'Piano')
                _buildPianoView(colorScheme)
              else
                _buildGuitarView(colorScheme),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Transition Audition
              Text(
                'HEAR TRANSITION WITH ACTIVE CHORD (${widget.activeChord.name}):',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: colorScheme.secondary),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.outline),
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      ),
                      icon: const Icon(Icons.play_circle_outline, size: 14),
                      label: Text(
                        '${widget.activeChord.name} ➔ ${widget.chord.name}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () => widget.onPlayTransition(widget.activeChord, widget.chord),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.outline),
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      ),
                      icon: const Icon(Icons.play_circle_outline, size: 14),
                      label: Text(
                        '${widget.chord.name} ➔ ${widget.activeChord.name}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () => widget.onPlayTransition(widget.chord, widget.activeChord),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Add Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.outline),
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.arrow_back, size: 14),
                      label: Text(
                        '+ Prefix (Before ${widget.activeChord.name})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: widget.onAddPrefix,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.onSurface,
                        foregroundColor: colorScheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: Text(
                        '+ Suffix (After ${widget.activeChord.name})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: widget.onAddSuffix,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _PianoKeyModel {
  final int midi;
  final String name;

  const _PianoKeyModel({required this.midi, required this.name});
}

class _GuitarShape {
  final List<int> frets; // 6 strings: Low E (string 6) to High E (string 1)
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

    // 1. Nut / Top Fret Line
    canvas.drawLine(
      const Offset(leftMargin, topMargin),
      Offset(leftMargin + gridWidth, topMargin),
      nutPaint,
    );

    // 2. Fret Wires
    for (int f = 1; f <= numFrets; f++) {
      final y = topMargin + f * fretSpacing;
      canvas.drawLine(Offset(leftMargin, y), Offset(leftMargin + gridWidth, y), wirePaint);
    }

    // 3. Strings
    for (int s = 0; s < numStrings; s++) {
      final x = leftMargin + s * stringSpacing;
      final sPaint = Paint()
        ..color = colorScheme.outline
        ..strokeWidth = 1.0 + (5 - s) * 0.3;
      canvas.drawLine(Offset(x, topMargin), Offset(x, topMargin + gridHeight), sPaint);
    }

    // 4. Starting Fret Label if > 1
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

    // 5. Open / Mute Markers above Nut
    for (int s = 0; s < numStrings; s++) {
      if (s >= frets.length) break;
      final f = frets[s];
      final x = leftMargin + s * stringSpacing;

      if (f == -1) {
        final tp = TextPainter(
          text: TextSpan(
            text: '✕',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.secondary),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, topMargin - 16));
      } else if (f == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '○',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, topMargin - 16));
      } else {
        int fretNumberOnGrid = f - (baseFret - 1);
        if (fretNumberOnGrid >= 1 && fretNumberOnGrid <= numFrets) {
          final dotY = topMargin + (fretNumberOnGrid - 0.5) * fretSpacing;
          final dotPaint = Paint()..color = colorScheme.onSurface;
          canvas.drawCircle(Offset(x, dotY), 6.5, dotPaint);

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

    // 6. String Names (E A D G B E)
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

_GuitarShape _getGuitarChordShape(ChordInfo chord) {
  String cleanRoot = chord.root.replaceAll('♯', '#').replaceAll('♭', 'b').trim();
  final key = '${cleanRoot}_${chord.quality}';

  const lookup = <String, _GuitarShape>{
    // C Shapes
    'C_Major': _GuitarShape([-1, 3, 2, 0, 1, 0]),
    'C_Minor': _GuitarShape([-1, 3, 5, 5, 4, 3], baseFret: 3),
    'C_7th': _GuitarShape([-1, 3, 2, 3, 1, 0]),
    'C_Maj7': _GuitarShape([-1, 3, 2, 0, 0, 0]),
    'C_m7': _GuitarShape([-1, 3, 5, 3, 4, 3], baseFret: 3),
    'C_Add9': _GuitarShape([-1, 3, 2, 0, 3, 0]),
    'C_9th': _GuitarShape([-1, 3, 2, 3, 3, 0]),
    'C_Sus4': _GuitarShape([-1, 3, 3, 0, 1, 1]),
    'C_Sus2': _GuitarShape([-1, 3, 0, 0, 1, -1]),
    'C_Dim': _GuitarShape([-1, 3, 4, 2, 4, -1], baseFret: 2),
    'C_Dim7': _GuitarShape([-1, 3, 4, 2, 4, -1], baseFret: 2),
    'C_Aug': _GuitarShape([-1, 3, 2, 1, 1, -1]),

    // C# / Db Shapes
    'C#_Major': _GuitarShape([-1, 4, 6, 6, 6, 4], baseFret: 4),
    'C#_Minor': _GuitarShape([-1, 4, 6, 6, 5, 4], baseFret: 4),
    'C#_7th': _GuitarShape([-1, 4, 6, 4, 6, 4], baseFret: 4),
    'Db_Major': _GuitarShape([-1, 4, 6, 6, 6, 4], baseFret: 4),
    'Db_Minor': _GuitarShape([-1, 4, 6, 6, 5, 4], baseFret: 4),

    // D Shapes
    'D_Major': _GuitarShape([-1, -1, 0, 2, 3, 2]),
    'D_Minor': _GuitarShape([-1, -1, 0, 2, 3, 1]),
    'D_7th': _GuitarShape([-1, -1, 0, 2, 1, 2]),
    'D_Maj7': _GuitarShape([-1, -1, 0, 2, 2, 2]),
    'D_m7': _GuitarShape([-1, -1, 0, 2, 1, 1]),
    'D_Sus2': _GuitarShape([-1, -1, 0, 2, 3, 0]),
    'D_Sus4': _GuitarShape([-1, -1, 0, 2, 3, 3]),
    'D_Dim': _GuitarShape([-1, -1, 0, 1, 3, 1]),
    'D_m7b5': _GuitarShape([-1, -1, 0, 1, 1, 1]),

    // Eb / D# Shapes
    'Eb_Major': _GuitarShape([-1, 6, 8, 8, 8, 6], baseFret: 6),
    'Eb_Minor': _GuitarShape([-1, 6, 8, 8, 7, 6], baseFret: 6),
    'Eb_7th': _GuitarShape([-1, 6, 8, 6, 8, 6], baseFret: 6),
    'Eb_Maj7': _GuitarShape([-1, 6, 8, 7, 8, 6], baseFret: 6),
    'D#_Major': _GuitarShape([-1, 6, 8, 8, 8, 6], baseFret: 6),

    // E Shapes
    'E_Major': _GuitarShape([0, 2, 2, 1, 0, 0]),
    'E_Minor': _GuitarShape([0, 2, 2, 0, 0, 0]),
    'E_7th': _GuitarShape([0, 2, 0, 1, 0, 0]),
    'E_Maj7': _GuitarShape([0, 2, 1, 1, 0, 0]),
    'E_m7': _GuitarShape([0, 2, 0, 0, 0, 0]),
    'E_Sus4': _GuitarShape([0, 2, 2, 2, 0, 0]),
    'E_7#9': _GuitarShape([0, 7, 6, 7, 8, -1], baseFret: 5),

    // F Shapes
    'F_Major': _GuitarShape([1, 3, 3, 2, 1, 1]),
    'F_Minor': _GuitarShape([1, 3, 3, 1, 1, 1]),
    'F_7th': _GuitarShape([1, 3, 1, 2, 1, 1]),
    'F_Maj7': _GuitarShape([-1, -1, 3, 2, 1, 0]),
    'F_m7': _GuitarShape([1, 3, 1, 1, 1, 1]),

    // F# / Gb Shapes
    'F#_Major': _GuitarShape([2, 4, 4, 3, 2, 2], baseFret: 2),
    'F#_Minor': _GuitarShape([2, 4, 4, 2, 2, 2], baseFret: 2),
    'F#_7th': _GuitarShape([2, 4, 2, 3, 2, 2], baseFret: 2),
    'Gb_Major': _GuitarShape([2, 4, 4, 3, 2, 2], baseFret: 2),

    // G Shapes
    'G_Major': _GuitarShape([3, 2, 0, 0, 0, 3]),
    'G_Minor': _GuitarShape([3, 5, 5, 3, 3, 3], baseFret: 3),
    'G_7th': _GuitarShape([3, 2, 0, 0, 0, 1]),
    'G_Maj7': _GuitarShape([3, -1, 0, 0, 0, 2]),
    'G_m7': _GuitarShape([3, 5, 3, 3, 3, 3], baseFret: 3),
    'G_Sus4': _GuitarShape([3, 2, 0, 0, 1, 3]),

    // Ab / G# Shapes
    'Ab_Major': _GuitarShape([4, 6, 6, 5, 4, 4], baseFret: 4),
    'Ab_Minor': _GuitarShape([4, 6, 6, 4, 4, 4], baseFret: 4),
    'Ab_7th': _GuitarShape([4, 6, 4, 5, 4, 4], baseFret: 4),
    'G#_Major': _GuitarShape([4, 6, 6, 5, 4, 4], baseFret: 4),

    // A Shapes
    'A_Major': _GuitarShape([-1, 0, 2, 2, 2, 0]),
    'A_Minor': _GuitarShape([-1, 0, 2, 2, 1, 0]),
    'A_7th': _GuitarShape([-1, 0, 2, 0, 2, 0]),
    'A_Maj7': _GuitarShape([-1, 0, 2, 1, 2, 0]),
    'A_m7': _GuitarShape([-1, 0, 2, 0, 1, 0]),
    'A_Sus2': _GuitarShape([-1, 0, 2, 2, 0, 0]),
    'A_Sus4': _GuitarShape([-1, 0, 2, 2, 3, 0]),
    'A_7alt': _GuitarShape([-1, 0, 1, 0, 2, 1]),

    // Bb / A# Shapes
    'Bb_Major': _GuitarShape([-1, 1, 3, 3, 3, 1]),
    'Bb_Minor': _GuitarShape([-1, 1, 3, 3, 2, 1]),
    'Bb_7th': _GuitarShape([-1, 1, 3, 1, 3, 1]),
    'Bb_Maj7': _GuitarShape([-1, 1, 3, 2, 3, 1]),
    'Bb_m7': _GuitarShape([-1, 1, 3, 1, 2, 1]),

    // B Shapes
    'B_Major': _GuitarShape([-1, 2, 4, 4, 4, 2], baseFret: 2),
    'B_Minor': _GuitarShape([-1, 2, 4, 4, 3, 2], baseFret: 2),
    'B_7th': _GuitarShape([-1, 2, 1, 2, 0, 2]),
    'B_Maj7': _GuitarShape([-1, 2, 4, 3, 4, 2], baseFret: 2),
    'B_m7': _GuitarShape([-1, 2, 0, 2, 0, 2]),
    'B_m7b5': _GuitarShape([-1, 2, 3, 2, 3, -1], baseFret: 2),
  };

  if (lookup.containsKey(key)) {
    return lookup[key]!;
  }

  // Algorithmic Fallback Solver
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
