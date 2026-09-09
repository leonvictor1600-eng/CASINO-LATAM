import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'usuario_modelo.dart';

/// Simula una base de datos de usuarios, con las cuentas (correo +
/// contraseña) persistidas en el almacenamiento del dispositivo.
///
/// Es un Singleton: solo existe UNA instancia en toda la app, accesible
/// desde cualquier pantalla como `BaseDatosMemoria.instancia`. Esto permite
/// que la pantalla de Login y la pantalla Home hablen con el mismo
/// "usuarioActual" sin necesidad de pasar el dato manualmente por cada
/// widget intermedio.
///
/// PERSISTENCIA: solo se guarda el par correo+contraseña de cada cuenta
/// (bajo la llave [_llaveCuentasGuardadas] en SharedPreferences). El
/// progreso de juego (monedas, giros, avatar, etc.) NO se duplica aquí:
/// eso ya lo guarda HomeScreen por separado, usando el correo como parte
/// de sus propias llaves. Por eso, al recrear un Usuario desde disco,
/// basta con sus valores por defecto: HomeScreen los sobrescribe apenas
/// carga con los datos reales de esa cuenta.
///
/// IMPORTANTE: `cargarCuentasGuardadas()` debe llamarse una sola vez, al
/// arrancar la app (antes de `runApp`), para que las cuentas creadas en
/// sesiones anteriores ya estén disponibles cuando AuthScreen las necesite.
class BaseDatosMemoria {
  // Constructor privado + instancia estática = patrón Singleton.
  BaseDatosMemoria._interno();
  static final BaseDatosMemoria instancia = BaseDatosMemoria._interno();

  static const String _llaveCuentasGuardadas = 'cuentas_registradas';

  /// Todos los usuarios registrados, indexados por correo (en minúsculas).
  final Map<String, Usuario> _usuarios = {};

  /// El usuario con sesión activa en este momento. Si es null, nadie ha
  /// iniciado sesión (o cerró sesión).
  Usuario? usuarioActual;

  bool _cuentasCargadas = false;

  bool get haySesionActiva => usuarioActual != null;

  /// Lee del almacenamiento del dispositivo las cuentas (correo +
  /// contraseña) creadas en sesiones anteriores y las carga en memoria.
  /// Es seguro llamarla varias veces: si ya se cargaron, no vuelve a leer.
  Future<void> cargarCuentasGuardadas() async {
    if (_cuentasCargadas) return;
    final prefs = await SharedPreferences.getInstance();
    final crudo = prefs.getString(_llaveCuentasGuardadas);
    if (crudo != null && crudo.isNotEmpty) {
      final Map<String, dynamic> credenciales = jsonDecode(crudo) as Map<String, dynamic>;
      credenciales.forEach((correo, password) {
        _usuarios[correo] = Usuario(email: correo, password: password as String);
      });
    }
    _cuentasCargadas = true;
  }

  /// Vuelca a SharedPreferences el mapa actual de correo->contraseña.
  /// Se llama automáticamente cada vez que se registra una cuenta nueva.
  Future<void> _guardarCuentas() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> credenciales = {
      for (final entrada in _usuarios.entries) entrada.key: entrada.value.password,
    };
    await prefs.setString(_llaveCuentasGuardadas, jsonEncode(credenciales));
  }

  /// Intenta registrar un nuevo usuario.
  /// Devuelve `null` si todo salió bien, o un [String] con el mensaje de
  /// error a mostrar en la UI si algo falló.
  String? registrar({required String email, required String password}) {
    final correo = email.trim().toLowerCase();

    if (correo.isEmpty || password.isEmpty) {
      return 'Completa todos los campos.';
    }
    if (!_esCorreoValido(correo)) {
      return 'Ingresa un correo electrónico válido.';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (_usuarios.containsKey(correo)) {
      return 'Ese correo ya está registrado. Intenta iniciar sesión.';
    }

    final nuevoUsuario = Usuario(email: correo, password: password);
    _usuarios[correo] = nuevoUsuario;
    usuarioActual = nuevoUsuario;
    // No se espera (no 'await') para no bloquear la UI del formulario;
    // es una escritura pequeña y muy poco probable que falle.
    _guardarCuentas();
    return null; // éxito
  }

  /// Intenta iniciar sesión con un correo y contraseña existentes.
  /// Devuelve `null` si el login fue exitoso, o el mensaje de error.
  String? iniciarSesion({required String email, required String password}) {
    final correo = email.trim().toLowerCase();

    if (correo.isEmpty || password.isEmpty) {
      return 'Completa todos los campos.';
    }

    final usuario = _usuarios[correo];
    if (usuario == null) {
      return 'No existe ninguna cuenta con ese correo.';
    }
    if (usuario.password != password) {
      return 'Contraseña incorrecta.';
    }

    usuarioActual = usuario;
    return null; // éxito
  }

  /// Cierra la sesión activa (no borra al usuario de la "base de datos",
  /// solo limpia quién es el usuario actual).
  void cerrarSesion() {
    usuarioActual = null;
  }

  bool _esCorreoValido(String correo) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    return regex.hasMatch(correo);
  }
}