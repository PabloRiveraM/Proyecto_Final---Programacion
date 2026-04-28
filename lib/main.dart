import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estructuras de Datos',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        // === PALETA DE COLORES DEL PROYECTO ===
        scaffoldBackgroundColor: Colors.white, // Fondo blanco
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,                 // Negro (Formal)
          secondary: Colors.blueGrey.shade700,   // Gris azulado 
          surface: Colors.white,                 // Tarjetas blancas
          error: Colors.red.shade700,            // Para alertas
        ),
        
        // Estilo de la barra superior
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white, // Color del texto de la barra
          elevation: 0,
          centerTitle: true,
        ),
        
        // Estilo de los botones flotantes
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blueGrey.shade700,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// === PANTALLA TEMPORAL DE INICIO ===
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyecto Prog III'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch, size: 80, color: Colors.black),
            const SizedBox(height: 20),
            const Text(
              '¡El proyecto base está listo!\nTema e integraciones iniciales.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.black
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción de prueba
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Botón funcionando! ✅'),
              backgroundColor: Colors.blueGrey.shade800,
            )
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}