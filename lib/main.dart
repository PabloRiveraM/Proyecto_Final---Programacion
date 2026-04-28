import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'screens/list_screen.dart'; // Importa pantalla de lista

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
        title: const Text('Estructuras de Datos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.account_tree_outlined, size: 80, color: Colors.black),
            const SizedBox(height: 20),
            const Text(
              'Seleccione una estructura:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            // BOTÓN PARA TU MÓDULO (Marly)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                // Navegación hacia tu pantalla
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListScreen()),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Lista Enlazada'),
            ),
            
            const SizedBox(height: 10),
            // Aquí agregarás los botones de Tabla Hash, Pilas, etc. después.
          ],
        ),
      ),
    );
  }
}