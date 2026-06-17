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

class _TrainingScreenState extends State<TrainingScreen> {
  final GlobalKey<BeatRingState> _beatRingKey = GlobalKey();
  final GlobalKey<DirectionOverlayState> _directionKey = GlobalKey();

  late TrainingEngine _engine;
  late AudioService _audio;

  StreamSubscription<BeatEvent>? _beatSub;
  StreamSubscription<SignalEvent>? _signalSub;
  StreamSubscription<TrainingState>? _stateSub;
  StreamSubscription<void>? _tickSub;

  TrainingState _state = TrainingState();
  int _countInValue = 3;

  @override
  void initState() {
    super.initState();
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
      if (mounted) setState(() => _state = state);
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
        if (mounted) setState(() => _countInValue = beat.beatNumber);
      }
    });

    await _engine.start();
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
        title: const Text('训练结束', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('时间: ${_formatTime(_state.elapsedSeconds)}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('变向信号: ${_state.signalCount} 次', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('平均BPM: ${_state.currentBpm}', style: const TextStyle(color: Colors.white70)),
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
    _engine.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRest = _state.phase == TrainingPhase.rest;
    final isCountIn = _state.phase == TrainingPhase.countIn;
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale ring/overlay to ~55% of screen width, capped for very wide phones
    final ringSize = (screenWidth * 0.55).clamp(180.0, 280.0);

    return Scaffold(
      backgroundColor: isRest ? const Color(0xFF16213E) : const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildTopBar(isRest, isCountIn),
            const SizedBox(height: 16),
            Expanded(
              child: isCountIn ? _buildCountIn() : _buildMainDisplay(ringSize, isRest),
            ),
            SizedBox(
              width: 72,
              height: 72,
              child: FloatingActionButton(
                onPressed: () {
                  _stopTraining();
                  Navigator.pop(context);
                },
                backgroundColor: const Color(0xFFE91E63),
                child: const Icon(Icons.stop_rounded, size: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDisplay(double ringSize, bool isRest) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isRest) ...[
          const Text('休 息',
              style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 8)),
          const SizedBox(height: 24),
        ],
        Stack(
          alignment: Alignment.center,
          children: [
            BeatRing(
              key: _beatRingKey,
              size: ringSize,
              color: isRest ? Colors.orange : const Color(0xFF00E5FF),
            ),
            DirectionOverlay(key: _directionKey, size: ringSize * 1.15),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isRest, bool isCountIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopItem('时间', _formatTime(_state.elapsedSeconds), Colors.white),
          _buildTopItem('BPM', '${_state.currentBpm}', Colors.white),
          _buildTopItem(
            '变向',
            '${_state.signalCount}',
            _state.signalCount > 0 ? const Color(0xFFE91E63) : Colors.white54,
          ),
        ],
      ),
    );
  }

  Widget _buildTopItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: valueColor, fontSize: 26, fontWeight: FontWeight.w300)),
      ],
    );
  }

  Widget _buildCountIn() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_countInValue',
            style: const TextStyle(
                fontSize: 110, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text('准备...',
              style: TextStyle(fontSize: 16, color: Colors.white54)),
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
