import 'dart:async';
import 'dart:math';

import '../models/training_config.dart';
import 'metronome_engine.dart';
import 'tone_generator.dart';

enum TrainingPhase { idle, countIn, running, rest, paused, finished }

class SignalEvent {
  final Direction direction;
  final DirectionSignalType signalType;

  SignalEvent(this.direction, this.signalType);
}

class TrainingState {
  final TrainingPhase phase;
  final int elapsedSeconds;
  final int totalSeconds;
  final int beatCount;
  final int signalCount;
  final int currentBpm;
  final int roundNumber;
  final int totalRounds;
  final Direction? lastDirection;

  TrainingState({
    this.phase = TrainingPhase.idle,
    this.elapsedSeconds = 0,
    this.totalSeconds = 0,
    this.beatCount = 0,
    this.signalCount = 0,
    this.currentBpm = 100,
    this.roundNumber = 1,
    this.totalRounds = 1,
    this.lastDirection,
  });
}

class TrainingEngine {
  final TrainingConfig config;
  final MetronomeEngine _metronome = MetronomeEngine();

  final _stateController = StreamController<TrainingState>.broadcast();
  final _signalController = StreamController<SignalEvent>.broadcast();
  final _beatController = StreamController<BeatEvent>.broadcast();
  final _tickController = StreamController<void>.broadcast();

  final Random _random = Random();
  Timer? _durationTimer;
  Timer? _bpmTimer;
  StreamSubscription<BeatEvent>? _beatSub;

  int _signalCount = 0;
  int _beatsSinceLastSignal = 0;
  int _elapsedSeconds = 0;
  int _roundNumber = 1;
  int _currentBpm;
  int _baseBpm;
  Direction? _lastDirection;
  TrainingPhase _phase = TrainingPhase.idle;

  TrainingEngine(this.config) : _currentBpm = config.bpm, _baseBpm = config.bpm;

  Stream<TrainingState> get stateStream => _stateController.stream;
  Stream<SignalEvent> get signalStream => _signalController.stream;
  Stream<BeatEvent> get beatStream => _beatController.stream;
  Stream<void> get tickStream => _tickController.stream;

  TrainingPhase get phase => _phase;
  int get signalCount => _signalCount;
  int get elapsedSeconds => _elapsedSeconds;
  int get currentBpm => _currentBpm;

  Future<void> start() async {
    _signalCount = 0;
    _beatsSinceLastSignal = 0;
    _elapsedSeconds = 0;
    _roundNumber = 1;
    _lastDirection = null;
    _currentBpm = config.bpm;
    _baseBpm = config.bpm;

    final intervalMs = config.beatIntervalMs;
    _metronome.configure(
      beatIntervalMs: intervalMs,
      beatsPerBar: config.beatsPerBar,
    );

    _phase = TrainingPhase.countIn;
    _emitState();

    _beatSub = _metronome.beatStream.listen(_onBeat);

    // 3-2-1 count-in
    for (int i = 3; i >= 1; i--) {
      _beatController.add(BeatEvent(
        beatNumber: i,
        isCountIn: true,
        isFirstBeat: i == 1,
      ));
      _tickController.add(null);
      await Future.delayed(Duration(milliseconds: intervalMs.round()));
    }

    _phase = TrainingPhase.running;
    _emitState();
    _metronome.start();
    _startDurationTracking();
    _startRandomBpmVariation();
  }

  void _startRandomBpmVariation() {
    if (!config.enableRandomBpm) return;
    // Vary BPM every 2-4 bars
    _bpmTimer = Timer.periodic(
      Duration(milliseconds: (config.beatIntervalMs * config.beatsPerBar * 2).round()),
      (_) => _varyBpm(),
    );
  }

  void _varyBpm() {
    final range = (config.bpm * config.randomBpmPercent / 100).round();
    final minBpm = (config.bpm - range).clamp(40, 500);
    final maxBpm = (config.bpm + range).clamp(40, 500);
    _currentBpm = minBpm + _random.nextInt(max(maxBpm - minBpm, 1));
    final intervalMs = 60000.0 / _currentBpm / config.beatSubdivision;
    _metronome.configure(beatIntervalMs: intervalMs, beatsPerBar: config.beatsPerBar);
    _emitState();
  }

