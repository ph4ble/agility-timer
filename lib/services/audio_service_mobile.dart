import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../engines/tone_generator.dart';
import 'audio_service.dart';

AudioService createAudioService() => MobileAudioService();

class MobileAudioService implements AudioService {
  final _pool = <AudioPlayer>[];
  int _poolIndex = 0;

  @override
  Future<void> init() async {
    for (int i = 0; i < 4; i++) {
      final player = AudioPlayer();
      await player.setSource(BytesSource(ToneGenerator.tickWav()));
      _pool.add(player);
    }
  }

  @override
  Future<void> playTick(double volume) async {
    if (_pool.isEmpty) return;
    _poolIndex = (_poolIndex + 1) % _pool.length;
    final player = _pool[_poolIndex];
    await player.stop();
    await player.setSource(BytesSource(ToneGenerator.tickWav()));
    await player.setVolume(volume);
    await player.resume();
  }

  @override
  Future<void> playSignal(DirectionSignalType type, double volume) async {
    if (_pool.isEmpty) return;
    final player = _pool.last;
    await player.stop();
    await player.setSource(BytesSource(ToneGenerator.signalWav(type)));
    await player.setVolume(volume);
    await player.resume();
  }

  @override
  Future<void> dispose() async {
    for (final p in _pool) {
      p.dispose();
    }
    _pool.clear();
  }
}
