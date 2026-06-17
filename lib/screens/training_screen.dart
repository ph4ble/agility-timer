import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engines/metronome_engine.dart';
import '../engines/tone_generator.dart';
import '../engines/training_engine.dart';
import '../models/training_config.dart';
import '../services/audio_service.dart';
import '../widgets/beat_ring.dart';
import '../widgets/direction_overlay.dart';

class TrainingScreen extends StatefulWidget {
  final TrainingConfig config;

  const TrainingScreen({super.key, required this.config});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with TickerProviderStateMixin {
  final GlobalKey<BeatRingState> _beatRingKey = GlobalKey();
  final GlobalKey<DirectionOverlayState> _directionKey = GlobalKey();

  late TrainingEngine _engine;
  late AudioService _audio;

  StreamSubscription<BeatEvent>? _beatSub;
  StreamSubscription<SignalEvent>? _signalSub;
  StreamSubscription<TrainingState>? _stateSub;
  StreamSubscription<void>? _tickSub;
  StreamSubscription<CountdownEvent>? _countdownSub;
  StreamSubscription<void>? _endBellSub;

  TrainingState _state = TrainingState();
  int _countInValue = 3;
  int _countdownRemaining = -1;
  bool _isPaused = false;
  late AnimationController _timerFlashController;
  late Animation<double> _timerFlashAnim;

  @override
  void initState() {
    super.initState();
    _timerFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _timerFlashAnim = Tween(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _timerFlashController, curve: Curves.easeInOut),
    );
    _engine = TrainingEngine(widget.config);
    _audio = AudioService();
    _initAndStart();
  }

  Future<void> _initAndStart() async {
    await _audio.init();
    if (!mounted) return;
    _startTraining();
  }

  Future<void> _startTraining() async {
    _stateSub = _engine.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _state = state;
          _isPaused = state.phase == TrainingPhase.paused;
        });
      }
      if (state.phase == TrainingPhase.finished) {
        _showFinishedDialog();
      }
    });

    _signalSub = _engine.signalStream.listen((signal) {
      _audio.playSignal(signal.signalType, widget.config.signalVolume);
      _directionKey.currentState?.showDirection(signal.direction);
      HapticFeedback.heavyImpact();
    });

    _tickSub = _engine.tickStream.listen((_) {
      _audio.playTick(widget.config.regularVolume);
      _beatRingKey.currentState?.pulse();
    });

    _beatSub = _engine.beatStream.listen((beat) {
      if (beat.isCountIn) {
        if (beat.beatNumber > 0) {
          if (mounted) setState(() => _countInValue = beat.beatNumber);
          _audio.playCountInBeep(beat.beatNumber, widget.config.regularVolume);
        } else {
          if (mounted) setState(() => _countInValue = 0);
          _audio.playCountInBeep(0, widget.config.regularVolume);
        }
      }
    });

    _countdownSub = _engine.countdownStream.listen((event) {
      _audio.playCountdownWarning(widget.config.regularVolume);
      if (mounted) setState(() => _countdownRemaining = event.remainingSeconds);
      _timerFlashController.repeat(reverse: true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _timerFlashController.stop();
          _timerFlashController.reset();
          setState(() => _countdownRemaining = -1);
        }
      });
    });

    _endBellSub = _engine.endBellStream.listen((_) {
      _audio.playEndBell(widget.config.regularVolume);
    });

    await _engine.start();
  }

  void _togglePause() {
    if (_isPaused) {
      _engine.resume();
    } else {
      _engine.pause();
    }
  }

  void _stopTraining() {
    _engine.stop();
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('训练结束',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('时间: ${_formatTime(_state.elapsedSeconds)}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('变向信号: ${_state.signalCount} 次',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('平均BPM: ${_state.currentBpm}',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('返回', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _beatSub?.cancel();
    _signalSub?.cancel();
    _stateSub?.cancel();
    _tickSub?.cancel();
    _countdownSub?.cancel();
    _endBellSub?.cancel();
    _engine.dispose();
    _audio.dispose();
    _timerFlashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRest = _state.phase == TrainingPhase.rest;
    final isCountIn = _state.phase == TrainingPhase.countIn;
    final isFinished = _state.phase == TrainingPhase.finished;
    final screenWidth = MediaQuery.of(context).size.width;
    final ringSize = (screenWidth * 0.48).clamp(160.0, 240.0);

    return Scaffold(
      backgroundColor: isRest ? const Color(0xFF16213E) : const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Top: big timer + BPM
            _buildHeader(isRest, isCountIn),
            const SizedBox(height: 8),
            // Middle: beat ring + direction or count-in
            Expanded(
              child: Center(
                child: isCountIn
                    ? _buildCountIn(ringSize)
                    : _buildMainDisplay(ringSize, isRest),
              ),
            ),
            // Bottom: pause + stop buttons
            if (!isCountIn && !isFinished) _buildBottomButtons(isRest),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isRest, bool isCountIn) {
    final timeStr = _formatTime(_state.elapsedSeconds);
    final isUrgent = _countdownRemaining > 0 && _countdownRemaining <= 10;

    return AnimatedBuilder(
      animation: _timerFlashAnim,
      builder: (_, child) {
        final opacity = isUrgent ? _timerFlashAnim.value : 1.0;
        return Opacity(
          opacity: opacity,
          child: Column(
            children: [
              // Big timer
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 88,
                  fontWeight: FontWeight.w100,
                  color: isUrgent ? const Color(0xFFFF5252) : Colors.white,
                  letterSpacing: 6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (isRest)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text('休 息',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          letterSpacing: 8)),
                ),
              if (isCountIn)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('准备',
                      style: TextStyle(fontSize: 14, color: Colors.white54)),
                ),
              if (_isPaused && !isCountIn)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('已暂停',
                      style: TextStyle(fontSize: 14, color: Colors.orange)),
                ),
              // BPM below timer (small)
              if (!isCountIn && _state.phase != TrainingPhase.finished)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${_state.currentBpm} BPM',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.white38, letterSpacing: 2)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountIn(double ringSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _countInValue > 0 ? '$_countInValue' : '开始!',
          style: TextStyle(
            fontSize: _countInValue > 0 ? 100 : 56,
            fontWeight: FontWeight.bold,
            color: _countInValue > 0 ? Colors.white : const Color(0xFF00E5FF),
          ),
        ),
        const SizedBox(height: 24),
        Stack(
          alignment: Alignment.center,
          children: [
            BeatRing(
              key: _beatRingKey,
              size: ringSize,
              color: const Color(0xFF00E5FF),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainDisplay(double ringSize, bool isRest) {
    return Stack(
      alignment: Alignment.center,
      children: [
        BeatRing(
          key: _beatRingKey,
          size: ringSize,
          color: isRest ? Colors.orange : const Color(0xFF00E5FF),
        ),
        DirectionOverlay(key: _directionKey, size: ringSize * 1.15),
      ],
    );
  }

  Widget _buildBottomButtons(bool isRest) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pause/Resume button
          SizedBox(
            width: 64,
            height: 64,
            child: FloatingActionButton(
              onPressed: _togglePause,
              backgroundColor:
                  _isPaused ? const Color(0xFF4CAF50) : Colors.white24,
              child: Icon(
                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 32,
                color: _isPaused ? Colors.white : Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Stop button
          SizedBox(
            width: 64,
            height: 64,
            child: FloatingActionButton(
              onPressed: () {
                _stopTraining();
                Navigator.pop(context);
              },
              backgroundColor: const Color(0xFFE91E63),
              child:
                  const Icon(Icons.stop_rounded, size: 32, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
