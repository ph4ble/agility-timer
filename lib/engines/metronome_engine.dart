import 'dart:async';

class BeatEvent {
  final int beatNumber;
  final bool isFirstBeat;
  final bool isCountIn;
  final DateTime timestamp;

  BeatEvent({
    required this.beatNumber,
    this.isFirstBeat = false,
    this.isCountIn = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class MetronomeEngine {
  final _beatController = StreamController<BeatEvent>.broadcast();
  Timer? _timer;
  int _beatCount = 0;
  int _beatsPerBar = 4;
  double _intervalMs = 500;

  Stream<BeatEvent> get beatStream => _beatController.stream;
  int get beatCount => _beatCount;
  bool get isRunning => _timer != null;

  void configure({required double beatIntervalMs, int beatsPerBar = 4}) {
    _intervalMs = beatIntervalMs;
    _beatsPerBar = beatsPerBar;
  }

  Future<void> countIn(int count, {double intervalMs = 0}) async {
    final interval = intervalMs > 0 ? intervalMs : _intervalMs;
    for (int i = 0; i < count; i++) {
      final isLast = i == count - 1;
      _beatController.add(BeatEvent(
        beatNumber: i + 1,
        isCountIn: true,
        isFirstBeat: isLast,
      ));
      await Future.delayed(Duration(milliseconds: interval.round()));
    }
  }

  void start() {
    _beatCount = 0;
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: _intervalMs.round()),
      _onTick,
    );
    // Fire first beat immediately
    _onTick(null);
  }

  void _onTick(Timer? t) {
    _beatCount++;
    final isFirst = (_beatCount - 1) % _beatsPerBar == 0;
    _beatController.add(BeatEvent(
      beatNumber: _beatCount,
      isFirstBeat: isFirst,
    ));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _beatController.close();
  }
}
