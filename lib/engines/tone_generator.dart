import 'dart:math';
import 'dart:typed_data';

class ToneGenerator {
  static const int _sampleRate = 44100;
  static const int _bitsPerSample = 16;

  static Uint8List tickWav() {
    return _generateWav(frequency: 1800, durationMs: 40, volume: 0.7);
  }

  static Uint8List accentWav() {
    return _generateWav(frequency: 900, durationMs: 60, volume: 0.9);
  }

  // Count-in beeps (different pitch per number)
  static Uint8List countIn3Wav() {
    return _generateWav(frequency: 440, durationMs: 120, volume: 0.7);
  }

  static Uint8List countIn2Wav() {
    return _generateWav(frequency: 660, durationMs: 120, volume: 0.7);
  }

  static Uint8List countIn1Wav() {
    return _generateWav(frequency: 880, durationMs: 120, volume: 0.7);
  }

  static Uint8List countInStartWav() {
    return _generateWav(frequency: 1200, durationMs: 200, volume: 0.9);
  }

  // 10-second countdown warning — three quick beeps
  static Uint8List countdownWarningWav() {
    return _multiBeepWav(1000, 60, 50, 3, 0.8);
  }

  // Final 5-second warning — faster beeps
  static Uint8List countdownFinalWav() {
    return _multiBeepWav(1200, 40, 30, 5, 0.9);
  }

  // End bell — descending chime
  static Uint8List endBellWav() {
    return _chimeWav([1200, 1000, 800, 600], 200, 40, 0.9);
  }

  /// Generic alert sweep (for tone mode).
  static Uint8List signalWav(DirectionSignalType type) {
    switch (type) {
      case DirectionSignalType.alert:
        return _generateSweepWav(600, 1200, 150, 0.9);
      case DirectionSignalType.whistle:
        return _generateSweepWav(1200, 2000, 120, 0.85);
      case DirectionSignalType.drum:
        return _generateWav(frequency: 120, durationMs: 100, volume: 1.0);
      case DirectionSignalType.dirForward:
        return _dirForwardWav();
      case DirectionSignalType.dirBackward:
        return _dirBackwardWav();
      case DirectionSignalType.dirLeft:
        return _dirLeftWav();
      case DirectionSignalType.dirRight:
        return _dirRightWav();
    }
  }

  /// Rapid ascending two-note
  static Uint8List _dirForwardWav() {
    return _twoNoteWav(800, 1300, 45, 55, 0.95);
  }

  /// Rapid descending two-note
  static Uint8List _dirBackwardWav() {
    return _twoNoteWav(1200, 600, 45, 55, 0.95);
  }

  /// Sharp rising chirp
  static Uint8List _dirLeftWav() {
    return _generateSweepWav(1600, 2600, 75, 0.9);
  }

  /// Sharp falling chirp
  static Uint8List _dirRightWav() {
    return _generateSweepWav(2600, 1400, 75, 0.9);
  }

  /// Multiple quick beeps with gaps
  static Uint8List _multiBeepWav(double freq, int durMs, int gapMs, int count, double volume) {
    final beepSamples = (_sampleRate * durMs / 1000).round();
    final gapSamples = (_sampleRate * gapMs / 1000).round();
    final total = (beepSamples + gapSamples) * count;
    final data = Int16List(total);

    for (int b = 0; b < count; b++) {
      final offset = b * (beepSamples + gapSamples);
      for (int i = 0; i < beepSamples; i++) {
        final t = i / _sampleRate;
        final env = max(0, 1.0 - i / beepSamples);
        data[offset + i] = (volume * env * sin(2 * pi * freq * t) * 32767).round().clamp(-32768, 32767);
      }
    }
    return _encodeWav(data);
  }

  /// Descending chime of multiple notes
  static Uint8List _chimeWav(List<double> freqs, int durMs, int gapMs, double volume) {
    final noteSamples = (_sampleRate * durMs / 1000).round();
    final gapSamples = (_sampleRate * gapMs / 1000).round();
    final total = (noteSamples + gapSamples) * freqs.length;
    final data = Int16List(total);

    for (int n = 0; n < freqs.length; n++) {
      final offset = n * (noteSamples + gapSamples);
      final freq = freqs[n];
      for (int i = 0; i < noteSamples; i++) {
        final t = i / _sampleRate;
        final env = max(0, 1.0 - i / noteSamples);
        data[offset + i] = (volume * env * sin(2 * pi * freq * t) * 32767).round().clamp(-32768, 32767);
      }
    }
    return _encodeWav(data);
  }

  /// Two rapid notes with a tiny gap between them.
  static Uint8List _twoNoteWav(
    double freq1,
    double freq2,
    int dur1Ms,
    int dur2Ms,
    double volume,
  ) {
    final gapSamples = (_sampleRate * 15 / 1000).round();
    final n1 = (_sampleRate * dur1Ms / 1000).round();
    final n2 = (_sampleRate * dur2Ms / 1000).round();
    final total = n1 + gapSamples + n2;
    final data = Int16List(total);

    int idx = 0;
    for (int i = 0; i < n1; i++, idx++) {
      final t = i / _sampleRate;
      final env = max(0, 1.0 - i / n1 * 0.3);
      data[idx] = (volume * env * sin(2 * pi * freq1 * t) * 32767).round().clamp(-32768, 32767);
    }
    idx += gapSamples;
    for (int i = 0; i < n2; i++, idx++) {
      final t = i / _sampleRate;
      final env = max(0, 1.0 - i / n2);
      data[idx] = (volume * env * sin(2 * pi * freq2 * t) * 32767).round().clamp(-32768, 32767);
    }

    return _encodeWav(data);
  }

  static Uint8List _generateWav({
    required double frequency,
    required int durationMs,
    required double volume,
  }) {
    final numSamples = (_sampleRate * durationMs / 1000).round();
    final data = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final envelope = max(0, 1.0 - i / numSamples);
      final sample = (volume * envelope * sin(2 * pi * frequency * t) * 32767).round();
      data[i] = sample.clamp(-32768, 32767);
    }
    return _encodeWav(data);
  }

  static Uint8List _generateSweepWav(double startFreq, double endFreq, int durationMs, double volume) {
    final numSamples = (_sampleRate * durationMs / 1000).round();
    final data = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final envelope = max(0, 1.0 - i / numSamples);
      final freq = startFreq + (endFreq - startFreq) * (i / numSamples);
      final sample = (volume * envelope * sin(2 * pi * freq * t) * 32767).round();
      data[i] = sample.clamp(-32768, 32767);
    }
    return _encodeWav(data);
  }

  static Uint8List _encodeWav(Int16List samples) {
    final byteRate = _sampleRate * _bitsPerSample ~/ 8;
    final dataSize = samples.length * (_bitsPerSample ~/ 8);
    final fileSize = 36 + dataSize;
    final header = ByteData(44);

    header.setUint8(0, 0x52); header.setUint8(1, 0x49);
    header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57); header.setUint8(9, 0x41);
    header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    header.setUint8(12, 0x66); header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, _bitsPerSample ~/ 8, Endian.little);
    header.setUint16(34, _bitsPerSample, Endian.little);
    header.setUint8(36, 0x64); header.setUint8(37, 0x61);
    header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);

    final wav = Uint8List(44 + dataSize);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + dataSize, samples.buffer.asUint8List());
    return wav;
  }
}

enum DirectionSignalType {
  alert,
  whistle,
  drum,
  dirForward,
  dirBackward,
  dirLeft,
  dirRight,
}
