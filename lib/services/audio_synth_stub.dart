import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class AudioSynthesizer {
  static final AudioSynthesizer instance = AudioSynthesizer._internal();
  AudioSynthesizer._internal();

  static const MethodChannel _channel = MethodChannel('org.openstageset/audio_synth');

  /// Whether real-time audio synthesis is supported on this platform
  bool get isSupported {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  void playMidiNote(int midi, {double durationSeconds = 1.0, double volume = 0.4}) {
    try {
      _channel.invokeMethod('playMidiNote', {
        'midi': midi,
        'durationSeconds': durationSeconds,
        'volume': volume,
      });
    } catch (_) {}
  }

  void playChord(List<int> midiNotes, {double durationSeconds = 1.6, double volume = 0.3}) {
    try {
      _channel.invokeMethod('playChord', {
        'midiNotes': midiNotes,
        'durationSeconds': durationSeconds,
        'volume': volume,
      });
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
    try {
      _channel.invokeMethod('playDrum', {
        'type': type,
        'volume': volume,
      });
    } catch (_) {}
  }

  void stop() {
    try {
      _channel.invokeMethod('stop');
    } catch (_) {}
  }
}
