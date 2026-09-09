import 'dart:math';
import 'package:flutter/material.dart';
import 'simple_confetti.dart';

class SlotsScreen extends StatefulWidget {
  final double saldoActual;
  final int girosPrevios;
  final double multiplicadorVip;

  const SlotsScreen({
    super.key,
    required this.saldoActual,
    required this.girosPrevios,
    this.multiplicadorVip = 1.0,
  });

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  late double saldo;
  late int girosTotales;
  final double costoApuesta = 20.0;
  bool girando = false;
  String mensaje = '¡Haz coincidir 3 símbolos para ganar x5!';

  final List<String> simbolos = ['🍒', '🍋', '💎', '7️⃣', '🔔'];
  String s1 = '🍒';
  String s2 = '🍋';
  String s3 = '💎';

  int girosGanados = 0;
  double gananciaNeta = 0.0;
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

  void jugarSlots() {
    if (saldo < costoApuesta) {
      setState(() {
        mensaje = '⚠️ Saldo insuficiente. Recarga en el lobby.';
      });
      return;
    }

    setState(() {
      girando = true;
      saldo -= costoApuesta;
      gananciaNeta -= costoApuesta;
      girosTotales++;
      mensaje = 'Girando los rieles... 🎰';
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      // Si el usuario ya salió de esta pantalla (o hubo un hot reload)
      // mientras esperábamos, 'mounted' será false. Sin este chequeo,
      // el setState de abajo lanza una excepción y el juego se congela
      // mostrando "Girando los rieles..." para siempre.
      if (!mounted) return;

      final random = Random();
      final nuevoS1 = simbolos[random.nextInt(simbolos.length)];
      final nuevoS2 = simbolos[random.nextInt(simbolos.length)];
      final nuevoS3 = simbolos[random.nextInt(simbolos.length)];

      bool gano = (nuevoS1 == nuevoS2 && nuevoS2 == nuevoS3);
      double premio = 0.0;

      if (gano) {
        premio = costoApuesta * 5.0 * widget.multiplicadorVip;
        saldo += premio;
        gananciaNeta += premio;
        girosGanados++;
        _confettiController.play();
      }

      setState(() {
        s1 = nuevoS1;
        s2 = nuevoS2;
        s3 = nuevoS3;
        girando = false;
        if (gano) {
          mensaje = '🎉 ¡JACKPOT! ¡Ganaste USD ${premio.toStringAsFixed(2)}!';
        } else {
          mensaje = '❌ Sin coincidencia. Perdiste USD $costoApuesta';
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
          title: const Text('TRAGAMONEDAS SLOTS 🎰', style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 16)),
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
                    const Text('SLOTS DE 3 RIELES (Premio x5)', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.yellowAccent, width: 3),
                        boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 4)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [_buildRiel(s1), _buildRiel(s2), _buildRiel(s3)],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.yellowAccent.withValues(alpha: 0.4))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Tiradas', '$girosTotales'),
                          _buildStatItem('Jackpots', '$girosGanados'),
                          _buildStatItem('Neto', '${gananciaNeta >= 0 ? '+' : ''}\$$gananciaNeta', color: gananciaNeta >= 0 ? Colors.greenAccent : Colors.redAccent),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: girando ? null : jugarSlots,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          foregroundColor: Colors.yellowAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.yellowAccent, width: 1.5)),
                        ),
                        child: Text(girando ? 'GIRANDO...' : 'TIRAR SLOTS (USD 20)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
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

  Widget _buildRiel(String simbolo) {
    return Container(
      width: 70, height: 90,
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.yellowAccent.withValues(alpha: 0.6), width: 2)),
      child: Center(child: Text(girando ? '🔄' : simbolo, style: const TextStyle(fontSize: 36))),
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