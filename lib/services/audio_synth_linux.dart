import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'audio_synth_service.dart';

/// Real-time audio synthesizer for Linux desktops using PipeWire/PulseAudio/ALSA.
class LinuxAudioSynth {
  static final LinuxAudioSynth instance = LinuxAudioSynth._();
  LinuxAudioSynth._();

  bool _initialized = false;
  String? _cliPlayer; // 'pw-play', 'paplay', or 'aplay'
  final List<Process> _activeProcesses = [];
  final Random _random = Random();

  bool get isSupported => Platform.isLinux;

  void _init() {
    if (_initialized) return;
    _initialized = true;
    if (!Platform.isLinux) return;

    for (final cmd in ['pw-play', 'paplay', 'aplay']) {
      try {
        final res = Process.runSync('which', [cmd]);
        if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
          _cliPlayer = cmd;
          break;
        }
      } catch (_) {}
    }
  }

  /// Synthesize and play a single MIDI note
  void playMidiNote(int midi, {double durationSeconds = 1.0, double volume = 0.4}) {
    if (!_initialized) _init();
    final freq = MusicTheory.midiToFrequency(midi);
    final wav = _synthesizeNoteWav([freq], durationSeconds, volume);
    _playWav(wav);
  }

  /// Synthesize and play a chord polyphonically
  void playChord(List<int> midiNotes, {double durationSeconds = 1.6, double volume = 0.3}) {
    if (!_initialized) _init();
    if (midiNotes.isEmpty) return;
    final freqs = midiNotes.map((m) => MusicTheory.midiToFrequency(m)).toList();
    final wav = _synthesizeNoteWav(freqs, durationSeconds, volume);
    _playWav(wav);
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

  /// Synthesize and play drum percussion elements
  void playDrum(String type, {double volume = 0.3}) {
    if (!_initialized) _init();
    final wav = _synthesizeDrumWav(type, volume);
    if (wav != null) {
      _playWav(wav);
    }
  }

  void stop() {
    for (final proc in _activeProcesses) {
      try {
        proc.kill(ProcessSignal.sigkill);
      } catch (_) {}
    }
    _activeProcesses.clear();
  }

  void _playWav(Uint8List wavBytes) {
    if (_cliPlayer == null) _init();
    final player = _cliPlayer;
    if (player == null) return;

    try {
      final List<String> args = (player == 'aplay') ? ['-q', '-'] : ['-'];
      Process.start(player, args).then((proc) {
        _activeProcesses.add(proc);
        proc.stdin.add(wavBytes);
        proc.stdin.close();
        proc.exitCode.then((_) {
          _activeProcesses.remove(proc);
        });
      }).catchError((_) {});
    } catch (_) {}
  }

  /// Synthesize dual-oscillator acoustic piano sound with ADSR envelope
  Uint8List _synthesizeNoteWav(List<double> frequencies, double durationSec, double volume) {
    const sampleRate = 44100;
    final totalSamples = max(1, (durationSec * sampleRate).toInt());
    final pcm = Int16List(totalSamples);
    final noteVol = (volume / max(1.0, frequencies.length * 0.45)).clamp(0.05, 0.6);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;

      // ADSR Envelope: 20ms attack, decay to 50% at 250ms, exponential release fade
      double env;
      if (t < 0.02) {
        env = t / 0.02;
      } else if (t < 0.25) {
        env = 1.0 - 0.5 * ((t - 0.02) / 0.23);
      } else {
        final rem = ((t - 0.25) / max(0.01, durationSec - 0.25)).clamp(0.0, 1.0);
        env = 0.5 * (1.0 - rem);
      }

      double sampleVal = 0.0;
      for (final freq in frequencies) {
        // Triangle wave body
        final phase = (t * freq) % 1.0;
        final tri = 4.0 * (phase - 0.5).abs() - 1.0;
        // Sine wave overtone (1 octave higher)
        final overtone = sin(2.0 * pi * (freq * 2.0) * t) * 0.15;
        sampleVal += (tri + overtone);
      }

      // Micro ramp-in during first 88 samples (~2ms) to prevent edge click
      final ramp = i < 88 ? (i / 88.0) : 1.0;
      final out = (sampleVal * env * noteVol * ramp).clamp(-1.0, 1.0);
      pcm[i] = (out * 32767.0).toInt();
    }

    return _encodeWav(pcm, sampleRate);
  }

  /// Synthesize acoustic drum and metronome percussion
  Uint8List? _synthesizeDrumWav(String type, double volume) {
    const sampleRate = 44100;
    double durationSec;
    switch (type) {
      case 'kick': durationSec = 0.28; break;
      case 'snare': durationSec = 0.20; break;
      case 'hihat': durationSec = 0.05; break;
      case 'click_accent': durationSec = 0.05; break;
      case 'click_regular': durationSec = 0.04; break;
      default: return null;
    }

    final totalSamples = (durationSec * sampleRate).toInt();
    final pcm = Int16List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      double sampleVal = 0.0;

      switch (type) {
        case 'kick':
          final freq = 36.0 + (150.0 - 36.0) * exp(-t * 22.0);
          final env = exp(-t * 12.0);
          sampleVal = sin(2.0 * pi * freq * t) * env * 0.95;
          break;
        case 'snare':
          final freq = 65.0 + (220.0 - 65.0) * exp(-t * 20.0);
          final toneEnv = exp(-t * 16.0);
          final phase = (t * freq) % 1.0;
          final tone = (4.0 * (phase - 0.5).abs() - 1.0) * toneEnv * 0.6;
          final noise = (_random.nextDouble() * 2.0 - 1.0) * exp(-t * 24.0) * 0.4;
          sampleVal = tone + noise;
          break;
        case 'hihat':
          final noise = (_random.nextDouble() * 2.0 - 1.0);
          final env = exp(-t * 70.0);
          sampleVal = noise * env * 0.35;
          break;
        case 'click_accent':
          final freq = 600.0 + 600.0 * exp(-t * 50.0);
          final env = exp(-t * 40.0);
          sampleVal = sin(2.0 * pi * freq * t) * env * 0.8;
          break;
        case 'click_regular':
          final freq = 400.0 + 400.0 * exp(-t * 60.0);
          final env = exp(-t * 50.0);
          sampleVal = sin(2.0 * pi * freq * t) * env * 0.5;
          break;
      }

      final ramp = i < 88 ? (i / 88.0) : 1.0;
      final out = (sampleVal * volume * ramp).clamp(-1.0, 1.0);
      pcm[i] = (out * 32767.0).toInt();
    }

    return _encodeWav(pcm, sampleRate);
  }

  /// Package raw 16-bit PCM samples into standard RIFF WAV container
  Uint8List _encodeWav(Int16List samples, int sampleRate) {
    final byteCount = samples.length * 2;
    final totalSize = 44 + byteCount;
    final data = ByteData(totalSize);

    // RIFF header
    data.setUint8(0, 0x52); // 'R'
    data.setUint8(1, 0x49); // 'I'
    data.setUint8(2, 0x46); // 'F'
    data.setUint8(3, 0x46); // 'F'
    data.setUint32(4, totalSize - 8, Endian.little);
    data.setUint8(8, 0x57); // 'W'
    data.setUint8(9, 0x41); // 'A'
    data.setUint8(10, 0x56); // 'V'
    data.setUint8(11, 0x45); // 'E'

    // fmt chunk
    data.setUint8(12, 0x66); // 'f'
    data.setUint8(13, 0x6D); // 'm'
    data.setUint8(14, 0x74); // 't'
    data.setUint8(15, 0x20); // ' '
    data.setUint32(16, 16, Endian.little); // chunk size
    data.setUint16(20, 1, Endian.little); // audio format (PCM)
    data.setUint16(22, 1, Endian.little); // num channels (1 = mono)
    data.setUint32(24, sampleRate, Endian.little); // sample rate
    data.setUint32(28, sampleRate * 2, Endian.little); // byte rate (sampleRate * 1 * 2)
    data.setUint16(32, 2, Endian.little); // block align
    data.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    data.setUint8(36, 0x64); // 'd'
    data.setUint8(37, 0x61); // 'a'
    data.setUint8(38, 0x74); // 't'
    data.setUint8(39, 0x61); // 'a'
    data.setUint32(40, byteCount, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      data.setInt16(44 + (i * 2), samples[i], Endian.little);
    }

    return data.buffer.asUint8List();
  }
}
