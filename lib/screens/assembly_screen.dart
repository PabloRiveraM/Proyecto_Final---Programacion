// lib/screens/assembly_screen.dart
// Autor: Marly Ramírez — actualizado para usar AppState compartido
//
// Pantalla de Ensamble Actual:
//   - Lee Lista Enlazada y Pila desde AppState (singleton)
//   - Botón Deshacer: AppState.deshacer() → pop() pila + delete() lista
//   - Botón Agregar: llama a ApiService.fetchData() → elegir pieza → AppState.agregarAlEnsamble()

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../models/api_models/item_model.dart';
import '../models/data_structures/custom_graph.dart';
import '../services/api_services.dart';

class AssemblyScreen extends StatefulWidget {
  const AssemblyScreen({super.key});

  @override
  State<AssemblyScreen> createState() => _AssemblyScreenState();
}

class _AssemblyScreenState extends State<AssemblyScreen> {
  final AppState _estado = AppState();
  final CompatibilityGraph _grafo = CompatibilityGraph();
  bool _cargando = false;
  List<ConflictoCompatibilidad> _conflictos = [];

  @override
  void initState() {
    super.initState();
    _estado.addListener(_actualizar);
  }

  @override
  void dispose() {
    _estado.removeListener(_actualizar);
    super.dispose();
  }

  void _actualizar() => setState(() {});

  // ── Agregar pieza desde la IA ─────────────────────────────────────────────
  Future<void> _agregarPiezaDesdeIA() async {
    setState(() => _cargando = true);
    final piezas = await ApiService.fetchData();
    if (!mounted) return;
    setState(() => _cargando = false);

    if (piezas.isEmpty) {
      _mostrarSnackbar('No se pudo obtener piezas de la IA.', esError: true);
      return;
    }

    final elegida = await _mostrarDialogoEleccion(piezas);
    if (elegida == null) return;

    _estado.agregarAlEnsamble(elegida);
    // Agregar al grafo y verificar compatibilidad (Jose - Grafo)
    _grafo.agregarPieza(elegida);
    final piezasActuales = _estado.ensamble.toList();
    setState(() {
      _conflictos = _grafo.verificarEnsamble(piezasActuales);
    });
    if (_conflictos.isNotEmpty) {
      _mostrarSnackbar(
          '⚠️ Conflicto: ${_conflictos.first.motivo}',
          esError: true,
          duracion: const Duration(seconds: 4));
    } else {
      _mostrarSnackbar('${elegida.nombre} agregada al ensamble.');
    }
  }

  // ── Deshacer última acción ────────────────────────────────────────────────
  void _deshacer() {
    final pieza = _estado.deshacer();
    if (pieza == null) {
      _mostrarSnackbar('No hay acciones para deshacer.', esError: true);
    } else {
      // Re-verificar compatibilidad sin la pieza quitada
      final piezasActuales = _estado.ensamble.toList();
      setState(() {
        _conflictos = _grafo.verificarEnsamble(piezasActuales);
      });
      _mostrarSnackbar('Se quitó: ${pieza.nombre}');
    }
  }

  // ── Diálogo selector de pieza ─────────────────────────────────────────────
  Future<ItemModel?> _mostrarDialogoEleccion(List<ItemModel> piezas) {
    return showModalBottomSheet<ItemModel>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Elige una pieza para agregar',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: piezas.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.divider, height: 1),
              itemBuilder: (ctx, i) {
                final pieza = piezas[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.memory_rounded,
                        color: AppColors.secondary, size: 22),
                  ),
                  title: Text(pieza.nombre,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  subtitle: Text('${pieza.categoria} · ${pieza.watts}W',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  trailing: Text('Q${pieza.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  onTap: () => Navigator.pop(ctx, pieza),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _mostrarSnackbar(String mensaje,
      {bool esError = false,
      Duration duracion = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje,
            style: const TextStyle(color: AppColors.textOnDark)),
        backgroundColor: esError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duracion,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final piezas = _estado.ensamble.toList();
    final hayHistorial = !_estado.historial.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        title: const Text('Ensamble Actual',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Deshacer',
            icon: Icon(Icons.undo_rounded,
                color: AppColors.textOnDark.withValues(alpha: 0.3)),
            onPressed: hayHistorial ? _deshacer : null,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildResumen(piezas.length),
          if (_conflictos.isNotEmpty) _buildAlertaConflictos(),
          Expanded(
            child: piezas.isEmpty
                ? _buildEstadoVacio()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: piezas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildTarjetaPieza(piezas[i], i),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cargando ? null : _agregarPiezaDesdeIA,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        icon: _cargando
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.textOnDark))
            : const Icon(Icons.add_rounded),
        label: Text(_cargando ? 'Consultando IA...' : 'Agregar pieza'),
      ),
    );
  }

  Widget _buildResumen(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _Stat(Icons.memory_rounded, '$count', 'Piezas'),
          const SizedBox(width: 12),
          _Stat(Icons.bolt_rounded, '${_estado.totalWattsEnsamble}W', 'Consumo'),
          const SizedBox(width: 12),
          _Stat(Icons.attach_money_rounded,
              'Q${_estado.totalPrecioEnsamble.toStringAsFixed(0)}', 'Total'),
        ],
      ),
    );
  }

  Widget _buildAlertaConflictos() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text('Conflictos de Compatibilidad',
                  style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ..._conflictos.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${c.motivo}',
                    style: TextStyle(
                        color: AppColors.error.withValues(alpha: 0.9),
                        fontSize: 12)),
              )),
        ],
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.computer_rounded, size: 64, color: AppColors.secondary),
          SizedBox(height: 16),
          Text('Tu ensamble está vacío',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Agrega piezas con la IA o desde el Catálogo',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTarjetaPieza(ItemModel pieza, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pieza.nombre,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text('${pieza.categoria} · ${pieza.watts}W',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text('Q${pieza.precio.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

// ── Widget auxiliar stat chip ─────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String etiqueta;
  const _Stat(this.icon, this.valor, this.etiqueta);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textOnDark, size: 18),
            const SizedBox(height: 4),
            Text(valor,
                style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(etiqueta,
                style: TextStyle(
                    color: AppColors.textOnDark.withValues(alpha: 0.65),
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
