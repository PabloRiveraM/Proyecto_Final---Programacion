// lib/screens/catalog_screen.dart
// Autor: Diego (Apioide) — feature/diego-catalogo-arbol
//
// Catálogo de piezas organizado con un Árbol Binario de Búsqueda.
// - Carga piezas desde ApiService (IA + RAG)
// - Las inserta en PCComponentTree (ordenadas por categoría)
// - Chips de filtro generados por recorrido inOrder() del árbol
// - Botones para agregar al Ensamble o a la Wishlist

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../models/api_models/item_model.dart';
import '../models/data_structures/custom_tree.dart';
import '../services/api_services.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final PCComponentTree _arbol = PCComponentTree();
  final AppState _estado = AppState();

  bool _cargando = false;
  bool _cargado = false;
  String? _categoriaSeleccionada; // null = mostrar todas

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  // ── Carga piezas de la IA e inserta en el árbol ──────────────────────────
  Future<void> _cargarCatalogo() async {
    if (_cargado) return;
    setState(() => _cargando = true);

    final piezas = await ApiService.fetchData();

    if (!mounted) return;
    for (final pieza in piezas) {
      _arbol.insertar(pieza);
    }

    setState(() {
      _cargando = false;
      _cargado = true;
    });
  }

  // ── Piezas a mostrar según filtro activo ─────────────────────────────────
  List<ItemModel> get _piezasFiltradas {
    if (_categoriaSeleccionada == null) return _arbol.todasLasPiezas();
    return _arbol.buscarPorCategoria(_categoriaSeleccionada!);
  }

  // ── Agregar al ensamble ──────────────────────────────────────────────────
  void _agregarAlEnsamble(ItemModel pieza) {
    _estado.agregarAlEnsamble(pieza);
    _mostrarSnackbar('${pieza.nombre} agregada al ensamble');
  }

  // ── Agregar a Wishlist ───────────────────────────────────────────────────
  void _agregarAWishlist(ItemModel pieza) {
    _estado.agregarAWishlist(pieza);
    _mostrarSnackbar('${pieza.nombre} guardada en Wishlist');
  }

  void _mostrarSnackbar(String msg, {bool esError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: AppColors.textOnDark)),
        backgroundColor: esError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        title: const Text('Catálogo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Recargar catálogo',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargando
                ? null
                : () {
                    setState(() => _cargado = false);
                    _cargarCatalogo();
                  },
          ),
        ],
      ),
      body: _cargando
          ? _buildCargando()
          : _arbol.isEmpty
              ? _buildVacio()
              : Column(
                  children: [
                    _buildFiltros(),
                    _buildContadorArbol(),
                    Expanded(child: _buildGridPiezas()),
                  ],
                ),
    );
  }

  // ── Widget: Cargando ─────────────────────────────────────────────────────
  Widget _buildCargando() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Cargando catálogo desde la IA...',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Widget: Vacío ────────────────────────────────────────────────────────
  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.grid_view_rounded,
                size: 36, color: AppColors.secondary),
          ),
          const SizedBox(height: 16),
          const Text('Sin piezas en el catálogo',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Toca recargar para obtener el catálogo',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Widget: Chips de filtro (generados por inOrder del árbol) ────────────
  Widget _buildFiltros() {
    final categorias = ['Todas', ..._arbol.categorias()];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categorias[i];
          final seleccionada =
              (i == 0 && _categoriaSeleccionada == null) ||
              cat == _categoriaSeleccionada;
          return GestureDetector(
            onTap: () => setState(() =>
                _categoriaSeleccionada = i == 0 ? null : cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: seleccionada
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: seleccionada
                        ? AppColors.primary
                        : AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  color: seleccionada
                      ? AppColors.textOnDark
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Widget: Info del árbol ───────────────────────────────────────────────
  Widget _buildContadorArbol() {
    final nodos = _arbol.inOrder();
    final totalPiezas = _arbol.todasLasPiezas().length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.account_tree_rounded,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            'Árbol: ${nodos.length} categorías · $totalPiezas piezas',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Widget: Grid de piezas ───────────────────────────────────────────────
  Widget _buildGridPiezas() {
    final piezas = _piezasFiltradas;
    if (piezas.isEmpty) {
      return const Center(
        child: Text('No hay piezas en esta categoría',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: piezas.length,
      itemBuilder: (_, i) => _buildTarjetaPieza(piezas[i]),
    );
  }

  // ── Widget: Tarjeta de pieza ─────────────────────────────────────────────
  Widget _buildTarjetaPieza(ItemModel pieza) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono + categoría
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconoCategoria(pieza.categoria),
                    color: AppColors.textOnDark, size: 28),
                const SizedBox(height: 8),
                Text(
                  pieza.categoria,
                  style: TextStyle(
                    color: AppColors.textOnDark.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pieza.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${pieza.watts}W',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  'Q${pieza.precio.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Botones
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: _BotonAccion(
                    icono: Icons.build_rounded,
                    tooltip: 'Agregar al ensamble',
                    onTap: () => _agregarAlEnsamble(pieza),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _BotonAccion(
                    icono: Icons.favorite_rounded,
                    tooltip: 'Agregar a Wishlist',
                    onTap: () => _agregarAWishlist(pieza),
                    secundario: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconoCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'procesador':
        return Icons.memory_rounded;
      case 'tarjeta grafica':
        return Icons.videogame_asset_rounded;
      case 'motherboard':
        return Icons.developer_board_rounded;
      case 'ram':
        return Icons.storage_rounded;
      case 'fuente de poder':
        return Icons.bolt_rounded;
      case 'almacenamiento':
        return Icons.save_rounded;
      default:
        return Icons.devices_rounded;
    }
  }
}

// ── Widget auxiliar: botón de acción ─────────────────────────────────────────
class _BotonAccion extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;
  final bool secundario;

  const _BotonAccion({
    required this.icono,
    required this.tooltip,
    required this.onTap,
    this.secundario = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                secundario ? AppColors.surface : AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: secundario
                    ? AppColors.border
                    : AppColors.primary),
          ),
          child: Icon(
            icono,
            size: 18,
            color: secundario
                ? AppColors.secondary
                : AppColors.textOnDark,
          ),
        ),
      ),
    );
  }
}
