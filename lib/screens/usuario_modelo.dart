/// Modelo de datos de un Usuario registrado en la app.
///
/// NOTA IMPORTANTE: esto es una simulación educativa/demo. La contraseña
/// se guarda en texto plano en memoria (RAM) únicamente para fines de
/// prototipo. En una app real de producción NUNCA se debe guardar así:
/// se debe usar un backend con hash+salt (bcrypt/argon2) o un servicio
/// de autenticación (Firebase Auth, Supabase Auth, etc).
class Usuario {
  final String email;
  final String password;

  // --- Progreso de juego asociado a esta cuenta ---
  double monedas;
  int girosRuleta;
  int girosSlots;
  int girosHigherLower;
  int girosLeon;
  String username;
  String avatar;
  String? ultimoBonusFecha;
  bool modoOscuro;

  Usuario({
    required this.email,
    required this.password,
    this.monedas = 1000,
    this.girosRuleta = 0,
    this.girosSlots = 0,
    this.girosHigherLower = 0,
    this.girosLeon = 0,
    String? username,
    this.avatar = '🎩',
    this.ultimoBonusFecha,
    this.modoOscuro = true,
  }) : username = username ?? email.split('@').first;

  int get girosTotales =>
      girosRuleta + girosSlots + girosHigherLower + girosLeon;
}