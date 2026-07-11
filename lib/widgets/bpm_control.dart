import 'package:flutter/material.dart';

class BpmControl extends StatelessWidget {
  final int bpm;
  final ValueChanged<int> onChanged;

  const BpmControl({
    super.key,
    required this.bpm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BPM number
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$bpm',
                style: const TextStyle(
                    fontSize: 42, fontWeight: FontWeight.w300, color: Colors.white)),
            const Padding(
              padding: EdgeInsets.only(bottom: 6, left: 2),
              child: Text('BPM',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Slider + quick buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _quickButton(-10),
            const SizedBox(width: 4),
            _quickButton(-1),
            const SizedBox(width: 6),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 9),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: bpm.toDouble(),
                  min: 40,
                  max: 500,
                  activeColor: const Color(0xFFE91E63),
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _quickButton(1),
            const SizedBox(width: 4),
            _quickButton(10),
          ],
        ),
      ],
    );
  }

  Widget _quickButton(int delta) {
    final label = delta > 0 ? '+$delta' : '$delta';
    return SizedBox(
      width: 38,
      height: 34,
      child: OutlinedButton(
        onPressed: () => onChanged((bpm + delta).clamp(40, 500)),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          side: const BorderSide(color: Colors.white24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ),
    );
  }
}
