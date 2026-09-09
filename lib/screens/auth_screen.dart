import 'package:flutter/material.dart';
import 'base_datos_memoria.dart';
import 'home_screen.dart';

/// Pantalla de autenticación (Registro / Inicio de sesión).
///
/// Alterna entre dos modos usando un solo formulario:
///  - Modo "Iniciar sesión": valida contra un usuario ya existente.
///  - Modo "Registrarse": crea un usuario nuevo en [BaseDatosMemoria].
///
/// Al autenticar con éxito, navega reemplazando esta pantalla por
/// [HomeScreen], pasándole el [Usuario] que quedó activo en la sesión.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _modoRegistro = false; // false = login, true = registro
  bool _ocultarPassword = true;
  bool _procesando = false;
  String? _errorGeneral; // errores que no son de un campo específico (ej: "correo ya registrado")

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _alternarModo() {
    setState(() {
      _modoRegistro = !_modoRegistro;
      _errorGeneral = null;
      _formKey.currentState?.reset();
    });
  }

  String? _validarEmail(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Ingresa tu correo';
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(valor.trim())) return 'Correo no válido';
    return null;
  }

  String? _validarPassword(String? valor) {
    if (valor == null || valor.isEmpty) return 'Ingresa tu contraseña';
    if (valor.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _enviarFormulario() async {
    // Valida los campos del formulario (formato de correo, largo de password).
    final formularioValido = _formKey.currentState?.validate() ?? false;
    if (!formularioValido) return;

    setState(() {
      _procesando = true;
      _errorGeneral = null;
    });

    // Pequeño delay simulado para que se sienta como una llamada real a un
    // servidor (mejora la percepción de la UI, no es obligatorio).
    await Future.delayed(const Duration(milliseconds: 400));

    final email = _emailController.text;
    final password = _passwordController.text;
    final db = BaseDatosMemoria.instancia;

    // Según el modo activo, intenta registrar o iniciar sesión.
    final String? error = _modoRegistro
        ? db.registrar(email: email, password: password)
        : db.iniciarSesion(email: email, password: password);

    if (!mounted) return;

    if (error != null) {
      // Falló: mostramos el error visual y dejamos de "procesar".
      setState(() {
        _errorGeneral = error;
        _procesando = false;
      });
      return;
    }

    // Éxito: navegamos al Home reemplazando esta pantalla (para que el
    // botón de "atrás" del sistema no regrese al login).
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(usuario: db.usuarioActual!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F0F), Color(0xFF450A0A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Logo / título estilo arcade ---
                    const Icon(Icons.casino, color: Colors.amber, size: 72),
                    const SizedBox(height: 12),
                    const Text(
                      'CASINO LATAM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _modoRegistro ? 'Crea tu cuenta para jugar' : 'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 32),

                    // --- Tarjeta del formulario ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A0505),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Campo correo
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            style: const TextStyle(color: Colors.white),
                            validator: _validarEmail,
                            decoration: _decoracionCampo(
                              etiqueta: 'Correo electrónico',
                              icono: Icons.email_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Campo contraseña con opción de mostrar/ocultar
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _ocultarPassword,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            style: const TextStyle(color: Colors.white),
                            validator: _validarPassword,
                            decoration: _decoracionCampo(
                              etiqueta: 'Contraseña',
                              icono: Icons.lock_outline,
                              sufijo: IconButton(
                                icon: Icon(
                                  _ocultarPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.amber.withValues(alpha: 0.7),
                                ),
                                onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                              ),
                            ),
                          ),

                          // Mensaje de error general (correo repetido, credenciales
                          // incorrectas, cuenta inexistente, etc).
                          if (_errorGeneral != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorGeneral!,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),

                          // Botón principal: Registrarse / Iniciar sesión
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _procesando ? null : _enviarFormulario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                disabledBackgroundColor: Colors.red.shade900.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.amber, width: 1.5),
                                ),
                              ),
                              child: _procesando
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.amber),
                                    )
                                  : Text(
                                      _modoRegistro ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
                                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Botón para alternar entre modo Login / Registro ---
                    TextButton(
                      onPressed: _procesando ? null : _alternarModo,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13),
                          children: [
                            TextSpan(
                              text: _modoRegistro ? '¿Ya tienes cuenta? ' : '¿No tienes cuenta? ',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            TextSpan(
                              text: _modoRegistro ? 'Inicia sesión' : 'Regístrate',
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Estilo de campo reutilizable, coherente con la paleta oscura/ámbar
  /// del resto de la app (mismos tonos que HomeScreen y las pantallas de
  /// juego: fondo negro, bordes ámbar, texto blanco).
  InputDecoration _decoracionCampo({
    required String etiqueta,
    required IconData icono,
    Widget? sufijo,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icono, color: Colors.amber.withValues(alpha: 0.8)),
      suffixIcon: sufijo,
      filled: true,
      fillColor: Colors.black26,
      errorStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
    );
  }
}