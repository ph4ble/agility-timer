import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import '../engines/tone_generator.dart';
import 'audio_service.dart';

AudioService createAudioService() => WebAudioService();

class WebAudioService implements AudioService {
  String? _tickDataUri;
  final _signalDataUris = <DirectionSignalType, String>{};
  String? _countIn3Uri;
  String? _countIn2Uri;
  String? _countIn1Uri;
  String? _countInStartUri;
  String? _countdownWarningUri;
  String? _endBellUri;
  final _players = <html.AudioElement>[];
  int _poolIndex = 0;

  @override
  Future<void> init() async {
    _tickDataUri = _toDataUri(ToneGenerator.tickWav());
    for (final type in DirectionSignalType.values) {
      _signalDataUris[type] = _toDataUri(ToneGenerator.signalWav(type));
    }
    _countIn3Uri = _toDataUri(ToneGenerator.countIn3Wav());
    _countIn2Uri = _toDataUri(ToneGenerator.countIn2Wav());
    _countIn1Uri = _toDataUri(ToneGenerator.countIn1Wav());
    _countInStartUri = _toDataUri(ToneGenerator.countInStartWav());
    _countdownWarningUri = _toDataUri(ToneGenerator.countdownWarningWav());
    _endBellUri = _toDataUri(ToneGenerator.endBellWav());
    for (int i = 0; i < 6; i++) {
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
    _play(_players.last, uri, volume);
  }

  @override
  Future<void> playCountInBeep(int number, double volume) async {
    final uri = switch (number) {
      3 => _countIn3Uri,
      2 => _countIn2Uri,
      1 => _countIn1Uri,
      _ => _countInStartUri,
    };
    if (uri == null) return;
    _play(_players.last, uri, volume);
  }

  @override
  Future<void> playCountdownWarning(double volume) async {
    if (_countdownWarningUri == null) return;
    _play(_players.last, _countdownWarningUri!, volume);
  }

  @override
  Future<void> playEndBell(double volume) async {
    if (_endBellUri == null) return;
    _play(_players.last, _endBellUri!, volume);
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
