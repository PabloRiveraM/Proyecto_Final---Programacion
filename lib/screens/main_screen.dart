import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import 'assembly_screen.dart';
import 'catalog_screen.dart';
import 'wishlist_screen.dart';
import 'search_screen.dart';
import 'analysis_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _estado = AppState();

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

  void _logout() {
    _estado.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
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
