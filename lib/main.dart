// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/assembly_screen.dart';

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
        // === PALETA DE COLORES ORIGINAL DEL PROYECTO ===
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,               // Negro (Formal)
          secondary: Colors.blueGrey.shade700, // Gris azulado
          surface: Colors.white,               // Tarjetas blancas
          error: Colors.red.shade700,          // Para alertas
        ),
        // Estilo de la barra superior
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
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

// ── Menú Principal ────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // === PALETA DE COLORES ORIGINAL DEL PROYECTO ===
  static const Color _bgBase = Colors.white;
  static const Color _bgCard = Color(0xFFF5F5F5);
  static const Color _textPrimary = Colors.black;
  static const Color _textSecondary = Color(0xFF607D8B); // blueGrey

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBase,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildSectionLabel('TU MÓDULO'),
                  const SizedBox(height: 12),
                  _buildModuloMarly(),
                  const SizedBox(height: 28),
                  _buildSectionLabel('MÓDULOS DEL EQUIPO'),
                  const SizedBox(height: 12),
                  _buildComingSoonCard(
                    icon: Icons.grid_view_rounded,
                    titulo: 'Tabla Hash',
                    descripcion: 'Búsqueda rápida de componentes',
                    color: const Color(0xFFFF6D00),
                  ),
                  const SizedBox(height: 10),
                  _buildComingSoonCard(
                    icon: Icons.account_tree_rounded,
                    titulo: 'Árbol / Grafo',
                    descripcion: 'Relaciones de compatibilidad',
                    color: const Color(0xFF00E676),
                  ),
                  const SizedBox(height: 10),
                  _buildComingSoonCard(
                    icon: Icons.sort_rounded,
                    titulo: 'Algoritmos de Ordenamiento',
                    descripcion: 'Ordenar piezas por precio o rendimiento',
                    color: const Color(0xFFFFD600),
                  ),
                  const Spacer(),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.computer_rounded,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 20),
        const Text(
          'Estructuras de Datos',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Simulador de ensamblaje con IA + RAG',
          style: TextStyle(color: _textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildModuloMarly() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => const AssemblyScreen(),
          transitionsBuilder: (_, anim, ctx2, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.link_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestión Lineal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lista Enlazada · Pila (Deshacer)',
                    style: TextStyle(
                        color: Color(0xFFBDBDBD), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _ChipLabel(
                          label: 'Ensamblador', color: Colors.white),
                      const SizedBox(width: 6),
                      _ChipLabel(label: 'IA + RAG', color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey.shade400, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  descripcion,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Próximo',
              style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'Estructuras de Datos • 2026',
        style: TextStyle(
          color: _textSecondary.withValues(alpha: 0.5),
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Widget auxiliar: etiqueta tipo chip ───────────────────────────────────────

class _ChipLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _ChipLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
