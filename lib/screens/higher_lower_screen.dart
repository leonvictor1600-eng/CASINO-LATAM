import 'package:flutter/material.dart';
import 'dart:math';
import 'simple_confetti.dart';

class HigherLowerScreen extends StatefulWidget {
  final double saldoActual;
  final int girosPrevios;
  final double multiplicadorVip;

  const HigherLowerScreen({
    super.key,
    required this.saldoActual,
    required this.girosPrevios,
    this.multiplicadorVip = 1.0,
  });

  @override
  State<HigherLowerScreen> createState() => _HigherLowerScreenState();
}

class _HigherLowerScreenState extends State<HigherLowerScreen> {
  late double saldo;
  late int girosTotales;
  final int _apuesta = 50;
  int _cartaActual = 5;
  int _siguienteCarta = 8;
  String _mensaje = '¿La siguiente carta será Mayor o Menor?';
  bool _juegoTerminado = false;

  final Random _random = Random();
  final SimpleConfettiController _confettiController = SimpleConfettiController();

  @override
  void initState() {
    super.initState();
    saldo = widget.saldoActual;
    girosTotales = widget.girosPrevios;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void regresarAlLobby() {
    Navigator.pop(context, {'saldo': saldo, 'giros': girosTotales});
  }

  void _nuevaRonda() {
    setState(() {
      _cartaActual = _random.nextInt(13) + 1; // Cartas del 1 al 13
      _siguienteCarta = _random.nextInt(13) + 1;
      _mensaje = '¿La siguiente carta será Mayor o Menor?';
      _juegoTerminado = false;
    });
  }

  void _adivinar(bool esMayor) {
    if (_juegoTerminado) return;

    setState(() {
      _juegoTerminado = true;
      girosTotales++;
      bool acerto = false;

      if (esMayor) {
        acerto = _siguienteCarta >= _cartaActual;
      } else {
        acerto = _siguienteCarta <= _cartaActual;
      }

      if (acerto) {
        final premio = _apuesta * widget.multiplicadorVip;
        saldo += premio;
        _mensaje = '¡Correcto! Ganaste ${premio.toStringAsFixed(0)} monedas 🎉';
        _confettiController.play();
      } else {
        saldo -= _apuesta;
        _mensaje = '¡Fallaste! Perdiste $_apuesta monedas 😢';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        regresarAlLobby();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Mayor o Menor',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: regresarAlLobby,
          ),
        ),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.multiplicadorVip > 1.0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)),
                      child: Text('Bono VIP activo: x${widget.multiplicadorVip.toStringAsFixed(2)}', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  Text(
                    'Monedas: ${saldo.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCard('Actual', _cartaActual),
                      const SizedBox(width: 30),
                      _buildCard(
                        'Siguiente',
                        _juegoTerminado ? _siguienteCarta : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _mensaje,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  if (!_juegoTerminado) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => _adivinar(false),
                          icon: const Icon(Icons.arrow_downward, color: Colors.white),
                          label: const Text(
                            'Menor o Igual',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => _adivinar(true),
                          icon: const Icon(Icons.arrow_upward, color: Colors.white),
                          label: const Text(
                            'Mayor o Igual',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                      ),
                      onPressed: _nuevaRonda,
                      child: const Text(
                        'Siguiente Carta',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SimpleConfettiOverlay(controller: _confettiController),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String titulo, int? valor) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          width: 90,
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              valor != null ? '$valor' : '?',
              style: TextStyle(
                color: valor != null ? Colors.black87 : Colors.grey,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}