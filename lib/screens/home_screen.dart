import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'roulette_screen.dart';
import 'slots_screen.dart';
import 'higher_lower_screen.dart';
import 'profile_screen.dart';
import 'deposit_screen.dart';
import 'lion_runner_screen.dart';
import 'game_card.dart';
import 'simple_confetti.dart';
import 'usuario_modelo.dart';
import 'base_datos_memoria.dart';
import 'auth_screen.dart';

const int montoBonusDiario = 200;

/// Monedas que se entregan como recompensa cada vez que el jugador
/// avanza a un rango VIP superior (Bronce -> Plata -> Oro -> Diamante).
const int bonusPorAvanzarRango = 50;

String _fechaHoyComoTexto() {
  final ahora = DateTime.now();
  return '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
}

class HomeScreen extends StatefulWidget {
  /// Usuario que quedó activo tras un login/registro exitoso en AuthScreen.
  final Usuario usuario;

  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _monedas = 1000;
  int _girosRuleta = 0;
  int _girosSlots = 0;
  int _girosHigherLower = 0;
  int _girosLeon = 0;
  String _username = 'Jugador';
  String _avatar = '🎩';
  String? _ultimoBonusFecha;
  bool _cargando = true;
  bool _modoOscuro = true;

  /// Índice (dentro de la lista vipTiers de profile_screen.dart) del rango
  /// VIP más alto que este usuario ya alcanzó y por el que ya cobró su
  /// bono. Sirve para no volver a pagar el mismo bono dos veces.
  int _tierAlcanzadoIndex = 0;

  /// Controlador para el efecto de confeti que celebra el avance de rango.
  final SimpleConfettiController _confettiController = SimpleConfettiController();

  int get _girosTotales => _girosRuleta + _girosSlots + _girosHigherLower + _girosLeon;
  double get _multiplicadorVip => 1.0;
  bool get _bonusDisponibleHoy => _ultimoBonusFecha != _fechaHoyComoTexto();

  /// Devuelve el índice del rango VIP correspondiente a una cantidad de
  /// giros dada, usando la misma lista/lógica que ya usa ProfileScreen.
  int _indiceTier(int giros) => vipTiers.indexOf(tierPorGiros(giros));

  /// Genera una llave de SharedPreferences única por cuenta, para que el
  /// progreso de un usuario nunca se mezcle con el de otro en el mismo
  /// dispositivo. Ej: "jugador@mail.com_saldo".
  String _llave(String base) => '${widget.usuario.email}_$base';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();

    // Calculamos los giros totales ANTES del setState para poder usarlos
    // como base del rango, en caso de que sea la primera vez que se carga
    // el sistema de recompensas (para no pagar bonos retroactivos por
    // rangos que el jugador ya tenía desde antes de esta actualización).
    final girosRuletaGuardados = prefs.getInt(_llave('girosRuleta')) ?? widget.usuario.girosRuleta;
    final girosSlotsGuardados = prefs.getInt(_llave('girosSlots')) ?? widget.usuario.girosSlots;
    final girosHigherLowerGuardados = prefs.getInt(_llave('girosHigherLower')) ?? widget.usuario.girosHigherLower;
    final girosLeonGuardados = prefs.getInt(_llave('girosLeon')) ?? widget.usuario.girosLeon;
    final girosTotalesGuardados =
        girosRuletaGuardados + girosSlotsGuardados + girosHigherLowerGuardados + girosLeonGuardados;

