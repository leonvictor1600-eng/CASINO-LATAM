import 'package:flutter/material.dart';

/// Tarjeta de juego que se ilumina al pasar el cursor (hover en escritorio/web)
/// o al presionarla (móvil).
class GameCard extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _hover = false;
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    final resaltado = _hover || _presionado;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _presionado = true),
        onTapUp: (_) => setState(() => _presionado = false),
        onTapCancel: () => setState(() => _presionado = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: resaltado ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: resaltado ? widget.color : widget.color.withOpacity(0.5),
                width: resaltado ? 2.5 : 1.5,
              ),
              boxShadow: resaltado
                  ? [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 18, spreadRadius: 2)]
                  : [],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icono, size: 48, color: resaltado ? widget.color : widget.color.withOpacity(0.9)),
                const SizedBox(height: 12),
                Text(
                  widget.titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitulo,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}