import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

/// ============================================================
/// EL LEÓN DE LA SUERTE 🦁 (Con Apuesta Personalizada y Doble Salto)
/// ============================================================

enum _EstadoJuego { seleccionMultiplicador, esperando, jugando, terminado }

enum _TipoObjeto { moneda, obstaculoCasinoSuelo, tragamonedasCaida }

class _ObjetoJuego {
  double x;
  double y; // 0 es el suelo
  final double ancho;
  final double alto;
  final _TipoObjeto tipo;
  bool asentado;
  double velocidadCaida;
  final bool esLetal;
  bool recolectado;
  final String simboloCasino;

  _ObjetoJuego({
    required this.x,
    required this.y,
    required this.ancho,
    required this.alto,
    required this.tipo,
    this.asentado = true,
    this.velocidadCaida = 0,
    this.esLetal = false,
    this.recolectado = false,
    this.simboloCasino = '🎰',
  });
}

class _ZonaAdvertencia {
  double x;
  double tiempoRestante;
  final bool esLetal;
  _ZonaAdvertencia({required this.x, required this.tiempoRestante, required this.esLetal});
}

class LionRunnerScreen extends StatefulWidget {
  final double saldoActual;
  final int girosPrevios;
  final double multiplicadorVip;

  const LionRunnerScreen({
    super.key,
    required this.saldoActual,
    required this.girosPrevios,
    this.multiplicadorVip = 1.0,
  });

  @override
  State<LionRunnerScreen> createState() => _LionRunnerScreenState();
}

