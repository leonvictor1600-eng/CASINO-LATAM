import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/base_datos_memoria.dart';

void main() async {
  // Necesario porque vamos a usar 'await' antes de runApp (para leer
  // SharedPreferences), y eso requiere que el binding de Flutter ya
  // esté inicializado.
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las cuentas (correo + contraseña) creadas en sesiones
  // anteriores, para que AuthScreen ya pueda reconocerlas.
  await BaseDatosMemoria.instancia.cargarCuentasGuardadas();

  runApp(const CasinoApp());
}

class CasinoApp extends StatelessWidget {
  const CasinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casino LATAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: Colors.amber,
              secondary: Colors.redAccent,
            ),
      ),
      // La app siempre arranca pidiendo login/registro.
      home: const AuthScreen(),
    );
  }
}