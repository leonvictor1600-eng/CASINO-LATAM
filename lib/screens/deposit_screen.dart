import 'package:flutter/material.dart';

class DepositScreen extends StatefulWidget {
  final int monedasActuales;

  const DepositScreen({super.key, required this.monedasActuales});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  late int _monedas;
  String _metodoSeleccionado = 'PayPal';
  
  // Controladores para los formularios
  final TextEditingController _paypalController = TextEditingController();
  final TextEditingController _usdtWalletController = TextEditingController();
  final TextEditingController _usdtHashController = TextEditingController();
  final TextEditingController _pmTelefonoController = TextEditingController();
  final TextEditingController _pmCedulaController = TextEditingController();
  final TextEditingController _pmBancoController = TextEditingController();

  bool _bonoReclamadoHoy = false;

  @override
  void initState() {
    super.initState();
    _monedas = widget.monedasActuales;
  }

  void _reclamarBono() {
    if (_bonoReclamadoHoy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Ya reclamaste tu bono diario hoy! Vuelve mañana.')),
      );
      return;
    }

    setState(() {
      _monedas += 250; // Bono de 250 monedas
      _bonoReclamadoHoy = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Has reclamado +250 monedas de Bonus Diario! 🎉'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _procesarRecarga() {
    // Simulación de recarga exitosa agregando monedas de prueba
    setState(() {
      _monedas += 1000; // Recarga simulada de 1000 monedas
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('¡Recarga Exitosa!', style: TextStyle(color: Colors.amber)),
        content: Text(
          'Tu pago mediante $_metodoSeleccionado ha sido procesado con éxito. Se han acreditado 1000 monedas a tu cuenta.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Fondo oscuro casino
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C), // Rojo Carmesí
        title: const Text(
          'CAJA Y RECARGAS',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _monedas), // Devuelve el saldo actualizado al Home
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Balance y Bonus Diario
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo Actual:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        '$_monedas Monedas',
                        style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bonoReclamadoHoy ? Colors.grey : Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _bonoReclamadoHoy ? null : _reclamarBono,
                    icon: const Icon(Icons.card_giftcard),
                    label: Text(_bonoReclamadoHoy ? 'Bono Reclamado' : 'Bonus Diario'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Selecciona Método de Pago',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Selector de métodos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetodoBoton('PayPal', Icons.paypal),
                _buildMetodoBoton('USDT', Icons.currency_bitcoin),
                _buildMetodoBoton('Pago Móvil', Icons.phone_android),
              ],
            ),
            const SizedBox(height: 24),

            // Formulario dinámico según el método elegido
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalles de pago: $_metodoSeleccionado',
                    style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFormularioMetodo(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C), // Rojo
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _procesarRecarga,
                      child: const Text(
                        'Confirmar Recarga (+1000 Monedas)',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoBoton(String nombre, IconData icono) {
    bool seleccionado = _metodoSeleccionado == nombre;
    return GestureDetector(
      onTap: () => setState(() => _metodoSeleccionado = nombre),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFFB71C1C) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: seleccionado ? Colors.amber : Colors.grey),
        ),
        child: Column(
          children: [
            Icon(icono, color: seleccionado ? Colors.amber : Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(nombre, style: TextStyle(color: seleccionado ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioMetodo() {
    if (_metodoSeleccionado == 'PayPal') {
      return TextField(
        controller: _paypalController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'Correo electrónico de PayPal',
          labelStyle: TextStyle(color: Colors.grey),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
        ),
      );
    } else if (_metodoSeleccionado == 'USDT') {
      return Column(
        children: [
          TextField(
            controller: _usdtWalletController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Dirección de Billetera (TRC20 / BEP20)',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usdtHashController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Hash de Transacción / TXID',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          TextField(
            controller: _pmBancoController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Banco Emisor',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pmTelefonoController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Número de Teléfono',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pmCedulaController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cédula / DNI',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            ),
          ),
        ],
      );
    }
  }
}