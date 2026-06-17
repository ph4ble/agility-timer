import 'package:flutter/material.dart';

import '../models/training_config.dart';
import '../widgets/bpm_control.dart';
import 'training_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bpm = 100;
  int _minBeats = 4;
  int _maxBeats = 8;
  int _directionCount = 2;
  int _durationMinutes = 3;
  TrainingMode _mode = TrainingMode.free;
  SignalSoundType _soundType = SignalSoundType.tone;
  bool _randomBpm = false;
  int _randomBpmPercent = 10;
  int _intervalWorkSeconds = 30;
  int _intervalRestSeconds = 10;
  int _intervalRounds = 5;

  @override
  Widget build(BuildContext context) {
    // Compute flex ratios so sections with more content get more space
    int randomFlex = _randomBpm ? 2 : 1;
    int modeFlex;
    switch (_mode) {
      case TrainingMode.interval:
        modeFlex = 5;
        break;
      case TrainingMode.timed:
        modeFlex = 4;
        break;
      default:
        modeFlex = 3;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('敏捷训练计时器', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 44,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              const SizedBox(height: 4),
              // BPM control
              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: BpmControl(bpm: _bpm, onChanged: (v) => setState(() => _bpm = v)),
              ),
              const SizedBox(height: 6),
              // 4 settings sections
              Expanded(
                flex: 2,
                child: _buildSection('变向信号间隔', Icons.shuffle, _buildBeatRange()),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: 2,
                child: _buildSection('方向 & 声音', Icons.directions_run, _buildDirectionSound()),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: randomFlex,
                child: _buildSection('随机变速', Icons.speed, _buildRandomBpm()),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: modeFlex,
                child: _buildSection('训练模式', Icons.fitness_center, _buildMode()),
              ),
              const SizedBox(height: 8),
              // Start button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _startTraining,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('开 始 训 练'),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 13),
              const SizedBox(width: 5),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(child: content),
        ],
      ),
    );
  }

  // ---- 变向信号间隔 ----
  Widget _buildBeatRange() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _miniSlider('最小拍数', _minBeats, 2, 16, (v) {
          setState(() {
            _minBeats = v;
            if (_maxBeats < v) _maxBeats = v;
          });
        }),
        const SizedBox(height: 6),
        _miniSlider('最大拍数', _maxBeats, _minBeats, 32, (v) => setState(() => _maxBeats = v)),
      ],
    );
  }

  // ---- 方向 & 声音 ----
  Widget _buildDirectionSound() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [2, 3, 4].map((count) {
            final selected = _directionCount == count;
            return GestureDetector(
              onTap: () => setState(() => _directionCount = count),
              child: Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFE91E63) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? const Color(0xFFE91E63) : Colors.white24),
                ),
                child: Column(
                  children: [
                    Text('$count',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : Colors.white70)),
                    Text(count == 2 ? '前/侧' : count == 3 ? '前/左/右' : '四方',
                        style: TextStyle(fontSize: 9, color: selected ? Colors.white70 : Colors.white54)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _soundChip(SignalSoundType.tone, '提示音'),
            const SizedBox(width: 8),
            _soundChip(SignalSoundType.voiceDirection, '方向音调'),
          ],
        ),
      ],
    );
  }

  Widget _soundChip(SignalSoundType type, String label) {
    final selected = _soundType == type;
    return GestureDetector(
      onTap: () => setState(() => _soundType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE91E63) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFFE91E63) : Colors.white24),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.white70)),
      ),
    );
  }

  // ---- 随机变速 ----
  Widget _buildRandomBpm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const Expanded(
                child: Text('随机变速', style: TextStyle(color: Colors.white70, fontSize: 13))),
            SizedBox(
              height: 26,
              child: Switch(
                value: _randomBpm,
                activeColor: const Color(0xFFE91E63),
                onChanged: (v) => setState(() => _randomBpm = v),
              ),
            ),
          ],
        ),
        if (_randomBpm) ...[
          const SizedBox(height: 4),
          _miniSlider('波动范围', _randomBpmPercent, 5, 30,
              (v) => setState(() => _randomBpmPercent = v),
              suffix: '%'),
        ],
      ],
    );
  }

  // ---- 训练模式 ----
  Widget _buildMode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(child: _modeChip(TrainingMode.free, '自由模式', '不限时')),
            const SizedBox(width: 4),
            Expanded(child: _modeChip(TrainingMode.timed, '定时模式', '到时结束')),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _modeChip(TrainingMode.progressive, '递增模式', 'BPM渐快')),
            const SizedBox(width: 4),
            Expanded(child: _modeChip(TrainingMode.interval, '间歇模式', '训练+休息')),
          ],
        ),
        if (_mode == TrainingMode.timed) ...[
          const SizedBox(height: 6),
          _durationSelector(),
        ],
        if (_mode == TrainingMode.interval) ...[
          const SizedBox(height: 4),
          _intervalControls(),
        ],
      ],
    );
  }

  Widget _modeChip(TrainingMode mode, String title, String subtitle) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE91E63) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFFE91E63) : Colors.white24),
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.white70)),
            Text(subtitle,
                style: TextStyle(fontSize: 9, color: selected ? Colors.white60 : Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _durationSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [1, 3, 5, 10, 15, 30].map((mins) {
        final selected = _durationMinutes == mins;
        return GestureDetector(
          onTap: () => setState(() => _durationMinutes = mins),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE91E63) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? const Color(0xFFE91E63) : Colors.white24),
            ),
            child: Text(
              mins < 10 ? '${mins}分' : '$mins',
              style: TextStyle(fontSize: 11, color: selected ? Colors.white : Colors.white70),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _intervalControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(
                width: 28, child: Text('训练', style: TextStyle(color: Colors.white54, fontSize: 10))),
            Expanded(child: _secondsRow(_intervalWorkSeconds, (v) => setState(() => _intervalWorkSeconds = v))),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const SizedBox(
                width: 28, child: Text('休息', style: TextStyle(color: Colors.white54, fontSize: 10))),
            Expanded(child: _secondsRow(_intervalRestSeconds, (v) => setState(() => _intervalRestSeconds = v))),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(
                width: 28, child: Text('组数', style: TextStyle(color: Colors.white54, fontSize: 10))),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: _intervalRounds.toDouble(),
                  min: 1,
                  max: 20,
                  activeColor: const Color(0xFFE91E63),
                  onChanged: (v) => setState(() => _intervalRounds = v.round()),
                ),
              ),
            ),
            SizedBox(
              width: 34,
              child: Text('${_intervalRounds}组',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _secondsRow(int current, ValueChanged<int> onChanged) {
    return Row(
      children: [5, 10, 15, 20, 30, 45, 60].map((secs) {
        final selected = current == secs;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(secs),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE91E63) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: selected ? const Color(0xFFE91E63) : Colors.white24),
              ),
              child: Text('${secs}s',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: selected ? Colors.white : Colors.white70)),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---- Shared ----
  Widget _miniSlider(String label, int value, int min, int max, ValueChanged<int> onChanged,
      {String suffix = '拍'}) {
    return Row(
      children: [
        SizedBox(
            width: 52,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              activeColor: const Color(0xFFE91E63),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text('$value$suffix',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  void _startTraining() {
    final config = TrainingConfig(
      bpm: _bpm,
      minBeatsToChange: _minBeats,
      maxBeatsToChange: _maxBeats,
      directionCount: _directionCount,
      trainingDuration: Duration(minutes: _durationMinutes),
      mode: _mode,
      signalSoundType: _soundType,
      enableRandomBpm: _randomBpm,
      randomBpmPercent: _randomBpmPercent,
      intervalWorkSeconds: _intervalWorkSeconds,
      intervalRestSeconds: _intervalRestSeconds,
      intervalRounds: _intervalRounds,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainingScreen(config: config)),
    );
  }
}
