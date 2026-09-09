import 'dart:math';
import 'package:flutter/material.dart';

/// Controlador simple para disparar el efecto de confeti.
/// Se usa igual que un ChangeNotifier: llama a play() cuando quieras celebrar.
class SimpleConfettiController {
  final ValueNotifier<int> _trigger = ValueNotifier<int>(0);
  ValueNotifier<int> get trigger => _trigger;

  void play() {
    _trigger.value++;
  }

  void dispose() {
    _trigger.dispose();
  }
}

class _ConfettiParticle {
  final double startX;
  final double size;
  final double speed;
  final double sway;
  final double rotationSpeed;
  final Color color;

  _ConfettiParticle({
    required this.startX,
    required this.size,
    required this.speed,
    required this.sway,
    required this.rotationSpeed,
    required this.color,
  });
}

/// Superposición de confeti. Colócalo dentro de un Stack, por encima
/// del resto del contenido, y llama a controller.play() para celebrar.
class SimpleConfettiOverlay extends StatefulWidget {
  final SimpleConfettiController controller;
  final List<Color> colors;
  final int particleCount;

  const SimpleConfettiOverlay({
    super.key,
    required this.controller,
    this.colors = const [
      Colors.amber,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
    ],
    this.particleCount = 40,
  });

  @override
  State<SimpleConfettiOverlay> createState() => _SimpleConfettiOverlayState();
}

class _SimpleConfettiOverlayState extends State<SimpleConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final Random _random = Random();
  List<_ConfettiParticle> _particles = [];
  bool _activo = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    widget.controller.trigger.addListener(_onPlay);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _activo = false);
      }
    });
  }

  void _onPlay() {
    _particles = List.generate(widget.particleCount, (_) {
      return _ConfettiParticle(
        startX: _random.nextDouble(),
        size: 6 + _random.nextDouble() * 6,
        speed: 0.75 + _random.nextDouble() * 0.4,
        sway: (_random.nextDouble() - 0.5) * 80,
        rotationSpeed: (_random.nextDouble() - 0.5) * 12,
        color: widget.colors[_random.nextInt(widget.colors.length)],
      );
    });
    setState(() => _activo = true);
    _animController.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.trigger.removeListener(_onPlay);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_activo) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _animController.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final caida = Curves.easeIn.transform(progress);
    final opacidad = (1 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final dy = caida * p.speed * size.height * 1.1;
      final dx = p.startX * size.width + sin(progress * pi * 2) * p.sway;

      paint.color = p.color.withValues(alpha: opacidad);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(progress * p.rotationSpeed);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}