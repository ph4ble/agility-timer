enum TrainingMode { free, timed, progressive, interval }

enum SignalSoundType { tone, voiceDirection }

enum Direction {
  forward,
  backward,
  left,
  right;

  String get label {
    switch (this) {
      case Direction.forward: return '前';
      case Direction.backward: return '后';
      case Direction.left: return '左';
      case Direction.right: return '右';
    }
  }
}

class TrainingConfig {
  int bpm;
  int beatSubdivision;
  int beatsPerBar;
  int minBeatsToChange;
  int maxBeatsToChange;
  int directionCount;
  Duration trainingDuration;
  TrainingMode mode;
  int intervalWorkSeconds;
  int intervalRestSeconds;
  int intervalRounds;
  bool enableVibration;
  double regularVolume;
  double signalVolume;
  SignalSoundType signalSoundType;
  bool enableRandomBpm;
  int randomBpmPercent;

  TrainingConfig({
    this.bpm = 100,
    this.beatSubdivision = 1,
    this.beatsPerBar = 4,
    this.minBeatsToChange = 4,
    this.maxBeatsToChange = 8,
    this.directionCount = 2,
    this.trainingDuration = const Duration(minutes: 3),
    this.mode = TrainingMode.free,
    this.intervalWorkSeconds = 30,
    this.intervalRestSeconds = 10,
    this.intervalRounds = 5,
    this.enableVibration = false,
    this.regularVolume = 0.8,
    this.signalVolume = 1.0,
    this.signalSoundType = SignalSoundType.tone,
    this.enableRandomBpm = false,
    this.randomBpmPercent = 10,
  });

  double get beatIntervalMs => 60000.0 / bpm / beatSubdivision;

  List<Direction> get activeDirections {
    return Direction.values.take(directionCount).toList();
  }
}
