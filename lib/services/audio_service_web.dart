import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import '../engines/tone_generator.dart';
import 'audio_service.dart';

AudioService createAudioService() => WebAudioService();

class WebAudioService implements AudioService {
  String? _tickDataUri;
  final _signalDataUris = <DirectionSignalType, String>{};
  final _players = <html.AudioElement>[];
  int _poolIndex = 0;

  @override
  Future<void> init() async {
    _tickDataUri = _toDataUri(ToneGenerator.tickWav());
    for (final type in DirectionSignalType.values) {
      _signalDataUris[type] = _toDataUri(ToneGenerator.signalWav(type));
    }
    // Pre-create pool of audio elements
    for (int i = 0; i < 4; i++) {
      _players.add(html.AudioElement());
    }
  }

  String _toDataUri(Uint8List wav) {
    return 'data:audio/wav;base64,${base64Encode(wav)}';
  }

  @override
  Future<void> playTick(double volume) async {
    if (_tickDataUri == null) return;
    _poolIndex = (_poolIndex + 1) % _players.length;
    final player = _players[_poolIndex];
    _play(player, _tickDataUri!, volume);
  }

  @override
  Future<void> playSignal(DirectionSignalType type, double volume) async {
    final uri = _signalDataUris[type];
    if (uri == null) return;
    final player = _players.last;
    _play(player, uri, volume);
  }

  void _play(html.AudioElement player, String uri, double volume) {
    player.volume = volume;
    player.src = uri;
    player.play();
  }

  @override
  Future<void> dispose() async {
    for (final p in _players) {
      p.remove();
    }
    _players.clear();
  }
}
