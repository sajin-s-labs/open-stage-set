import 'package:web/web.dart' as web;
import 'audio_synth_service.dart';

class AudioSynthesizer {
  static final AudioSynthesizer instance = AudioSynthesizer._internal();
  AudioSynthesizer._internal();

  /// Whether real-time audio synthesis is supported on this platform
  bool get isSupported => true;

  web.AudioContext? _audioContext;

  web.AudioContext get _ctx {
    _audioContext ??= web.AudioContext();
    if (_audioContext!.state == 'suspended') {
      _audioContext!.resume();
    }
    return _audioContext!;
  }

  /// Play a single musical MIDI note with rich electric piano tone
  void playMidiNote(int midi, {double durationSeconds = 1.0, double volume = 0.4}) {
    try {
      final frequency = MusicTheory.midiToFrequency(midi);
      _playFrequency(frequency, durationSeconds: durationSeconds, volume: volume);
    } catch (_) {}
  }

  /// Play a polyphonic chord simultaneously
  void playChord(List<int> midiNotes, {double durationSeconds = 1.6, double volume = 0.3}) {
    try {
      final noteVolume = (volume / (midiNotes.length > 2 ? (midiNotes.length * 0.45) : 1.0)).clamp(0.05, 0.5);
      for (final midi in midiNotes) {
        final freq = MusicTheory.midiToFrequency(midi);
        _playFrequency(freq, durationSeconds: durationSeconds, volume: noteVolume);
      }
    } catch (_) {}
  }

  /// Play chord notes sequentially as an arpeggio
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

  /// Core sound synthesis using dual oscillators with warm ADSR envelope
  void _playFrequency(double frequency, {double durationSeconds = 1.2, double volume = 0.35}) {
    final ctx = _ctx;
    final now = ctx.currentTime;

    // 1. Primary body oscillator (triangle wave)
    final osc = ctx.createOscillator();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(frequency, now);

    // 2. Overtone oscillator for sparkle / acoustic warmth (sine wave 1 octave higher)
    final overtone = ctx.createOscillator();
    overtone.type = 'sine';
    overtone.frequency.setValueAtTime(frequency * 2.0, now);

    // 3. Main gain envelope
    final gain = ctx.createGain();
    gain.gain.setValueAtTime(0.0001, now);
    // Smooth attack (no clicks)
    gain.gain.exponentialRampToValueAtTime(volume, now + 0.02);
    // Natural acoustic decay
    gain.gain.exponentialRampToValueAtTime(volume * 0.5, now + 0.25);
    // Release fade
    gain.gain.exponentialRampToValueAtTime(0.0001, now + durationSeconds);

    // 4. Overtone gain envelope
    final overtoneGain = ctx.createGain();
    overtoneGain.gain.setValueAtTime(volume * 0.12, now);
    overtoneGain.gain.exponentialRampToValueAtTime(0.0001, now + (durationSeconds * 0.6));

    // Connect audio graph
    osc.connect(gain);
    overtone.connect(overtoneGain);
    gain.connect(ctx.destination);
    overtoneGain.connect(ctx.destination);

    // Trigger sound
    osc.start(now);
    overtone.start(now);

    osc.stop(now + durationSeconds);
    overtone.stop(now + durationSeconds);
  }

  /// Synthesize acoustic drum elements (kick, snare, hihat, metronome clicks)
  void playDrum(String type, {double volume = 0.3}) {
    try {
      final ctx = _ctx;
      final now = ctx.currentTime;
      final v = volume.clamp(0.0, 1.0);
      if (v <= 0.001) return;

      switch (type) {
        case 'kick':
          final osc = ctx.createOscillator();
          final gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(150.0, now);
          osc.frequency.exponentialRampToValueAtTime(36.0, now + 0.12);
          gain.gain.setValueAtTime(v * 0.9, now);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.28);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now);
          osc.stop(now + 0.3);
          break;
        case 'snare':
          final toneOsc = ctx.createOscillator();
          final toneGain = ctx.createGain();
          toneOsc.type = 'triangle';
          toneOsc.frequency.setValueAtTime(220.0, now);
          toneOsc.frequency.exponentialRampToValueAtTime(65.0, now + 0.1);
          toneGain.gain.setValueAtTime(v * 0.6, now);
          toneGain.gain.exponentialRampToValueAtTime(0.0001, now + 0.18);
          toneOsc.connect(toneGain);
          toneGain.connect(ctx.destination);
          toneOsc.start(now);
          toneOsc.stop(now + 0.2);

          final snapOsc = ctx.createOscillator();
          final snapGain = ctx.createGain();
          snapOsc.type = 'square';
          snapOsc.frequency.setValueAtTime(800.0, now);
          snapOsc.frequency.exponentialRampToValueAtTime(120.0, now + 0.08);
          snapGain.gain.setValueAtTime(v * 0.3, now);
          snapGain.gain.exponentialRampToValueAtTime(0.0001, now + 0.14);
          snapOsc.connect(snapGain);
          snapGain.connect(ctx.destination);
          snapOsc.start(now);
          snapOsc.stop(now + 0.16);
          break;
        case 'hihat':
          final osc = ctx.createOscillator();
          final gain = ctx.createGain();
          osc.type = 'square';
          osc.frequency.setValueAtTime(4500.0, now);
          gain.gain.setValueAtTime(v * 0.22, now);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.045);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now);
          osc.stop(now + 0.05);
          break;
        case 'click_accent':
          final osc = ctx.createOscillator();
          final gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(1200.0, now);
          osc.frequency.exponentialRampToValueAtTime(600.0, now + 0.03);
          gain.gain.setValueAtTime(v * 0.6, now);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.05);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now);
          osc.stop(now + 0.06);
          break;
        case 'click_regular':
          final osc = ctx.createOscillator();
          final gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(800.0, now);
          osc.frequency.exponentialRampToValueAtTime(400.0, now + 0.025);
          gain.gain.setValueAtTime(v * 0.35, now);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.04);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now);
          osc.stop(now + 0.05);
          break;
      }
    } catch (_) {}
  }

  /// Stop current playback
  void stop() {
    try {
      _audioContext?.close();
      _audioContext = null;
    } catch (_) {}
  }
}
