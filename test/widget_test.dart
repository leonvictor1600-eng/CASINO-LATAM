import 'dart:ui';
import 'package:flutter/material.dart';
import 'roulette_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Saldo inicial de cortesía de USD 500 para que puedas jugar inmediatamente
  double saldoUsuario = 500.0;
  
  bool isHoverRoulette = false;
  bool isHoverSlots = false;

  void mostrarDialogoRecarga() {
    final TextEditingController bancoController = TextEditingController();
    final TextEditingController telefonoController = TextEditingController();
    final TextEditingController montoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.yellowAccent, width: 1.5),
          ),
          title: const Text(
            '💳 Recarga Bancaria / Pago Móvil',
            style: TextStyle(color: Colors.yellowAccent, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bancoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Banco Emisor',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.yellowAccent)),
                ),
              ),
              TextField(
                controller: telefonoController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Teléfono / Cédula',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.yellowAccent)),
                ),
              ),
              TextField(
                controller: montoController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Monto a Recargar (USD)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.yellowAccent)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellowAccent, foregroundColor: Colors.black),
              onPressed: () {
                final double monto = double.tryParse(montoController.text) ?? 0.0;
                if (monto > 0) {
                  setState(() {
                    saldoUsuario += monto;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('¡Recarga simulada exitosa de USD $monto!')),
                  );
                }
              },
              child: const Text('Confirmar Pago', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CASINO LATAM 🎰', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
        backgroundColor: const Color(0xFF7F1D1D),
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
                child: Text(
                  'Saldo: USD ${saldoUsuario.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.yellowAccent, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F0F), Color(0xFF500000)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LOBBY PRINCIPAL',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Selecciona tu experiencia de juego:', style: TextStyle(color: Colors.white70, fontSize: 15)),
                  ElevatedButton.icon(
                    onPressed: mostrarDialogoRecarga,
                    icon: const Icon(Icons.account_balance, color: Colors.black, size: 18),
                    label: const Text('+ Recargar Banco', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellowAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    MouseRegion(
                      onEnter: (_) => setState(() => isHoverRoulette = true),
                      onExit: (_) => setState(() => isHoverRoulette = false),
                      child: AnimatedScale(
                        scale: isHoverRoulette ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: _buildGameCard(
                          titulo: 'Ruleta Flash (1-100)',
                          subtitulo: 'Múltiples Apuestas',
                          icon: Icons.pie_chart,
                          isHovered: isHoverRoulette,
                          onTap: () async {
                            final double? nuevoSaldo = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RouletteScreen(saldoActual: saldoUsuario),
                              ),
                            );
                            if (nuevoSaldo != null) {
                              setState(() {
                                saldoUsuario = nuevoSaldo;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    MouseRegion(
                      onEnter: (_) => setState(() => isHoverSlots = true),
                      onExit: (_) => setState(() => isHoverSlots = false),
                      child: AnimatedScale(
                        scale: isHoverSlots ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: _buildGameCard(
                          titulo: 'Próximamente',
                          subtitulo: 'Blackjack / Slots',
                          icon: Icons.lock,
                          isHovered: isHoverSlots,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Este módulo de apuestas se habilitará próximamente.')),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard({required String titulo, required String subtitulo, required IconData icon, required bool isHovered, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFF7F1D1D) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHovered ? Colors.yellowAccent : Colors.redAccent.withValues(alpha: 0.5),
            width: isHovered ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered ? Colors.yellowAccent.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.5),
              blurRadius: isHovered ? 15 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: isHovered ? Colors.yellowAccent : Colors.redAccent),
            const SizedBox(height: 16),
            Text(titulo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isHovered ? Colors.yellowAccent : Colors.white)),
            const SizedBox(height: 6),
            Text(subtitulo, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}