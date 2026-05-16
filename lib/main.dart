// lib/main.dart
// Autor: Marly Ramírez — feature/marly-navegacion
// Menú principal con navegación BottomNavigationBar de 5 módulos.

import 'package:flutter/material.dart';
import 'core/app_colors.dart';
import 'screens/assembly_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/search_screen.dart';
import 'screens/analysis_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Builder — Estructuras de Datos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnDark,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textOnDark,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ── Navegación Principal ──────────────────────────────────────────────────────

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Las 5 pantallas del proyecto
  final List<Widget> _screens = const [
    AssemblyScreen(),   // Marly   — Lista Enlazada + Pila
    CatalogScreen(),    // Diego   — Árbol jerárquico
    WishlistScreen(),   // Diego   — Cola (Queue)
    SearchScreen(),     // Jose    — Tabla Hash
    AnalysisScreen(),   // Diego   — Gráficas fl_chart
  ];

  // Datos de cada pestaña
  static const List<_TabItem> _tabs = [
    _TabItem(
      icon: Icons.build_rounded,
      iconActive: Icons.build,
      label: 'Ensamble',
    ),
    _TabItem(
      icon: Icons.grid_view_outlined,
      iconActive: Icons.grid_view_rounded,
      label: 'Catálogo',
    ),
    _TabItem(
      icon: Icons.favorite_outline_rounded,
      iconActive: Icons.favorite_rounded,
      label: 'Wishlist',
    ),
    _TabItem(
      icon: Icons.search_rounded,
      iconActive: Icons.search_rounded,
      label: 'Búsqueda',
    ),
    _TabItem(
      icon: Icons.bar_chart_outlined,
      iconActive: Icons.bar_chart_rounded,
      label: 'Análisis',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cuerpo: pantalla activa sin re-crear el árbol de widgets
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // Barra de navegación inferior
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: List.generate(
            _tabs.length,
            (i) => BottomNavigationBarItem(
              icon: Icon(
                i == _currentIndex
                    ? _tabs[i].iconActive
                    : _tabs[i].icon,
                size: 24,
              ),
              label: _tabs[i].label,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Modelo auxiliar para los tabs ─────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final IconData iconActive;
  final String label;

  const _TabItem({
    required this.icon,
    required this.iconActive,
    required this.label,
  });
}
