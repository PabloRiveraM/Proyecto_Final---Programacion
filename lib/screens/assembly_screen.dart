// lib/screens/assembly_screen.dart
// Autor: Marly Ramírez — feature/marly-navegacion
// Pantalla de Ensamble Actual:
//   - Lista Enlazada (CustomLinkedList) para mostrar las piezas seleccionadas
//   - Pila (CustomStack) como historial para la operación Deshacer
//   - Botón Deshacer: pop() en pila + delete() en lista enlazada
//   - Botón Agregar: llama a ApiService.fetchData() para obtener piezas vía IA + RAG

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/api_models/item_model.dart';
import '../models/data_structures/custom_list.dart';
import '../models/data_structures/custom_stack.dart';
import '../services/api_services.dart';

class AssemblyScreen extends StatefulWidget {
  const AssemblyScreen({super.key});

  @override
  State<AssemblyScreen> createState() => _AssemblyScreenState();
}

class _AssemblyScreenState extends State<AssemblyScreen> {
  // === ESTRUCTURAS DE DATOS ===
  final CustomLinkedList<ItemModel> _listaEnsamble = CustomLinkedList();
  final CustomStack<ItemModel> _pilaHistorial = CustomStack();

  bool _cargando = false;

  // === TOTALES ===
  double get _totalPrecio =>
      _listaEnsamble.toList().fold(0.0, (sum, p) => sum + p.precio);
  int get _totalWatts =>
      _listaEnsamble.toList().fold(0, (sum, p) => sum + p.watts);

  // ── Agregar pieza desde la IA (RAG) ──────────────────────────────────────
  Future<void> _agregarPiezaDesdeIA() async {
    setState(() => _cargando = true);

    final List<ItemModel> piezas = await ApiService.fetchData();

    if (!mounted) return;
    setState(() => _cargando = false);

    if (piezas.isEmpty) {
      _mostrarSnackbar('No se pudo obtener piezas de la IA.', esError: true);
      return;
    }

    // Mostramos un diálogo para que el usuario elija cuál agregar
    final ItemModel? elegida = await _mostrarDialogoEleccion(piezas);
    if (elegida == null) return;

    setState(() {
      _listaEnsamble.insert(elegida);    // Insertar en lista enlazada
      _pilaHistorial.push(elegida);      // Guardar en pila para deshacer
    });

    _mostrarSnackbar('${elegida.nombre} agregada al ensamble.');
  }

  // ── Deshacer última pieza agregada ───────────────────────────────────────
  void _deshacer() {
    if (_pilaHistorial.isEmpty) {
      _mostrarSnackbar('No hay acciones para deshacer.', esError: true);
      return;
    }

    final ItemModel? pieza = _pilaHistorial.pop();
    if (pieza == null) return;

    setState(() {
      _listaEnsamble.delete(pieza);
    });

    _mostrarSnackbar('Se quitó: ${pieza.nombre}');
  }

  // ── Diálogo de elección de pieza ─────────────────────────────────────────
  Future<ItemModel?> _mostrarDialogoEleccion(List<ItemModel> piezas) {
    return showModalBottomSheet<ItemModel>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Elige una pieza para agregar',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.memory_rounded,
                          color: AppColors.secondary, size: 22),
                    ),
                    title: Text(
                      pieza.nombre,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${pieza.categoria} · ${pieza.watts}W',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: Text(
                      'Q${pieza.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, pieza),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  // ── SnackBar ─────────────────────────────────────────────────────────────
  void _mostrarSnackbar(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje,
            style: const TextStyle(color: AppColors.textOnDark)),
        backgroundColor:
            esError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final piezas = _listaEnsamble.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ensamble Actual',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Botón Deshacer en la AppBar
          IconButton(
            tooltip: 'Deshacer',
            icon: Icon(
              Icons.undo_rounded,
              color: _pilaHistorial.isEmpty
                  ? AppColors.textOnDark.withValues(alpha: 0.3)
                  : AppColors.textOnDark,
            ),
            onPressed: _pilaHistorial.isEmpty ? null : _deshacer,
          ),
        ],
      ),
      body: Column(
        children: [
          // === RESUMEN SUPERIOR ===
          _buildResumen(piezas.length),

          // === LISTA DE PIEZAS ===
          Expanded(
            child: piezas.isEmpty
                ? _buildEstadoVacio()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: piezas.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildTarjetaPieza(piezas[i], i),
                  ),
          ),
        ],
      ),

      // === BOTÓN AGREGAR ===
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cargando ? null : _agregarPiezaDesdeIA,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        icon: _cargando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnDark,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: Text(_cargando ? 'Consultando IA...' : 'Agregar pieza'),
      ),
    );
  }

  // ── Widget: Resumen ───────────────────────────────────────────────────────
  Widget _buildResumen(int cantidadPiezas) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStatChip(
            Icons.memory_rounded,
            '$cantidadPiezas',
            'Piezas',
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            Icons.bolt_rounded,
            '$_totalWatts W',
            'Consumo',
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            Icons.attach_money_rounded,
            'Q${_totalPrecio.toStringAsFixed(0)}',
            'Total',
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String valor, String etiqueta) {
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
            Text(
              valor,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              etiqueta,
              style: TextStyle(
                color: AppColors.textOnDark.withValues(alpha: 0.65),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget: Estado vacío ──────────────────────────────────────────────────
  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.computer_rounded,
                size: 40, color: AppColors.secondary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tu ensamble está vacío',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca "Agregar pieza" para empezar\ncon ayuda de la Inteligencia Artificial',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Widget: Tarjeta de pieza ──────────────────────────────────────────────
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
          // Número de posición en la lista enlazada
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info de la pieza
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pieza.nombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pieza.categoria} · ${pieza.watts}W',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // Precio
          Text(
            'Q${pieza.precio.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
