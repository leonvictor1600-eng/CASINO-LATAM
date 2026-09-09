import 'dart:math';
import 'package:flutter/material.dart';
import 'simple_confetti.dart';

class RouletteScreen extends StatefulWidget {
  final double saldoActual;
  final int girosPrevios;
  final double multiplicadorVip;

  const RouletteScreen({
    super.key,
    required this.saldoActual,
    required this.girosPrevios,
    this.multiplicadorVip = 1.0,
  });

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> with SingleTickerProviderStateMixin {
  late double saldo;
  late int girosTotales;
  int? numeroGanador;
  String tipoApuestaSeleccionada = 'par';
  String mensajeResultado = 'Elige tu estrategia y gira la ruleta';
  bool girando = false;
  final double costoApuesta = 25.0;

  int girosGanados = 0;
  double gananciaNeta = 0.0;

  final List<int> historialGanadores = [];
  late AnimationController _animationController;
  final SimpleConfettiController _confettiController = SimpleConfettiController();

  @override
  void initState() {
    super.initState();
    saldo = widget.saldoActual;
    girosTotales = widget.girosPrevios;
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void regresarAlLobby() {
    Navigator.pop(context, {'saldo': saldo, 'giros': girosTotales});
  }

  void girarRuleta() {
    if (saldo < costoApuesta) {
      setState(() {
        mensajeResultado = '⚠️ Saldo insuficiente. Recarga en el lobby.';
      });
      return;
    }

    setState(() {
      girando = true;
      saldo -= costoApuesta;
      gananciaNeta -= costoApuesta;
      girosTotales++;
      mensajeResultado = 'Girando la ruleta... 🎲';
    });

    _animationController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 1600), () {
      // Mismo motivo que en Slots: evita el congelamiento si la pantalla
      // ya no está montada cuando el temporizador termina.
      if (!mounted) return;

      final random = Random();
      final int resultado = random.nextInt(100) + 1;

      bool gano = false;
      double multiplicadorPremio = 0.0;

      if (tipoApuestaSeleccionada == 'par' && resultado % 2 == 0) {
        gano = true;
        multiplicadorPremio = 2.0;
      } else if (tipoApuestaSeleccionada == 'impar' && resultado % 2 != 0) {
        gano = true;
        multiplicadorPremio = 2.0;
      } else if (tipoApuestaSeleccionada == '1-50' && resultado >= 1 && resultado <= 50) {
        gano = true;
        multiplicadorPremio = 3.0;
      } else if (tipoApuestaSeleccionada == '51-100' && resultado >= 51 && resultado <= 100) {
        gano = true;
        multiplicadorPremio = 3.0;
      }

      double premioTotal = 0.0;
      if (gano) {
        premioTotal = costoApuesta * multiplicadorPremio * widget.multiplicadorVip;
        saldo += premioTotal;
        gananciaNeta += premioTotal;
        girosGanados++;
        _confettiController.play();
      }

      setState(() {
        numeroGanador = resultado;
        girando = false;
        historialGanadores.insert(0, resultado);
        if (historialGanadores.length > 8) historialGanadores.removeLast();

        if (gano) {
          mensajeResultado = '🎉 ¡Cayó el $resultado! Ganaste USD ${premioTotal.toStringAsFixed(2)}';
        } else {
          mensajeResultado = '❌ Cayó el $resultado. Perdiste USD $costoApuesta';
        }
      });
    });
  }

  @override
  Widget build(context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        regresarAlLobby();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RULETA FLASH PRO 1-100', style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: const Color(0xFF7F1D1D),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.yellowAccent),
            onPressed: regresarAlLobby,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.yellowAccent, width: 1),
                  ),
                  child: Text('Saldo: USD ${saldo.toStringAsFixed(2)}', style: const TextStyle(color: Colors.yellowAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F0F0F), Color(0xFF450A0A)]),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (widget.multiplicadorVip > 1.0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)),
                        child: Text('Bono VIP activo: x${widget.multiplicadorVip.toStringAsFixed(2)}', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                      child: Row(
                        children: [
                          const Text('Últimos: ', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: historialGanadores.isEmpty
                                    ? [const Text(' Gira para ver historial ', style: TextStyle(color: Colors.white38, fontSize: 12))]
                                    : historialGanadores.map((numItem) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: numItem % 2 == 0 ? Colors.green.shade800 : Colors.red.shade900, shape: BoxShape.circle),
                                        child: Text('$numItem', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      )).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 5.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic)),
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.yellowAccent, width: 4),
                          boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.6), blurRadius: 18, spreadRadius: 4)],
                        ),
                        child: Center(
                          child: Text(
                            girando ? '🎲' : (numeroGanador != null ? '$numeroGanador' : '1-100'),
                            style: TextStyle(fontSize: numeroGanador != null && !girando ? 36 : 24, fontWeight: FontWeight.bold, color: Colors.yellowAccent),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(mensajeResultado, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 14),
                    const Text('Elige tu estrategia (Costo: USD 25):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBotonApuesta('Pares (x2)', 'par'),
                        const SizedBox(width: 8),
                        _buildBotonApuesta('Impares (x2)', 'impar'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBotonApuesta('Bloque 1-50 (x3)', '1-50'),
                        const SizedBox(width: 8),
                        _buildBotonApuesta('Bloque 51-100 (x3)', '51-100'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.yellowAccent.withValues(alpha: 0.4))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Giros', '$girosTotales'),
                          _buildStatItem('Aciertos', '$girosGanados'),
                          _buildStatItem('Neto', '${gananciaNeta >= 0 ? '+' : ''}\$$gananciaNeta', color: gananciaNeta >= 0 ? Colors.greenAccent : Colors.redAccent),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: girando ? null : girarRuleta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          foregroundColor: Colors.yellowAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.yellowAccent, width: 1.5)),
                        ),
                        child: Text(girando ? 'GIRANDO...' : 'GIRAR RULETA', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SimpleConfettiOverlay(controller: _confettiController),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonApuesta(String texto, String tipo) {
    bool seleccionada = tipoApuestaSeleccionada == tipo;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => tipoApuestaSeleccionada = tipo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: seleccionada ? Colors.yellowAccent : Colors.black45,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.yellowAccent, width: 1.5),
          ),
          child: Center(
            child: Text(texto, style: TextStyle(color: seleccionada ? Colors.black : Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String valor, {Color color = Colors.white}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(valor, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}