    setState(() {
      // Si es la primera vez que este usuario entra (no hay nada guardado
      // todavía en SharedPreferences), se usan los valores que trae el
      // objeto Usuario recién creado en BaseDatosMemoria.
      _monedas = prefs.getDouble(_llave('saldo')) ?? widget.usuario.monedas;
      _girosRuleta = girosRuletaGuardados;
      _girosSlots = girosSlotsGuardados;
      _girosHigherLower = girosHigherLowerGuardados;
      _girosLeon = girosLeonGuardados;
      _username = prefs.getString(_llave('username')) ?? widget.usuario.username;
      _avatar = prefs.getString(_llave('avatar')) ?? widget.usuario.avatar;
      _ultimoBonusFecha = prefs.getString(_llave('ultimoBonusFecha'));
      _modoOscuro = prefs.getBool(_llave('modoOscuro')) ?? true;
      _tierAlcanzadoIndex = prefs.getInt(_llave('tierAlcanzado')) ?? _indiceTier(girosTotalesGuardados);
      _cargando = false;
    });
  }

  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_llave('saldo'), _monedas);
    await prefs.setInt(_llave('girosRuleta'), _girosRuleta);
    await prefs.setInt(_llave('girosSlots'), _girosSlots);
    await prefs.setInt(_llave('girosHigherLower'), _girosHigherLower);
    await prefs.setInt(_llave('girosLeon'), _girosLeon);
    await prefs.setString(_llave('username'), _username);
    await prefs.setString(_llave('avatar'), _avatar);
    if (_ultimoBonusFecha != null) {
      await prefs.setString(_llave('ultimoBonusFecha'), _ultimoBonusFecha!);
    }
    await prefs.setInt(_llave('tierAlcanzado'), _tierAlcanzadoIndex);

    // Además de SharedPreferences, sincronizamos el objeto Usuario en
    // memoria para que, si el usuario cierra sesión y vuelve a entrar en
    // la MISMA ejecución de la app, BaseDatosMemoria ya tenga el dato
    // actualizado sin depender de releer el disco.
    widget.usuario
      ..monedas = _monedas
      ..girosRuleta = _girosRuleta
      ..girosSlots = _girosSlots
      ..girosHigherLower = _girosHigherLower
      ..girosLeon = _girosLeon
      ..username = _username
      ..avatar = _avatar
      ..ultimoBonusFecha = _ultimoBonusFecha
      ..modoOscuro = _modoOscuro;
  }

  Future<void> _alternarModo() async {
    setState(() {
      _modoOscuro = !_modoOscuro;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_llave('modoOscuro'), _modoOscuro);
  }

  void _reclamarBonusDiario() {
    if (!_bonusDisponibleHoy) return;
    setState(() {
      _monedas += montoBonusDiario;
      _ultimoBonusFecha = _fechaHoyComoTexto();
    });
    _guardarDatos();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF7F1D1D),
        content: Row(
          children: [
            const Icon(Icons.card_giftcard, color: Colors.amber),
            const SizedBox(width: 10),
            Text('¡Reclamaste $montoBonusDiario monedas de bonus diario!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Revisa si, después de la última partida, el jugador subió de rango
  /// VIP (según sus giros totales). Si subió uno o más rangos de golpe,
  /// paga el bono correspondiente por cada rango avanzado y muestra un
  /// diálogo de celebración. Debe llamarse justo después de actualizar
  /// _girosX y _guardarDatos() en cualquiera de los juegos.
  void _verificarAvanceDeRango() {
    final nuevoIndice = _indiceTier(_girosTotales);
    if (nuevoIndice <= _tierAlcanzadoIndex) return; // no hubo avance

    final rangosAvanzados = nuevoIndice - _tierAlcanzadoIndex;
    final bonusGanado = bonusPorAvanzarRango * rangosAvanzados;
    final nuevoTier = vipTiers[nuevoIndice];

    setState(() {
      _monedas += bonusGanado;
      _tierAlcanzadoIndex = nuevoIndice;
    });
    _guardarDatos();
    _confettiController.play();
    _mostrarDialogoAvanceRango(nuevoTier, bonusGanado);
  }

  void _mostrarDialogoAvanceRango(VipTier nuevoTier, int bonusGanado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0505),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: nuevoTier.color, width: 2),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(nuevoTier.icono, color: nuevoTier.color, size: 52),
            const SizedBox(height: 10),
            Text(
              '¡Subiste a rango ${nuevoTier.nombre}!',
              textAlign: TextAlign.center,
              style: TextStyle(color: nuevoTier.color, fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recibiste un bono de $bonusGanado monedas por avanzar de nivel.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Multiplicador de premios: x${nuevoTier.multiplicador.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('¡Genial!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirPerfil() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          username: _username,
          avatar: _avatar,
          girosTotales: _girosTotales,
          saldoActual: _monedas,
        ),
      ),
    );
    if (resultado != null && resultado is Map) {
      setState(() {
        _username = resultado['username'] as String;
        _avatar = resultado['avatar'] as String;
      });
      _guardarDatos();
    }
  }

  Future<void> _abrirRecarga() async {
    final saldoActualizado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepositScreen(
          monedasActuales: _monedas.toInt(),
        ),
      ),
    );

    if (saldoActualizado != null && saldoActualizado is int) {
      setState(() {
        _monedas = saldoActualizado.toDouble();
      });
      _guardarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF7F1D1D),
            content: Text('¡Saldo actualizado correctamente!',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Cierra la sesión: guarda el progreso actual, limpia el usuarioActual
  /// en BaseDatosMemoria y regresa a AuthScreen eliminando todo el
  /// historial de navegación (para que no se pueda volver al Home con
  /// el botón "atrás").
  Future<void> _cerrarSesion() async {
    await _guardarDatos();
    BaseDatosMemoria.instancia.cerrarSesion();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A0505),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    // Paletas de color según el modo
    final colorFondoScaffold = _modoOscuro ? const Color(0xFF1A0505) : const Color(0xFFFFF8E1);
    final colorAppBar = _modoOscuro ? const Color(0xFF7F1D1D) : const Color(0xFFB91C1C);
    final colorTituloAppBar = _modoOscuro ? Colors.amber : Colors.white;
    final colorTextoPrincipal = _modoOscuro ? Colors.white : const Color(0xFF3A0A0A);
    final colorTextoSecundario = _modoOscuro ? Colors.white70 : const Color(0xFF6B1010);
    final colorChipSaldoFondo = _modoOscuro ? Colors.amber.withValues(alpha: 0.2) : Colors.white;
    final colorChipSaldoBorde = _modoOscuro ? Colors.amber : const Color(0xFFB91C1C);
    final colorChipSaldoTexto = _modoOscuro ? Colors.white : const Color(0xFF3A0A0A);
    final gradienteFondo = _modoOscuro
        ? const [Color(0xFF1A0505), Color(0xFF450A0A)]
        : const [Color(0xFFFFF8E1), Color(0xFFFFE0B2)];
    final colorBonusFondoInactivo = _modoOscuro ? Colors.black26 : Colors.white;
    final colorBonusBotonInactivoTexto = _modoOscuro ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: colorFondoScaffold,
      appBar: AppBar(
        backgroundColor: colorAppBar,
        title: Text(
          'CASINO LATAM',
          style: TextStyle(
            color: colorTituloAppBar,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Mi perfil',
          icon: Text(_avatar, style: const TextStyle(fontSize: 22)),
          onPressed: _abrirPerfil,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorChipSaldoFondo,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorChipSaldoBorde, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.monetization_on, color: colorChipSaldoBorde, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      _monedas.toStringAsFixed(0),
                      style: TextStyle(
                        color: colorChipSaldoTexto,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Recargar saldo',
            icon: Icon(Icons.add_card, color: colorTituloAppBar, size: 26),
            onPressed: _abrirRecarga,
          ),
          IconButton(
            tooltip: _modoOscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            icon: Icon(
              _modoOscuro ? Icons.light_mode : Icons.dark_mode,
              color: colorTituloAppBar,
              size: 24,
            ),
            onPressed: _alternarModo,
          ),
          // --- Botón de Cerrar Sesión (requisito obligatorio) ---
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: Icon(Icons.logout, color: colorTituloAppBar, size: 24),
            onPressed: _cerrarSesion,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradienteFondo,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Encabezado de bienvenida con el correo de la cuenta activa ---
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selecciona un juego',
                          style: TextStyle(
                            color: colorTextoPrincipal,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.usuario.email,
                          style: TextStyle(color: colorTextoSecundario, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tarjeta de Bonus Diario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _bonusDisponibleHoy
                      ? const LinearGradient(colors: [Color(0xFF7F1D1D), Color(0xFFB45309)])
                      : null,
                  color: _bonusDisponibleHoy ? null : colorBonusFondoInactivo,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _modoOscuro
                        ? Colors.amber.withValues(alpha: _bonusDisponibleHoy ? 0.8 : 0.3)
                        : const Color(0xFFB91C1C).withValues(alpha: _bonusDisponibleHoy ? 0.8 : 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.card_giftcard,
                        color: _bonusDisponibleHoy ? Colors.amber : colorTextoSecundario, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bonusDisponibleHoy ? '¡Bonus diario disponible!' : 'Bonus diario reclamado',
                            style: TextStyle(
                              color: _bonusDisponibleHoy ? Colors.white : colorTextoPrincipal,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _bonusDisponibleHoy
                                ? 'Reclama $montoBonusDiario monedas gratis hoy'
                                : 'Vuelve mañana por más monedas',
                            style: TextStyle(
                              color: _bonusDisponibleHoy ? Colors.white70 : colorTextoSecundario,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _bonusDisponibleHoy ? _reclamarBonusDiario : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        disabledBackgroundColor: _modoOscuro ? Colors.white24 : Colors.black12,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _bonusDisponibleHoy ? 'Reclamar' : 'Reclamado',
                        style: TextStyle(
                          color: _bonusDisponibleHoy ? Colors.black : colorBonusBotonInactivoTexto,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    GameCard(
                      titulo: 'Ruleta',
                      subtitulo: 'Gana al rojo o negro',
                      icono: Icons.pie_chart,
                      color: Colors.amber,
                      onTap: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouletteScreen(
                              saldoActual: _monedas,
                              girosPrevios: _girosRuleta,
                              multiplicadorVip: _multiplicadorVip,
                            ),
                          ),
                        );
                        if (resultado != null && resultado is Map) {
                          setState(() {
                            _monedas = resultado['saldo'] as double;
                            _girosRuleta = resultado['giros'] as int;
                          });
                          _guardarDatos();
                          _verificarAvanceDeRango();
                        }
                      },
                    ),
                    GameCard(
                      titulo: 'Tragamonedas',
                      subtitulo: 'Busca el Jackpot',
                      icono: Icons.casino,
                      color: Colors.redAccent,
                      onTap: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SlotsScreen(
                              saldoActual: _monedas,
                              girosPrevios: _girosSlots,
                              multiplicadorVip: _multiplicadorVip,
                            ),
                          ),
                        );
                        if (resultado != null && resultado is Map) {
                          setState(() {
                            _monedas = resultado['saldo'] as double;
                            _girosSlots = resultado['giros'] as int;
                          });
                          _guardarDatos();
                          _verificarAvanceDeRango();
                        }
                      },
                    ),
                    GameCard(
                      titulo: 'Mayor o Menor',
                      subtitulo: 'Adivina la carta',
                      icono: Icons.style,
                      color: const Color(0xFFFFD700),
                      onTap: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HigherLowerScreen(
                              saldoActual: _monedas,
                              girosPrevios: _girosHigherLower,
                              multiplicadorVip: _multiplicadorVip,
                            ),
                          ),
                        );
                        if (resultado != null && resultado is Map) {
                          setState(() {
                            _monedas = resultado['saldo'] as double;
                            _girosHigherLower = resultado['giros'] as int;
                          });
                          _guardarDatos();
                          _verificarAvanceDeRango();
                        }
                      },
                    ),
                    GameCard(
                      titulo: 'El León de la Suerte',
                      subtitulo: 'Corre y esquiva',
                      icono: Icons.directions_run,
                      color: Colors.orangeAccent,
                      onTap: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LionRunnerScreen(
                              saldoActual: _monedas,
                              girosPrevios: _girosLeon,
                              multiplicadorVip: _multiplicadorVip,
                            ),
                          ),
                        );
                        if (resultado != null && resultado is Map) {
                          setState(() {
                            _monedas = resultado['saldo'] as double;
                            _girosLeon = resultado['giros'] as int;
                          });
                          _guardarDatos();
                          _verificarAvanceDeRango();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
          SimpleConfettiOverlay(controller: _confettiController),
        ],
      ),
    );
  }
}