  void _onBeat(BeatEvent beat) {
    _beatsSinceLastSignal++;

    _beatController.add(beat);
    _tickController.add(null);

    if (_beatsSinceLastSignal >= config.minBeatsToChange) {
      final maxBeats = config.maxBeatsToChange;
      final chance = _beatsSinceLastSignal >= maxBeats
          ? 1.0
          : 1.0 / (maxBeats - _beatsSinceLastSignal + 1);
      if (_random.nextDouble() < chance) {
        _fireSignal();
      }
    }
  }

  void _fireSignal() {
    _beatsSinceLastSignal = 0;
    _signalCount++;

    final directions = config.activeDirections;
    Direction dir;
    if (directions.length > 1 && _lastDirection != null) {
      final others = directions.where((d) => d != _lastDirection).toList();
      dir = others[_random.nextInt(others.length)];
    } else {
      dir = directions[_random.nextInt(directions.length)];
    }
    _lastDirection = dir;

    final signalType = _pickSignalType(dir);
    _signalController.add(SignalEvent(dir, signalType));
  }

  DirectionSignalType _pickSignalType(Direction dir) {
    if (config.signalSoundType == SignalSoundType.voiceDirection) {
      // Use direction-specific rapid two-note patterns
      switch (dir) {
        case Direction.forward: return DirectionSignalType.dirForward;
        case Direction.backward: return DirectionSignalType.dirBackward;
        case Direction.left: return DirectionSignalType.dirLeft;
        case Direction.right: return DirectionSignalType.dirRight;
      }
    }
    // Tone mode: single consistent alert sound for all directions
    return DirectionSignalType.alert;
  }

  void _startDurationTracking() {
    _durationTimer?.cancel();

    if (config.mode == TrainingMode.free) {
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        _emitState();
      });
    } else if (config.mode == TrainingMode.timed) {
      final totalSecs = config.trainingDuration.inSeconds;
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        _emitState();
        if (_elapsedSeconds >= totalSecs) stop();
      });
    } else if (config.mode == TrainingMode.progressive) {
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        _emitState();
      });
      // Progressive overrides random BPM: increase every 20s
      Timer.periodic(const Duration(seconds: 20), (_) {
        if (_phase == TrainingPhase.running && _currentBpm < 500) {
          _baseBpm = min(500, _baseBpm + 5);
          _currentBpm = _baseBpm;
          final intervalMs = 60000.0 / _currentBpm / config.beatSubdivision;
          _metronome.configure(beatIntervalMs: intervalMs, beatsPerBar: config.beatsPerBar);
          _emitState();
        }
      });
    } else if (config.mode == TrainingMode.interval) {
      _startIntervalWorkPhase();
    }
  }

  void _startIntervalWorkPhase() {
    _phase = TrainingPhase.running;
    _emitState();
    _elapsedSeconds = 0;

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      _emitState();
      if (_elapsedSeconds >= config.intervalWorkSeconds) {
        if (_roundNumber >= config.intervalRounds) {
          stop();
        } else {
          _startRestPhase();
        }
      }
    });
  }

  void _startRestPhase() {
    _phase = TrainingPhase.rest;
    _emitState();
    _elapsedSeconds = 0;

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      _emitState();
      if (_elapsedSeconds >= config.intervalRestSeconds) {
        _roundNumber++;
        _startIntervalWorkPhase();
      }
    });
  }

  void stop() {
    _phase = TrainingPhase.finished;
    _emitState();
    _metronome.stop();
    _durationTimer?.cancel();
    _bpmTimer?.cancel();
    _beatSub?.cancel();
  }

  void dispose() {
    stop();
    _metronome.dispose();
    _stateController.close();
    _signalController.close();
    _beatController.close();
    _tickController.close();
  }

  void _emitState() {
    int totalSecs = 0;
    if (config.mode == TrainingMode.timed) {
      totalSecs = config.trainingDuration.inSeconds;
    }

    _stateController.add(TrainingState(
      phase: _phase,
      elapsedSeconds: _elapsedSeconds,
      totalSeconds: totalSecs,
      beatCount: _metronome.beatCount,
      signalCount: _signalCount,
      currentBpm: _currentBpm,
      roundNumber: _roundNumber,
      totalRounds: config.mode == TrainingMode.interval ? config.intervalRounds : 1,
      lastDirection: _lastDirection,
    ));
  }
}
