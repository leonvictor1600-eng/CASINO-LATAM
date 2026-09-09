import 'package:flutter/material.dart';

class VipTier {
  final String nombre;
  final int minGiros;
  final double multiplicador;
  final Color color;
  final IconData icono;

  const VipTier({
    required this.nombre,
    required this.minGiros,
    required this.multiplicador,
    required this.color,
    required this.icono,
  });
}

const List<VipTier> vipTiers = [
  VipTier(nombre: 'Bronce', minGiros: 0, multiplicador: 1.0, color: Color(0xFFCD7F32), icono: Icons.shield),
  VipTier(nombre: 'Plata', minGiros: 50, multiplicador: 1.1, color: Color(0xFFC0C0C0), icono: Icons.shield_moon),
  VipTier(nombre: 'Oro', minGiros: 150, multiplicador: 1.25, color: Color(0xFFFFD700), icono: Icons.workspace_premium),
  VipTier(nombre: 'Diamante', minGiros: 300, multiplicador: 1.5, color: Color(0xFF67E8F9), icono: Icons.diamond),
];

VipTier tierPorGiros(int giros) {
  VipTier actual = vipTiers.first;
  for (final tier in vipTiers) {
    if (giros >= tier.minGiros) actual = tier;
  }
  return actual;
}

VipTier? siguienteTier(int giros) {
  for (final tier in vipTiers) {
    if (giros < tier.minGiros) return tier;
  }
  return null;
}

const List<String> avatarOptions = ['🎩', '🕶️', '👑', '🃏', '🎲', '🍀', '💰', '🦁', '🐯', '🎯'];

class ProfileScreen extends StatefulWidget {
  final String username;
  final String avatar;
  final int girosTotales;
  final double saldoActual;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.avatar,
    required this.girosTotales,
    required this.saldoActual,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nombreController;
  late String _avatarSeleccionado;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.username);
    _avatarSeleccionado = widget.avatar;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  void _guardarYSalir() {
    Navigator.pop(context, {
      'username': _nombreController.text.trim().isEmpty ? 'Jugador' : _nombreController.text.trim(),
      'avatar': _avatarSeleccionado,
    });
  }

  @override
  Widget build(BuildContext context) {
    final tierActual = tierPorGiros(widget.girosTotales);
    final proximoTier = siguienteTier(widget.girosTotales);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _guardarYSalir();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0505),
        appBar: AppBar(
          backgroundColor: const Color(0xFF7F1D1D),
          title: const Text('Mi Perfil', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _guardarYSalir,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: tierActual.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: tierActual.color, width: 3),
                  ),
                  child: Center(child: Text(_avatarSeleccionado, style: const TextStyle(fontSize: 48))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Tu nombre de jugador',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0A0A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tierActual.color.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(tierActual.icono, color: tierActual.color, size: 28),
                        const SizedBox(width: 10),
                        Text('Rango ${tierActual.nombre}',
                            style: TextStyle(color: tierActual.color, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Multiplicador de premios: x${tierActual.multiplicador.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('Giros totales: ${widget.girosTotales}', style: const TextStyle(color: Colors.white70)),
                    if (proximoTier != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: widget.girosTotales / proximoTier.minGiros,
                          backgroundColor: Colors.white12,
                          color: proximoTier.color,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Faltan ${proximoTier.minGiros - widget.girosTotales} giros para ${proximoTier.nombre}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      const Text('¡Rango máximo alcanzado! 🎉', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Elige tu avatar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: avatarOptions.map((avatar) {
                  final seleccionado = avatar == _avatarSeleccionado;
                  return InkWell(
                    onTap: () => setState(() => _avatarSeleccionado = avatar),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: seleccionado ? Colors.amber.withValues(alpha: 0.2) : Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: seleccionado ? Colors.amber : Colors.white24,
                          width: seleccionado ? 2 : 1,
                        ),
                      ),
                      child: Center(child: Text(avatar, style: const TextStyle(fontSize: 28))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo actual', style: TextStyle(color: Colors.white70)),
                    Text(
                      'USD ${widget.saldoActual.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarYSalir,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Guardar y volver', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}