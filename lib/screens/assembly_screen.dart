// lib/screens/assembly_screen.dart
// Módulo de Marly – Gestión Lineal: Lista Enlazada + Pila (Deshacer)

import 'package:flutter/material.dart';
import '../models/data_structures/custom_list.dart';
import '../models/data_structures/custom_stack.dart';
import '../models/api_models/item_model.dart';
import '../services/api_services.dart';

class AssemblyScreen extends StatefulWidget {
  const AssemblyScreen({super.key});

  @override
  State<AssemblyScreen> createState() => _AssemblyScreenState();
}

class _AssemblyScreenState extends State<AssemblyScreen>
    with TickerProviderStateMixin {
  // ── Estructuras de datos ──────────────────────────────────────────────────
  final CustomLinkedList<ItemModel> _ensamble = CustomLinkedList<ItemModel>();
  final CustomStack<ItemModel> _historial = CustomStack<ItemModel>();

  // ── Estado de la UI ───────────────────────────────────────────────────────
  List<ItemModel> _catalogo = [];
  bool _cargandoCatalogo = true;
  bool _verificando = false;
  String _categoriaSeleccionada = 'Todos';
  String? _errorCatalogo;

  // ── Animaciones ───────────────────────────────────────────────────────────
  late AnimationController _pulseController;

  // ── Paleta de colores ─────────────────────────────────────────────────────
  static const Color _bgBase = Color(0xFF0D0D1A);
  static const Color _bgCard = Color(0xFF1A1A2E);
  static const Color _bgCardAlt = Color(0xFF16213E);
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _purple = Color(0xFF7C4DFF);
  static const Color _green = Color(0xFF00E676);
  static const Color _red = Color(0xFFFF1744);
  static const Color _textPrimary = Color(0xFFE0E0E0);
  static const Color _textSecondary = Color(0xFF9E9E9E);

  // ── Categorías ────────────────────────────────────────────────────────────
  static const List<String> _categorias = [
    'Todos',
    'Procesador',
    'Tarjeta Grafica',
    'Motherboard',
    'RAM',
    'Almacenamiento',
    'Fuente de Poder',
  ];

  static const Map<String, IconData> _icono = {
    'Procesador': Icons.memory,
    'Tarjeta Grafica': Icons.videogame_asset,
    'Motherboard': Icons.developer_board,
    'RAM': Icons.storage,
    'Almacenamiento': Icons.save,
    'Fuente de Poder': Icons.bolt,
  };

  static const Map<String, Color> _colorCategoria = {
    'Procesador': Color(0xFF00E5FF),
    'Tarjeta Grafica': Color(0xFF7C4DFF),
    'Motherboard': Color(0xFFFF6D00),
    'RAM': Color(0xFF00E676),
    'Almacenamiento': Color(0xFFFFD600),
    'Fuente de Poder': Color(0xFFFF1744),
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

  Future<void> _cargarCatalogo() async {
    setState(() {
      _cargandoCatalogo = true;
      _errorCatalogo = null;
    });
    try {
      final piezas = await ApiService.fetchData();
      setState(() {
        _catalogo = piezas;
        _cargandoCatalogo = false;
      });
    } catch (e) {
      setState(() {
        _errorCatalogo = 'No se pudo cargar el catálogo. Verifica tu conexión.';
        _cargandoCatalogo = false;
      });
    }
  }

  void _agregarPieza(ItemModel pieza) {
    setState(() {
      _ensamble.insert(pieza); // Lista Enlazada
      _historial.push(pieza); // Pila (historial)
    });
    _mostrarSnackbar('✅  ${pieza.nombre} agregada al ensamble', _green);
  }

  void _deshacerUltima() {
    if (_historial.isEmpty) return;
    setState(() {
      _historial.pop(); // Saca de la pila
      _ensamble.removeLast(); // Elimina último nodo de la lista
    });
    _mostrarSnackbar('↩  Última pieza eliminada del ensamble', _cyan);
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje,
            style:
                const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int get _wattsTotal =>
      _ensamble.toList().fold(0, (sum, p) => sum + p.watts);

  double get _precioTotal =>
      _ensamble.toList().fold(0.0, (sum, p) => sum + p.precio);

  List<ItemModel> get _catalogoFiltrado => _categoriaSeleccionada == 'Todos'
      ? _catalogo
      : _catalogo.where((p) => p.categoria == _categoriaSeleccionada).toList();

  // ── Verificar compatibilidad ──────────────────────────────────────────────

  Future<void> _verificarCompatibilidad() async {
    final piezas = _ensamble.toList();
    if (piezas.isEmpty) {
      _mostrarSnackbar('⚠  Agrega piezas antes de verificar', _red);
      return;
    }
    setState(() => _verificando = true);
    try {
      final resultado = await ApiService.checkCompatibility(piezas);
      if (mounted) {
        setState(() => _verificando = false);
        _mostrarResultado(resultado);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _verificando = false);
        _mostrarSnackbar('Error al verificar compatibilidad', _red);
      }
    }
  }

  void _mostrarResultado(Map<String, dynamic> resultado) {
    final bool compatible = resultado['compatible'] ?? false;
    final int wattsTotal = resultado['wattsTotal'] ?? 0;
    final int wattsFuente = resultado['wattsFuente'] ?? 0;
    final double precio = (resultado['precioTotal'] ?? 0).toDouble();
    final List problemas = resultado['problemas'] ?? [];
    final List sugerencias = resultado['sugerencias'] ?? [];
    final String resumen = resultado['resumen'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx2, controller) => Container(
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: compatible
                  ? _green.withValues(alpha: 0.4)
                  : _red.withValues(alpha: 0.4),
            ),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    compatible ? Icons.check_circle : Icons.cancel,
                    color: compatible ? _green : _red,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    compatible
                        ? 'Ensamble Compatible'
                        : 'Ensamble Incompatible',
                    style: TextStyle(
                      color: compatible ? _green : _red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bgBase,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(resumen,
                    style:
                        const TextStyle(color: _textPrimary, fontSize: 14)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statCard(
                      'Consumo', '$wattsTotal W', Icons.bolt, _cyan),
                  const SizedBox(width: 10),
                  _statCard(
                      'Fuente', '$wattsFuente W', Icons.power, _purple),
                  const SizedBox(width: 10),
                  _statCard('Precio',
                      'Q${precio.toStringAsFixed(2)}', Icons.attach_money, _green),
                ],
              ),
              if (problemas.isNotEmpty) ...[
                const SizedBox(height: 16),
                _seccionResultado(
                    '⚠  Problemas encontrados', problemas, _red),
              ],
              if (sugerencias.isNotEmpty) ...[
                const SizedBox(height: 12),
                _seccionResultado('💡  Sugerencias', sugerencias, _cyan),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
      String label, String valor, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(label,
                style:
                    const TextStyle(color: _textSecondary, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _seccionResultado(
      String titulo, List<dynamic> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, color: color, size: 8),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.toString(),
                      style: const TextStyle(
                          color: _textPrimary, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final piezasEnsamble = _ensamble.toList();

    return Scaffold(
      backgroundColor: _bgBase,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTotalesBar(piezasEnsamble),
          _buildFiltrosCategorias(),
          Expanded(
            child: _cargandoCatalogo
                ? _buildCargando()
                : _errorCatalogo != null
                    ? _buildError()
                    : _buildContenido(piezasEnsamble),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bgCard,
      foregroundColor: _textPrimary,
      elevation: 0,
      title: const Text(
        '🖥  Ensamblador de PC',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        // Botón Deshacer (Pila)
        AnimatedOpacity(
          opacity: _historial.isEmpty ? 0.3 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Deshacer última pieza',
            onPressed: _historial.isEmpty ? null : _deshacerUltima,
          ),
        ),
        // Botón Verificar compatibilidad
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _verificando
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: _cyan, strokeWidth: 2),
                  ),
                )
              : TextButton.icon(
                  onPressed: _verificarCompatibilidad,
                  icon: const Icon(Icons.verified_outlined,
                      color: _cyan, size: 18),
                  label: const Text('Verificar',
                      style: TextStyle(color: _cyan, fontSize: 13)),
                ),
        ),
      ],
    );
  }

  Widget _buildTotalesBar(List<ItemModel> piezas) {
    return Container(
      color: _bgCardAlt,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.build_circle_outlined,
              color: _purple, size: 16),
          const SizedBox(width: 6),
          Text(
            '${piezas.length} pieza${piezas.length == 1 ? '' : 's'}',
            style:
                const TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const Spacer(),
          const Icon(Icons.bolt, color: _cyan, size: 16),
          const SizedBox(width: 4),
          Text('$_wattsTotal W',
              style: const TextStyle(
                  color: _cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(width: 16),
          const Icon(Icons.attach_money, color: _green, size: 16),
          Text('Q${_precioTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFiltrosCategorias() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _categorias.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categorias[i];
          final activo = cat == _categoriaSeleccionada;
          final color = cat == 'Todos'
              ? _purple
              : _colorCategoria[cat] ?? _cyan;
          return GestureDetector(
            onTap: () =>
                setState(() => _categoriaSeleccionada = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: activo
                    ? color.withValues(alpha: 0.2)
                    : _bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activo
                      ? color
                      : _textSecondary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: activo ? color : _textSecondary,
                  fontWeight: activo
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCargando() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) => Opacity(
              opacity: 0.5 + _pulseController.value * 0.5,
              child: child,
            ),
            child: const Icon(Icons.memory, color: _cyan, size: 64),
          ),
          const SizedBox(height: 20),
          const Text('Cargando catálogo desde la IA...',
              style:
                  TextStyle(color: _textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
                color: _cyan, backgroundColor: _bgCard),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: _red, size: 60),
          const SizedBox(height: 16),
          Text(_errorCatalogo!,
              style:
                  const TextStyle(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: Colors.black),
            onPressed: _cargarCatalogo,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido(List<ItemModel> piezasEnsamble) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel izquierdo: Catálogo
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Text(
                  'Catálogo (${_catalogoFiltrado.length})',
                  style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      letterSpacing: 1),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: _catalogoFiltrado.length,
                  itemBuilder: (_, i) =>
                      _buildPiezaCatalogo(_catalogoFiltrado[i]),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(
            width: 1,
            color: _textSecondary.withValues(alpha: 0.15)),
        // Panel derecho: Mi Ensamble (Lista Enlazada visual)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.link,
                        color: _purple, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Ensamble (${piezasEnsamble.length})',
                      style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: piezasEnsamble.isEmpty
                    ? _buildEnsambleVacio()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8),
                        itemCount: piezasEnsamble.length,
                        itemBuilder: (_, i) => _buildNodoEnsamble(
                            piezasEnsamble[i], i),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPiezaCatalogo(ItemModel pieza) {
    final color = _colorCategoria[pieza.categoria] ?? _cyan;
    final icon = _icono[pieza.categoria] ?? Icons.device_unknown;
    final yaAgregada =
        _ensamble.toList().any((p) => p.id == pieza.id);

    return GestureDetector(
      onTap: yaAgregada ? null : () => _agregarPieza(pieza),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: yaAgregada
              ? color.withValues(alpha: 0.05)
              : _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: yaAgregada
                ? color.withValues(alpha: 0.5)
                : _textSecondary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pieza.nombre,
                    style: TextStyle(
                      color: yaAgregada
                          ? _textSecondary
                          : _textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${pieza.watts}W · Q${pieza.precio.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: _textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (yaAgregada)
              const Icon(Icons.check_circle, color: _green, size: 18)
            else
              Icon(Icons.add_circle_outline,
                  color: color.withValues(alpha: 0.7), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildNodoEnsamble(ItemModel pieza, int index) {
    final color = _colorCategoria[pieza.categoria] ?? _cyan;
    final icon = _icono[pieza.categoria] ?? Icons.device_unknown;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _bgCardAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pieza.nombre,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${pieza.watts}W · Q${pieza.precio.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Flecha visual de lista enlazada entre nodos
        if (index < _ensamble.size - 1)
          Icon(Icons.keyboard_arrow_down,
              color: _purple.withValues(alpha: 0.5), size: 18),
      ],
    );
  }

  Widget _buildEnsambleVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) => Opacity(
              opacity: 0.2 + _pulseController.value * 0.3,
              child: child,
            ),
            child: const Icon(Icons.add_link,
                color: _purple, size: 48),
          ),
          const SizedBox(height: 12),
          const Text('Sin piezas',
              style: TextStyle(color: _textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          const Text(
            'Toca una pieza del\ncatálogo para agregar',
            style: TextStyle(color: _textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
