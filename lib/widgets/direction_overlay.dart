import 'package:flutter/material.dart';
import '../models/training_config.dart';

class DirectionOverlay extends StatefulWidget {
  final double size;
  final VoidCallback? onSignal;

  const DirectionOverlay({super.key, this.size = 280, this.onSignal});

  @override
  State<DirectionOverlay> createState() => DirectionOverlayState();
}

class DirectionOverlayState extends State<DirectionOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  Direction? _currentDirection;
  Color _currentColor = Colors.redAccent;

  static const _dirColors = {
    Direction.forward: Color(0xFF4CAF50),
    Direction.backward: Color(0xFF2196F3),
    Direction.left: Color(0xFFFF9800),
    Direction.right: Color(0xFFE91E63),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  void showDirection(Direction dir) {
    _currentDirection = dir;
    _currentColor = _dirColors[dir] ?? Colors.redAccent;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          if (_currentDirection == null) {
            return const SizedBox.shrink();
          }
          return Opacity(
            opacity: (_controller.value <= 0.2)
                ? _controller.value / 0.2
                : 1.0 - (_controller.value - 0.2) / 0.8,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: _buildArrow(_currentDirection!, _currentColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArrow(Direction dir, Color color) {
    IconData icon;
    switch (dir) {
      case Direction.forward:
        icon = Icons.arrow_upward_rounded;
      case Direction.backward:
        icon = Icons.arrow_downward_rounded;
      case Direction.left:
        icon = Icons.arrow_back_rounded;
      case Direction.right:
        icon = Icons.arrow_forward_rounded;
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.9),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 30, spreadRadius: 10),
        ],
      ),
      child: Icon(icon, size: widget.size * 0.5, color: Colors.white),
    );
  }
}
