class AudioSynthesizer {
  static final AudioSynthesizer instance = AudioSynthesizer._internal();
  AudioSynthesizer._internal();

  /// Whether real-time audio synthesis is supported on this platform
  bool get isSupported => false;

  void playMidiNote(int midi, {double durationSeconds = 1.0, double volume = 0.4}) {}

  void playChord(List<int> midiNotes, {double durationSeconds = 1.6, double volume = 0.3}) {}

  Future<void> playArpeggio(
    List<int> midiNotes, {
    int delayMs = 100,
    double durationSeconds = 1.2,
    double volume = 0.35,
  }) async {}

  void playDrum(String type, {double volume = 0.3}) {}

  void stop() {}
}
