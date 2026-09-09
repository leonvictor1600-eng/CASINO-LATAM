import 'package:flutter/material.dart';

class PaqueteMonedas {
  final String nombre;
  final int monedas;
  final IconData icono;
  final Color color;
  final bool destacado;

  const PaqueteMonedas({
    required this.nombre,
    required this.monedas,
    required this.icono,
    required this.color,
    this.destacado = false,
  });
}

const List<PaqueteMonedas> paquetesDisponibles = [
  PaqueteMonedas(nombre: 'Paquete Inicial', monedas: 500, icono: Icons.monetization_on, color: Colors.amber),
  PaqueteMonedas(nombre: 'Paquete Popular', monedas: 1200, icono: Icons.stars, color: Colors.orangeAccent, destacado: true),
  PaqueteMonedas(nombre: 'Paquete Premium', monedas: 3000, icono: Icons.diamond, color: Color(0xFF67E8F9)),
  PaqueteMonedas(nombre: 'Paquete VIP', monedas: 7500, icono: Icons.workspace_premium, color: Color(0xFFFFD700)),
];

/// Pantalla de recarga en MODO DEMO.
/// No se conecta a ningún procesador de pagos ni solicita datos financieros;
/// simplemente añade monedas virtuales de prueba al saldo local del jugador.
class RechargeScreen extends StatelessWidget {
  final double saldoActual;

  const RechargeScreen({super.key, required this.saldoActual});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F1D1D),
        title: const Text('Recargar Saldo', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.amber),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.science_outlined, color: Colors.amber, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MODO DEMO: estas son monedas virtuales de prueba. No se procesan pagos reales ni se solicitan datos financieros.',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A0A0A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  const Text('Saldo actual', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    saldoActual.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.amber, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: paquetesDisponibles.length,
              itemBuilder: (context, index) {
                final paquete = paquetesDisponibles[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A0A0A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: paquete.destacado ? Colors.amber : paquete.color.withValues(alpha: 0.5),
                      width: paquete.destacado ? 2 : 1,
                    ),
                    boxShadow: paquete.destacado
                        ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 14, spreadRadius: 1)]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: paquete.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(paquete.icono, color: paquete.color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  paquete.nombre,
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                if (paquete.destacado) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('POPULAR', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${paquete.monedas} monedas',
                              style: TextStyle(color: paquete.color, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, paquete.monedas),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Obtener', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}