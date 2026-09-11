import 'dart:async';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';

typedef _MidiOutOpenC = Int32 Function(
    Pointer<IntPtr> lphMidiOut, Uint32 uDeviceID, IntPtr dwCallback, IntPtr dwInstance, Uint32 fdwOpen);
typedef _MidiOutOpenDart = int Function(
    Pointer<IntPtr> lphMidiOut, int uDeviceID, int dwCallback, int dwInstance, int fdwOpen);

typedef _MidiOutShortMsgC = Int32 Function(IntPtr hMidiOut, Uint32 dwMsg);
typedef _MidiOutShortMsgDart = int Function(int hMidiOut, int dwMsg);

typedef _MidiOutCloseC = Int32 Function(IntPtr hMidiOut);
typedef _MidiOutCloseDart = int Function(int hMidiOut);

/// Real-time zero-latency MIDI synthesizer for Windows using winmm.dll and Microsoft GS Wavetable
class WindowsMidiSynth {
  static final WindowsMidiSynth instance = WindowsMidiSynth._();
  WindowsMidiSynth._();

  DynamicLibrary? _winmm;
  int _hMidiOut = 0;
  bool _initialized = false;
  bool _available = false;

  late final _MidiOutOpenDart _midiOutOpen;
  late final _MidiOutShortMsgDart _midiOutShortMsg;
  late final _MidiOutCloseDart _midiOutClose;

  final List<Timer> _activeTimers = [];

  bool get isSupported => Platform.isWindows;

  void _init() {
    if (_initialized) return;
    _initialized = true;
    if (!Platform.isWindows) return;

    try {
      _winmm = DynamicLibrary.open('winmm.dll');
      _midiOutOpen = _winmm!.lookupFunction<_MidiOutOpenC, _MidiOutOpenDart>('midiOutOpen');
      _midiOutShortMsg = _winmm!.lookupFunction<_MidiOutShortMsgC, _MidiOutShortMsgDart>('midiOutShortMsg');
      _midiOutClose = _winmm!.lookupFunction<_MidiOutCloseC, _MidiOutCloseDart>('midiOutClose');

      final handlePtr = calloc<IntPtr>();
      // MIDI_MAPPER = -1 (0xFFFFFFFF)
      final res = _midiOutOpen(handlePtr, 0xFFFFFFFF, 0, 0, 0);
      if (res == 0) {
        _hMidiOut = handlePtr.value;
        _available = true;
        // Select Acoustic Grand Piano (Program 0) on Channel 0
        _midiOutShortMsg(_hMidiOut, 0x0000C0);
      }
      calloc.free(handlePtr);
    } catch (_) {
      _available = false;
    }
  }

  void playMidiNote(int midi, {double durationSeconds = 1.0, double volume = 0.4}) {
    if (!_initialized) _init();
    if (!_available || _hMidiOut == 0) return;

    final vel = (volume * 127).clamp(20, 127).toInt();
    final noteOnMsg = 0x90 | (midi << 8) | (vel << 16);
    final noteOffMsg = 0x80 | (midi << 8);

    try {
      _midiOutShortMsg(_hMidiOut, noteOnMsg);
      final timer = Timer(Duration(milliseconds: (durationSeconds * 1000).toInt()), () {
        if (_hMidiOut != 0) {
          try {
            _midiOutShortMsg(_hMidiOut, noteOffMsg);
          } catch (_) {}
        }
      });
      _activeTimers.add(timer);
    } catch (_) {}
  }

  void playChord(List<int> midiNotes, {double durationSeconds = 1.6, double volume = 0.3}) {
    if (!_initialized) _init();
    if (!_available || _hMidiOut == 0 || midiNotes.isEmpty) return;

    final noteVol = (volume / (midiNotes.length > 2 ? (midiNotes.length * 0.4) : 1.0)).clamp(0.15, 0.9);
    final vel = (noteVol * 127).clamp(20, 127).toInt();

    try {
      for (final note in midiNotes) {
        final noteOnMsg = 0x90 | (note << 8) | (vel << 16);
        _midiOutShortMsg(_hMidiOut, noteOnMsg);
      }

      final timer = Timer(Duration(milliseconds: (durationSeconds * 1000).toInt()), () {
        if (_hMidiOut != 0) {
          for (final note in midiNotes) {
            final noteOffMsg = 0x80 | (note << 8);
            try {
              _midiOutShortMsg(_hMidiOut, noteOffMsg);
            } catch (_) {}
          }
        }
      });
      _activeTimers.add(timer);
    } catch (_) {}
  }

  Future<void> playArpeggio(
    List<int> midiNotes, {
    int delayMs = 100,
    double durationSeconds = 1.2,
    double volume = 0.35,
  }) async {
    for (int i = 0; i < midiNotes.length; i++) {
      playMidiNote(midiNotes[i], durationSeconds: durationSeconds, volume: volume);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }

  void playDrum(String type, {double volume = 0.3}) {
    if (!_initialized) _init();
    if (!_available || _hMidiOut == 0) return;

    // General MIDI standard drum notes on Channel 9 (0x99):
    // 36 = Bass Drum 1 (Kick)
    // 38 = Acoustic Snare
    // 42 = Closed Hi-Hat
    // 76 = High Wood Block (Click Accent)
    // 77 = Low Wood Block (Click Regular)
    int drumNote;
    switch (type) {
      case 'kick':
        drumNote = 36;
        break;
      case 'snare':
        drumNote = 38;
        break;
      case 'hihat':
        drumNote = 42;
        break;
      case 'click_accent':
        drumNote = 76;
        break;
      case 'click_regular':
      default:
        drumNote = 77;
        break;
    }

    final vel = (volume * 127).clamp(30, 127).toInt();
    final noteOnMsg = 0x99 | (drumNote << 8) | (vel << 16);
    final noteOffMsg = 0x89 | (drumNote << 8);

    try {
      _midiOutShortMsg(_hMidiOut, noteOnMsg);
      final timer = Timer(const Duration(milliseconds: 150), () {
        if (_hMidiOut != 0) {
          try {
            _midiOutShortMsg(_hMidiOut, noteOffMsg);
          } catch (_) {}
        }
      });
      _activeTimers.add(timer);
    } catch (_) {}
  }

  void stop() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();

    if (_hMidiOut != 0) {
      try {
        _midiOutShortMsg(_hMidiOut, 0x0078B0);
        _midiOutShortMsg(_hMidiOut, 0x007BB0);
        _midiOutShortMsg(_hMidiOut, 0x0078B9);
        _midiOutShortMsg(_hMidiOut, 0x007BB9);
      } catch (_) {}
    }
  }

  void dispose() {
    stop();
    if (_hMidiOut != 0) {
      try {
        _midiOutClose(_hMidiOut);
      } catch (_) {}
      _hMidiOut = 0;
    }
    _initialized = false;
    _available = false;
  }
}