class _LionRunnerScreenState extends State<LionRunnerScreen>
    with SingleTickerProviderStateMixin {
  static const double _gravedad = 1900.0;
  static const double _velocidadBase = 280.0;
  static const double _gravedadCaidaMaquina = 1700.0; 
  
  static const double _lionAncho = 56;
  static const double _lionAlto = 72;
  static const double _lionX = 70; 
  static const double _margenSuelo = 26; 

  bool _estaPresionando = false;
  double _tiempoPresion = 0.0;
  static const double _impulsoBase = 530.0;
  static const double _impulsoMaximoAdicional = 430.0;
  static const double _tiempoMaxPresion = 0.28;

  // Control de Doble Salto
  bool _puedeDobleSalto = true;
  bool _estaRealizandoDobleSalto = false;

  late final Ticker _ticker;
  Duration? _ultimoTick;

  _EstadoJuego _estado = _EstadoJuego.seleccionMultiplicador;
  int _multiplicadorSeleccionado = 1;
  double _importeApuesta = 10.0; // Importe que el usuario desea apostar
  
  // Variable de estado para llevar el control del saldo actual mutable durante la sesión de juego
  late double _saldoEnJuego;

  double _lionAltura = 0; 
  double _velocidadY = 0; 
  double _cicloCorrida = 0; 

  int _monedasRecolectadas = 0;
  double _gameSpeed = _velocidadBase;
  double _distanciaRecorrida = 0;

  final List<_ObjetoJuego> _objetos = [];
  final List<_ZonaAdvertencia> _advertenciasSuelo = [];
  
  double _tiempoParaSpawn = 0.4;
  final Random _random = Random();

  bool _apocalipsisActivo = false;
  double _tiempoApocalipsisRestante = 0;
  double _tiempoParaProximoEvento = 4.0; 
  double _alertaIntensidad = 0; 

  double _shakeTiempoRestante = 0;
  double _shakeMagnitud = 0;
  double _shakeDx = 0;
  double _shakeDy = 0;

  double _anchoCanvas = 360;
  double _altoCanvas = 320;

  late TextEditingController _controladorApuesta;

  @override
  void initState() {
    super.initState();
    _saldoEnJuego = widget.saldoActual;
    _ticker = createTicker(_onTick);
    _controladorApuesta = TextEditingController(text: _importeApuesta.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controladorApuesta.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_ultimoTick == null) {
      _ultimoTick = elapsed;
      return;
    }
    double dt = (elapsed - _ultimoTick!).inMicroseconds / 1000000.0;
    _ultimoTick = elapsed;
    dt = dt.clamp(0.0, 0.033);

    if (_estado == _EstadoJuego.jugando) {
      _actualizarJuego(dt);
    }

    _actualizarShake(dt);
    setState(() {});
  }

  void _actualizarJuego(double dt) {
    if (_estaPresionando) {
      _tiempoPresion += dt;
      if (_tiempoPresion <= _tiempoMaxPresion) {
        if (_lionAltura == 0) {
          _velocidadY += (_impulsoMaximoAdicional * 3.5) * dt;
        } else if (_estaRealizandoDobleSalto) {
          _velocidadY += (_impulsoMaximoAdicional * 3.2) * dt;
        }
      }
    }

    if (_lionAltura > 0 || _velocidadY != 0) {
      _velocidadY -= _gravedad * dt;
      _lionAltura += _velocidadY * dt;
      if (_lionAltura <= 0) {
        _lionAltura = 0;
        _velocidadY = 0;
        _puedeDobleSalto = true;
        _estaRealizandoDobleSalto = false;
      }
    } else {
      _cicloCorrida += dt * (_gameSpeed / _velocidadBase) * 9;
      _puedeDobleSalto = true;
      _estaRealizandoDobleSalto = false;
    }

    _gameSpeed = _velocidadBase + (_distanciaRecorrida * 0.025);
    if (_gameSpeed > _velocidadBase * 2.6) {
      _gameSpeed = _velocidadBase * 2.6;
    }

    _distanciaRecorrida += _gameSpeed * dt;

    for (var adv in _advertenciasSuelo) {
      adv.tiempoRestante -= dt;
    }
    _advertenciasSuelo.removeWhere((adv) => adv.tiempoRestante <= 0);

    if (!_apocalipsisActivo) {
      _tiempoParaSpawn -= dt;
      if (_tiempoParaSpawn <= 0) {
        double tipoRand = _random.nextDouble();
        
        if (tipoRand < 0.35) {
          _spawnMonedaSuelo();
        } else if (tipoRand < 0.70) {
          _spawnObstaculoCasinoSuelo();
        } else {
          bool esLetal = _random.nextDouble() < (0.2 + (_multiplicadorSeleccionado * 0.03));
          _spawnTragamonedasCaida(esLetal: esLetal);
        }
        
        final factorDificultad = (_velocidadBase / _gameSpeed).clamp(0.4, 0.9);
        _tiempoParaSpawn = (0.35 + _random.nextDouble() * 0.45) * factorDificultad;
      }
    }

    for (final obj in _objetos) {
      if (obj.tipo == _TipoObjeto.tragamonedasCaida && !obj.asentado) {
        obj.velocidadCaida -= _gravedadCaidaMaquina * dt;
        obj.y += obj.velocidadCaida * dt;
        if (obj.y <= 0) {
          obj.y = 0;
          obj.asentado = true;
          _dispararShake(intensidad: 14, duracion: 0.35);

          if (obj.esLetal && _colisionaConImpactoCaida(obj)) {
            _terminarJuego();
            return;
          }
        }
      }
      obj.x -= _gameSpeed * dt;
    }

    _verificarColisionesYRecoleccion();

    _objetos.removeWhere((o) => o.x + o.ancho < -50 || o.recolectado);

    if (_apocalipsisActivo) {
      _tiempoApocalipsisRestante -= dt;
      _alertaIntensidad = (_alertaIntensidad + dt * 4).clamp(0.0, 1.0);
      if (_tiempoApocalipsisRestante <= 0) {
        _apocalipsisActivo = false;
        _tiempoParaProximoEvento = 4.0 + _random.nextDouble() * 5.0; 
      }
    } else {
      _alertaIntensidad = (_alertaIntensidad - dt * 2).clamp(0.0, 1.0);
      _tiempoParaProximoEvento -= dt;
      if (_tiempoParaProximoEvento <= 0) {
        _activarApocalipsisAleatorio();
      }
    }
  }

  void _actualizarShake(double dt) {
    if (_shakeTiempoRestante > 0) {
      _shakeTiempoRestante -= dt;
      final t = (_shakeTiempoRestante / 0.35).clamp(0.0, 1.0);
      final magnitudActual = _shakeMagnitud * t;
      _shakeDx = (_random.nextDouble() - 0.5) * 2 * magnitudActual;
      _shakeDy = (_random.nextDouble() - 0.5) * 2 * magnitudActual;
      if (_shakeTiempoRestante <= 0) {
        _shakeDx = 0;
        _shakeDy = 0;
      }
    }
  }

  void _dispararShake({required double intensidad, required double duracion}) {
    _shakeMagnitud = intensidad;
    _shakeTiempoRestante = duracion;
  }

  void _spawnMonedaSuelo() {
    _objetos.add(_ObjetoJuego(
      x: _anchoCanvas + 30,
      y: 0,
      ancho: 34,
      alto: 34,
      tipo: _TipoObjeto.moneda,
      asentado: true,
      esLetal: false,
    ));
  }

  void _spawnObstaculoCasinoSuelo() {
    final List<Map<String, dynamic>> obstaculosTipos = [
      {'simbolo': '🎰', 'ancho': 48.0, 'alto': 64.0},
      {'simbolo': '🃏', 'ancho': 52.0, 'alto': 50.0},
      {'simbolo': '🎡', 'ancho': 50.0, 'alto': 62.0},
    ];

    final elegido = obstaculosTipos[_random.nextInt(obstaculosTipos.length)];

    _objetos.add(_ObjetoJuego(
      x: _anchoCanvas + 30,
      y: 0,
      ancho: elegido['ancho'] as double,
      alto: elegido['alto'] as double,
      tipo: _TipoObjeto.obstaculoCasinoSuelo,
      asentado: true,
      esLetal: true,
      simboloCasino: elegido['simbolo'] as String,
    ));
  }

  void _spawnTragamonedasCaida({required bool esLetal}) {
    double posXObjetivo = _lionX + 50 + _random.nextDouble() * 130;
    _advertenciasSuelo.add(_ZonaAdvertencia(x: posXObjetivo, tiempoRestante: 0.65, esLetal: esLetal));

    _objetos.add(_ObjetoJuego(
      x: posXObjetivo,
      y: _altoCanvas + 30,
      ancho: 52,
      alto: 64,
      tipo: _TipoObjeto.tragamonedasCaida,
      asentado: false,
      velocidadCaida: 0,
      esLetal: esLetal,
      simboloCasino: '🎰',
    ));
  }

  void _activarApocalipsisAleatorio() {
    _apocalipsisActivo = true;
    _tiempoApocalipsisRestante = 3.0;
    _dispararShake(intensidad: 15, duracion: 0.5);

    int cantidadObstaculos = 2 + (_multiplicadorSeleccionado >= 10 ? 2 : 1);
    for (int i = 0; i < cantidadObstaculos; i++) {
      double posX = _anchoCanvas + 40 + (i * 85);
      _objetos.add(_ObjetoJuego(
        x: posX,
        y: 0,
        ancho: 48,
        alto: 60,
        tipo: _TipoObjeto.obstaculoCasinoSuelo,
        asentado: true,
        esLetal: true,
        simboloCasino: '🎰',
      ));
    }
  }

  bool _colisionaConImpactoCaida(_ObjetoJuego o) {
    final lionLeft = _lionX;
    final lionRight = _lionX + _lionAncho;
    final obsLeft = o.x;
    final obsRight = o.x + o.ancho;

    bool colisionaH = lionLeft < obsRight - 10 && lionRight > obsLeft + 10;
    return colisionaH && _lionAltura < 20;
  }

  void _verificarColisionesYRecoleccion() {
    final lionTop = _lionAltura;
    final lionLeft = _lionX;
    final lionRight = _lionX + _lionAncho;

    for (final obj in _objetos) {
      if (obj.recolectado) continue;

      final objLeft = obj.x;
      final objRight = obj.x + obj.ancho;

      if (obj.tipo == _TipoObjeto.moneda) {
        const margenPerdon = 14.0;
        final colisionaH = lionLeft + margenPerdon < objRight - margenPerdon &&
            lionRight - margenPerdon > objLeft + margenPerdon;
        final solapaVertical = lionTop < 32; 

        if (colisionaH && solapaVertical) {
          obj.recolectado = true;
          _monedasRecolectadas++; 
        }
      } else if (obj.tipo == _TipoObjeto.obstaculoCasinoSuelo) {
        const margenPerdon = 10.0;
        final colisionaH = lionLeft + margenPerdon < objRight - margenPerdon &&
            lionRight - margenPerdon > objLeft + margenPerdon;
        
        final solapaVertical = lionTop < (obj.alto - 8);

        if (colisionaH && solapaVertical) {
          _terminarJuego();
          return;
        }
      }
    }
  }

  void _iniciarPresion() {
    if (_estado == _EstadoJuego.esperando) {
      _comenzarCarrera();
      return;
    }
    if (_estado == _EstadoJuego.jugando) {
      if (_lionAltura == 0) {
        _estaPresionando = true;
        _tiempoPresion = 0.0;
        _velocidadY = _impulsoBase;
      } else if (_puedeDobleSalto) {
        _estaPresionando = true;
        _tiempoPresion = 0.0;
        _velocidadY = _impulsoBase * 0.85; 
        _puedeDobleSalto = false;
        _estaRealizandoDobleSalto = true;
      }
    }
  }

  void _soltarPresion() {
    _estaPresionando = false;
  }

  void _seleccionarMultiplicador(int mult) {
    double importeIngresado = double.tryParse(_controladorApuesta.text) ?? 0.0;

    if (importeIngresado <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('⚠️ Introduce un importe de apuesta válido mayor a 0.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_saldoEnJuego < importeIngresado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('❌ No tienes suficiente saldo en la cuenta para esta apuesta.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _importeApuesta = importeIngresado;
      _multiplicadorSeleccionado = mult;
      _estado = _EstadoJuego.esperando;
    });
  }

  void _comenzarCarrera() {
    _saldoEnJuego -= _importeApuesta;

    setState(() {
      _estado = _EstadoJuego.jugando;
      _monedasRecolectadas = 0;
      _distanciaRecorrida = 0;
      _gameSpeed = _velocidadBase;
      _lionAltura = 0;
      _velocidadY = 0;
      _estaPresionando = false;
      _puedeDobleSalto = true;
      _estaRealizandoDobleSalto = false;
      _objetos.clear();
      _advertenciasSuelo.clear();
      _tiempoParaSpawn = 0.4;
      _apocalipsisActivo = false;
      _alertaIntensidad = 0;
      _tiempoParaProximoEvento = 3.5 + _random.nextDouble() * 4.0;
      _ultimoTick = null;
    });
    _ticker.start();
  }

  void _reiniciarConMismaApuesta() {
    _ticker.stop();
    if (_saldoEnJuego < _importeApuesta) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('❌ Saldo insuficiente para reinvertir la misma apuesta. Cambia tu importe.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _estado = _EstadoJuego.seleccionMultiplicador;
      });
      return;
    }
    _comenzarCarrera();
  }

  void _terminarJuego() {
    _ticker.stop();
    setState(() {
      _estado = _EstadoJuego.terminado;
    });
  }

  void _reintentar() {
    _ticker.stop();
    setState(() {
      _estado = _EstadoJuego.seleccionMultiplicador;
    });
  }

  void _intentarCobrarOpcion() {
    _ticker.stop();
    
    final valorPorMoneda = _importeApuesta * _multiplicadorSeleccionado;
    final premioMonedas = _monedasRecolectadas * valorPorMoneda;
    final botinActual = premioMonedas * widget.multiplicadorVip;

    if (_monedasRecolectadas <= 0) {
      _cobrarFinalDirecto(0.0);
      return;
    }

    _mostrarJuicioDelLeonCartas(botinActual);
  }

  void _mostrarJuicioDelLeonCartas(double acumuladoActual) {
    final int indiceGanador = _random.nextInt(3);
    bool revelado = false;
    int cartaSeleccionada = -1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A0505),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.amber, width: 2),
              ),
              title: const Column(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'EL JUICIO DEL LEÓN',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Botín en juego: \$${acumuladoActual.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Elige una carta dorada. ¡Al seleccionarla, todas se voltearán para revelar las posiciones!',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      final esGanadora = (index == indiceGanador);
                      return GestureDetector(
                        onTap: revelado ? null : () {
                          setStateDialog(() {
                            revelado = true;
                            cartaSeleccionada = index;
                          });
                          
                          Future.delayed(const Duration(milliseconds: 1100), () {
                            Navigator.pop(context);
                            if (esGanadora) {
                              double nuevoMonto = acumuladoActual * 2;
                              _mostrarAlertaVictoriaExtra(nuevoMonto);
                              _cobrarFinalDirecto(nuevoMonto); 
                            } else {
                              _mostrarAlertaDerrotaTotal();
                              _cobrarFinalDirecto(0.0); 
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 75,
                          height: 105,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: revelado
                                  ? (esGanadora ? const [Color(0xFF065F46), Color(0xFF047857)] : const [Color(0xFF7F1D1D), Color(0xFF450A0A)])
                                  : const [Color(0xFFB45309), Color(0xFF7F1D1D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: revelado
                                  ? (esGanadora ? Colors.greenAccent : Colors.redAccent)
                                  : (cartaSeleccionada == index ? Colors.amberAccent : Colors.amber),
                              width: cartaSeleccionada == index ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (revelado
                                        ? (esGanadora ? Colors.greenAccent : Colors.redAccent)
                                        : Colors.amber)
                                    .withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              revelado ? (esGanadora ? '🦁✨' : '🦁💀') : '🎴',
                              style: TextStyle(fontSize: revelado ? 26 : 30),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                if (!revelado)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _cobrarFinalDirecto(acumuladoActual);
                    },
                    child: const Text('Cobrar seguro y salir', style: TextStyle(color: Colors.grey)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarAlertaDerrotaTotal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF7F1D1D),
        content: Text(
          '💥 ¡LEÓN GRIS! Perdiste el importe de tu apuesta.',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarAlertaVictoriaExtra(double nuevoMonto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF065F46),
        content: Text(
          '⚡ ¡LEÓN DORADO! Duplicaste tu botín a \$${nuevoMonto.toStringAsFixed(0)}.',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cobrarFinalDirecto(double gananciaNeta) {
    Navigator.pop(context, {
      'saldo': _saldoEnJuego + gananciaNeta,
      'giros': widget.girosPrevios + 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    final valorMonedaActual = _importeApuesta * _multiplicadorSeleccionado;
    final monedasGeneradasActuales = (_monedasRecolectadas * valorMonedaActual * widget.multiplicadorVip).round();

    return PopScope(
      canPop: _estado != _EstadoJuego.jugando,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _intentarCobrarOpcion();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0505),
        appBar: AppBar(
          backgroundColor: const Color(0xFF7F1D1D),
          title: Text('LEÓN RUNNER (Apuesta: \$$_importeApuesta | x$_multiplicadorSeleccionado)',
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.amber),
            onPressed: _intentarCobrarOpcion,
          ),
        ),
        body: Column(
          children: [
            if (_estado != _EstadoJuego.seleccionMultiplicador) _buildHudSuperior(monedasGeneradasActuales),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _anchoCanvas = constraints.maxWidth;
                      _altoCanvas = constraints.maxHeight;
                      return GestureDetector(
                        onTapDown: (_) => _iniciarPresion(),
                        onTapUp: (_) => _soltarPresion(),
                        onTapCancel: _soltarPresion,
                        child: Transform.translate(
                          offset: Offset(_shakeDx, _shakeDy),
                          child: Container(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2),
                            ),
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                _buildFondoCortinas(),
                                _buildPiso(),
                                ..._advertenciasSuelo.map(_buildZonaAdvertenciaSuelo),
                                ..._objetos.map(_buildObjetoJuegoWidget),
                                _buildLeonConEsmoquin(),
                                if (_estado == _EstadoJuego.seleccionMultiplicador) _buildPantallaSeleccionMultiplicador(),
                                if (_estado == _EstadoJuego.esperando) _buildOverlayEsperando(),
                                if (_estado == _EstadoJuego.terminado) _buildOverlayGameOver(),
                                if (_apocalipsisActivo) _buildBannerApocalipsis(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_estado != _EstadoJuego.seleccionMultiplicador) _buildBotonRetirada(monedasGeneradasActuales),
          ],
        ),
      ),
    );
  }

  Widget _buildPantallaSeleccionMultiplicador() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xEE1A0505),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🦁', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 4),
              const Text(
                'CONFIGURA TU APUESTA Y RIESGO',
                style: TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    const Text('Importe a apostar (\$): ', style: TextStyle(color: Colors.white, fontSize: 13)),
                    Expanded(
                      child: TextField(
                        controller: _controladorApuesta,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Ej. 50',
                          hintStyle: TextStyle(color: Colors.white24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Saldo actual disponible: \$${_saldoEnJuego.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text(
                'Selecciona el Multiplicador de Riesgo:',
                style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 5, 10, 15, 20].map((mult) {
                  bool esExtremo = mult >= 15;
                  return ElevatedButton(
                    onPressed: () => _seleccionarMultiplicador(mult),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: esExtremo ? const Color(0xFF991B1B) : const Color(0xFF7F1D1D),
                      foregroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: esExtremo ? Colors.redAccent : Colors.amber, width: 1.5),
                      ),
                    ),
                    child: Text(
                      'x$mult',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: esExtremo ? 14 : 12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHudSuperior(int valorTotalAcumulado) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.amber, size: 18),
              const SizedBox(width: 6),
              Text('Apuesta: \$$_importeApuesta',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 4),
              Text('Monedas: $_monedasRecolectadas (\$${valorTotalAcumulado.toStringAsFixed(0)})',
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonRetirada(int valorTotalAcumulado) {
    final bool tieneMonedas = _monedasRecolectadas > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.black87,
      child: ElevatedButton.icon(
        onPressed: _intentarCobrarOpcion,
        style: ElevatedButton.styleFrom(
          backgroundColor: tieneMonedas ? const Color(0xFFB91C1C) : Colors.grey[800],
          foregroundColor: Colors.amber,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Colors.amber, width: 1.5),
        ),
        icon: Icon(
          tieneMonedas ? Icons.exit_to_app : Icons.arrow_back,
          color: Colors.amber,
        ),
        label: Text(
          tieneMonedas ? 'COBRAR Y SALIR' : 'SALIR',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber),
        ),
      ),
    );
  }

  Widget _buildFondoCortinas() {
    final colorNormalClaro = const Color(0xFF7F1D1D);
    final colorNormalOscuro = const Color(0xFF450A0A);
    return Positioned.fill(
      child: CustomPaint(
        painter: _CortinasPainter(colorClaro: colorNormalClaro, colorOscuro: colorNormalOscuro),
      ),
    );
  }

  Widget _buildPiso() {
    final desplazamiento = _distanciaRecorrida % 60;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: _margenSuelo + 18,
      child: CustomPaint(
        painter: _PisoPainter(desplazamiento: desplazamiento),
      ),
    );
  }

  Widget _buildZonaAdvertenciaSuelo(_ZonaAdvertencia adv) {
    return Positioned(
      left: adv.x - 20,
      bottom: _margenSuelo - 4,
      child: Container(
        width: 44,
        height: 12,
        decoration: BoxDecoration(
          color: (adv.esLetal ? Colors.red : Colors.orange).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber, width: 1),
        ),
        child: const Center(
          child: Text('⚠️', style: TextStyle(fontSize: 8)),
        ),
      ),
    );
  }

  Widget _buildLeonConEsmoquin() {
    double escalaX = 1.0;
    double escalaY = 1.0;
    if (_lionAltura > 0 && _velocidadY > 0) {
      escalaX = 0.92;
      escalaY = 1.1; 
    } else if (_lionAltura > 0 && _velocidadY < 0) {
      escalaX = 1.06;
      escalaY = 0.94; 
    }

    final rebote = (_lionAltura == 0 && _estado == _EstadoJuego.jugando)
        ? (sin(_cicloCorrida) * 3).abs()
        : 0.0;

    return Positioned(
      left: _lionX,
      bottom: _margenSuelo + _lionAltura + rebote,
      child: Transform.scale(
        scaleX: escalaX,
        scaleY: escalaY,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: _lionAncho,
          height: _lionAlto,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('🦁', style: TextStyle(fontSize: 36, height: 1.0)),
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.7), width: 1.5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 14,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(2),
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

  Widget _buildObjetoJuegoWidget(_ObjetoJuego obj) {
    if (obj.recolectado) return const SizedBox.shrink();

    return Positioned(
      left: obj.x,
      bottom: _margenSuelo + obj.y,
      child: SizedBox(
        width: obj.ancho,
        height: obj.alto,
        child: obj.tipo == _TipoObjeto.moneda
            ? _buildMonedaSuelo(obj.ancho)
            : Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.7), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    obj.simboloCasino,
                    style: TextStyle(fontSize: obj.alto * 0.65),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMonedaSuelo(double tamano) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.amber,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1),
        ],
      ),
      child: Center(
        child: Text(
          '🪙',
          style: TextStyle(fontSize: tamano * 0.6),
        ),
      ),
    );
  }

  Widget _buildOverlayEsperando() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🦁', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                'APUESTA: \$$_importeApuesta (Nivel x$_multiplicadorSeleccionado)',
                style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '¡Mantén presionado para saltar alto, y haz otro toque en el aire para un **Doble Salto**!\nToca la pantalla para comenzar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('TOCA PARA CORRER',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayGameOver() {
    final valorMonedaActual = _importeApuesta * _multiplicadorSeleccionado;
    final premioMonedas = (_monedasRecolectadas * valorMonedaActual * widget.multiplicadorVip);
    final bool ganoMonedas = _monedasRecolectadas > 0;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ganoMonedas ? Icons.monetization_on : Icons.flash_on,
                  color: ganoMonedas ? Colors.greenAccent : Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  ganoMonedas ? '¡COLISIÓN, PERO RESCATESTE BOTÍN!' : '¡COLISIÓN CON OBSTÁCULO DE CASINO!',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  ganoMonedas
                      ? 'Recolectaste $_monedasRecolectadas monedas. ¡Obtuviste: +\$${premioMonedas.toStringAsFixed(0)}!'
                      : 'Has perdido tu importe apostado: -\$$_importeApuesta',
                  style: TextStyle(
                    color: ganoMonedas ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // 1. Botón de Reinvertir y seguir jugando
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _reiniciarConMismaApuesta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.replay, color: Colors.white),
                    label: const Text(
                      'Reinvertir y seguir jugando',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Botón de Cambiar Apuesta
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _reintentar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: const BorderSide(color: Colors.amber, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.tune, color: Colors.amber),
                    label: const Text(
                      'Cambiar Apuesta',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerApocalipsis() {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent, width: 1.5),
          ),
          child: Text(
            '⚠️ ¡AVALANCHA DE OBSTÁCULOS x$_multiplicadorSeleccionado! ⚠️',
            style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _CortinasPainter extends CustomPainter {
  final Color colorClaro;
  final Color colorOscuro;

  _CortinasPainter({required this.colorClaro, required this.colorOscuro});

  @override
  void paint(Canvas canvas, Size size) {
    final fondo = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colorOscuro, colorClaro],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fondo);

    final pliegue = Paint()..color = Colors.black.withValues(alpha: 0.12);
    const anchoPliegue = 34.0;
    for (double x = -anchoPliegue; x < size.width + anchoPliegue; x += anchoPliegue) {
      final path = Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(x + anchoPliegue / 2, size.height * 0.35, x, size.height)
        ..lineTo(x + 6, size.height)
        ..quadraticBezierTo(x + anchoPliegue / 2 + 6, size.height * 0.35, x + 6, 0)
        ..close();
      canvas.drawPath(path, pliegue);
    }

    final franjaDorada = Paint()..color = Colors.amber.withValues(alpha: 0.65);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 6), franjaDorada);
  }

  @override
  bool shouldRepaint(covariant _CortinasPainter oldDelegate) => false;
}

class _PisoPainter extends CustomPainter {
  final double desplazamiento;

  _PisoPainter({required this.desplazamiento});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xFF1C1C1C);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), base);

    final lineaSuelo = Paint()
      ..color = Colors.amber.withValues(alpha: 0.85)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, 6), Offset(size.width, 6), lineaSuelo);

    final diagonal = Paint()
      ..color = Colors.amber.withValues(alpha: 0.25)
      ..strokeWidth = 3;
    const separacion = 30.0;
    for (double x = -separacion - desplazamiento; x < size.width + size.height; x += separacion) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        diagonal,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PisoPainter oldDelegate) => true;
}