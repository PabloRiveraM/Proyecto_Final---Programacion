// lib/screens/search_screen.dart
// Autor: Jose (8jose-gt) — feature/jose-busqueda-hash
//
// Búsqueda de piezas usando Tabla Hash (CustomHashTable):
//   - Búsqueda por ID: O(1) — búsqueda instantánea usando hash
//   - Búsqueda por nombre: O(n) — con indicador de tipo
//   - Al seleccionar una pieza, puede agregarse al ensamble o a la wishlist
//   - Muestra información educativa sobre la tabla hash (índice, colisiones)

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../models/api_models/item_model.dart';
import '../models/data_structures/custom_hash_table.dart';
import '../services/api_services.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final AppState _estado = AppState();
  final CustomHashTable _tabla = CustomHashTable();
  final TextEditingController _ctrl = TextEditingController();

  bool _cargando = false;
  bool _inicializado = false;
  List<ItemModel> _resultados = [];
  String? _mensajeBusqueda;
  bool _busquedaPorId = false;

  @override
  void initState() {
    super.initState();
    _inicializarTabla();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Carga el catálogo de la IA e inserta en la tabla hash
  Future<void> _inicializarTabla() async {
    if (_inicializado) return;
    setState(() => _cargando = true);

    final piezas = await ApiService.fetchData();
    if (!mounted) return;

    _tabla.insertarTodas(piezas);
    setState(() {
      _cargando = false;
      _inicializado = true;
    });
  }

  // Búsqueda principal
  void _buscar(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _resultados = [];
        _mensajeBusqueda = null;
      });
      return;
    }

    // Si es un número → buscar por ID (O(1))
    final comoNum = int.tryParse(query.trim());
    if (comoNum != null) {
      _busquedaPorId = true;
      final encontrado = _tabla.buscarPorId(comoNum);
      setState(() {
        _resultados = encontrado != null ? [encontrado] : [];
        _mensajeBusqueda = encontrado != null
            ? 'Encontrado en índice hash ${comoNum % CustomHashTable.tableSize} — O(1)'
            : 'ID #$comoNum no encontrado en la tabla';
      });
    } else {
      // Buscar por nombre (O(n))
      _busquedaPorId = false;
      final res = _tabla.buscarPorNombre(query.trim());
      setState(() {
        _resultados = res;
        _mensajeBusqueda = res.isEmpty
            ? 'Sin resultados para "$query"'
            : '${res.length} resultado(s) — búsqueda O(n) por nombre';
      });
    }
  }

  void _agregarAlEnsamble(ItemModel pieza) {
    _estado.agregarAlEnsamble(pieza);
    _snack('${pieza.nombre} agregada al ensamble');
  }

  void _agregarAWishlist(ItemModel pieza) {
    _estado.agregarAWishlist(pieza);
    _snack('${pieza.nombre} guardada en Wishlist');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: AppColors.textOnDark)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _tabla.infoColisiones();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        title: const Text('Búsqueda',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _cargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Inicializando tabla hash...',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            )
          : Column(
              children: [
                _buildInfoTabla(info),
                _buildBarraBusqueda(),
                if (_mensajeBusqueda != null) _buildMensaje(),
                Expanded(child: _buildResultados()),
              ],
            ),
    );
  }

  Widget _buildInfoTabla(Map<String, int> info) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _InfoChip('${_tabla.size}', 'Piezas'),
          _InfoChip('${CustomHashTable.tableSize}', 'Cubetas'),
          _InfoChip('${info['cubetasUsadas']}', 'Usadas'),
          _InfoChip('${info['totalColisiones']}', 'Colisiones'),
        ],
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _ctrl,
        onChanged: _buscar,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o por ID (número)...',
          hintStyle: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.secondary),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () {
                    _ctrl.clear();
                    _buscar('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildMensaje() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(
            _busquedaPorId ? Icons.flash_on_rounded : Icons.search_rounded,
            size: 14,
            color: _resultados.isEmpty
                ? AppColors.error
                : AppColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _mensajeBusqueda!,
              style: TextStyle(
                color: _resultados.isEmpty
                    ? AppColors.error
                    : AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultados() {
    if (_ctrl.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.grid_3x3_rounded,
                  size: 36, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            const Text('Tabla Hash lista',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Escribe un ID para búsqueda O(1)\no un nombre para búsqueda O(n)',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    if (_resultados.isEmpty) {
      return const Center(
        child: Text('Sin resultados',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _resultados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildTarjetaResultado(_resultados[i]),
    );
  }

  Widget _buildTarjetaResultado(ItemModel pieza) {
    final indiceHash = pieza.id % CustomHashTable.tableSize;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('ID ${pieza.id} → cubeta[$indiceHash]',
                    style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text('Q${pieza.precio.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(pieza.nombre,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          Text('${pieza.categoria} · ${pieza.watts}W',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _agregarAlEnsamble(pieza),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_rounded,
                            color: AppColors.textOnDark, size: 16),
                        SizedBox(width: 6),
                        Text('Ensamble',
                            style: TextStyle(
                                color: AppColors.textOnDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _agregarAWishlist(pieza),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_rounded,
                            color: AppColors.secondary, size: 16),
                        SizedBox(width: 6),
                        Text('Wishlist',
                            style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Widget: chip info de la tabla ─────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String valor;
  final String etiqueta;
  const _InfoChip(this.valor, this.etiqueta);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor,
            style: const TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(etiqueta,
            style: TextStyle(
                color: AppColors.textOnDark.withValues(alpha: 0.65),
                fontSize: 10)),
      ],
    );
  }
}
