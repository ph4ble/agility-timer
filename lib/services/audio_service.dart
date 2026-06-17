import '../engines/tone_generator.dart';
import 'audio_service_stub.dart'
    if (dart.library.html) 'audio_service_web.dart'
    if (dart.library.io) 'audio_service_mobile.dart';

abstract class AudioService {
  factory AudioService() => createAudioService();

  Future<void> init();
  Future<void> playTick(double volume);
  Future<void> playSignal(DirectionSignalType type, double volume);
  Future<void> dispose();
}
