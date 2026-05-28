// lib/screens/assembly_screen.dart
// Autor: Equipo Completo (Pablo, Marly, Diego, Jose)
//
// Pantalla de Ensamble Actual:
//   - Lee Lista Enlazada y Pila desde AppState (singleton)
//   - Botón Deshacer: AppState.deshacer()
//   - Resaltado rojo (Jose)
//   - Swipe to delete (Marly)
//   - Auto-armado (Diego)
//   - Exportación Imagen/PDF (Pablo)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../models/api_models/item_model.dart';
import '../models/data_structures/custom_graph.dart';
import '../services/api_services.dart';
import '../utils/pdf_generator.dart';
import 'login_screen.dart';

class AssemblyScreen extends StatefulWidget {
  const AssemblyScreen({super.key});

  @override
  State<AssemblyScreen> createState() => _AssemblyScreenState();
}

class _AssemblyScreenState extends State<AssemblyScreen> {
  final AppState _estado = AppState();
  final CompatibilityGraph _grafo = CompatibilityGraph();
  bool _cargando = false;
  bool _consultandoIA = false;
  bool _consultandoAmazon = false;
  List<ConflictoCompatibilidad> _conflictos = [];
  bool _dialogoMostrado = false;
  final ScreenshotController _screenshotController = ScreenshotController();
  // Precios de Amazon guardados para usar en el PDF
  Map<String, String> _preciosAmazon = {};

  @override
  void initState() {
    super.initState();
    _estado.addListener(_actualizar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_estado.ensamble.isEmpty && !_dialogoMostrado) {
        _dialogoMostrado = true;
        _mostrarDialogoAutoArmado();
      }
    });
  }

  @override
  void dispose() {
    _estado.removeListener(_actualizar);
    super.dispose();
  }

  void _actualizar() => setState(() {});

  // ── Auto-Armado (Diego) ───────────────────────────────────────────────────
  Future<void> _mostrarDialogoAutoArmado() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('¿Para qué usarás tu PC?', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sports_esports_rounded, color: AppColors.primary),
              title: const Text('PC Gamer', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Alto rendimiento para juegos', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () => _autoArmar(ctx, 'gamer'),
            ),
            ListTile(
              leading: const Icon(Icons.work_rounded, color: AppColors.primary),
              title: const Text('PC Oficina', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Tareas básicas y ofimática', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () => _autoArmar(ctx, 'oficina'),
            ),
            ListTile(
              leading: const Icon(Icons.build_rounded, color: AppColors.primary),
              title: const Text('Armar Manualmente', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Elegir pieza por pieza', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autoArmar(BuildContext ctx, String perfil) async {
    Navigator.pop(ctx);
    setState(() => _cargando = true);
    final catalogoCompleto = await ApiService.fetchData();
    
    ItemModel? cpu;
    ItemModel? mb;
    ItemModel? ram;
    ItemModel? psu;
    
    if (perfil == 'gamer') {
      cpu = catalogoCompleto.where((p) => p.nombre.contains('Ryzen 5') || p.nombre.contains('i5-12600')).firstOrNull;
      mb = catalogoCompleto.where((p) => p.categoria == 'Motherboard' && p.precio > 800).firstOrNull;
      ram = catalogoCompleto.where((p) => p.categoria == 'RAM' && p.nombre.contains('16GB')).firstOrNull;
      psu = catalogoCompleto.where((p) => p.categoria == 'Fuente de Poder' && p.watts >= 600).firstOrNull;
    } else if (perfil == 'oficina') {
      cpu = catalogoCompleto.where((p) => p.categoria == 'Procesador' && p.precio < 1000).firstOrNull;
      mb = catalogoCompleto.where((p) => p.categoria == 'Motherboard' && p.precio < 700).firstOrNull;
      ram = catalogoCompleto.where((p) => p.categoria == 'RAM' && p.nombre.contains('8GB')).firstOrNull;
      psu = catalogoCompleto.where((p) => p.categoria == 'Fuente de Poder' && p.watts <= 500).firstOrNull;
    }

    final piezasAuto = [cpu, mb, ram, psu].whereType<ItemModel>().toList();
    
    for (var p in piezasAuto) {
      _grafo.agregarPieza(p);
      _estado.agregarAlEnsamble(p);
    }
    
    setState(() {
      _cargando = false;
      _conflictos = _grafo.verificarEnsamble(_estado.ensamble.toList());
    });
    _mostrarSnackbar('Perfil $perfil cargado automáticamente.');
  }

  // ── Exportación (Pablo) ───────────────────────────────────────────────────
  void _mostrarMenuExportar() {
    if (_estado.ensamble.isEmpty) {
      _mostrarSnackbar('Agrega piezas al ensamble para poder exportar.', esError: true);
      return;
    }
    // Si ya se consultaron precios de Amazon, incluirlos en el PDF automáticamente
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Exportar Ensamble', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded, color: AppColors.primary),
              title: const Text('Compartir como Imagen', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _exportarImagen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
              title: const Text('Exportar como PDF', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                PdfGenerator.exportAndSharePdf(
                  _estado.ensamble.toList(),
                  _estado.totalPrecioEnsamble,
                  _estado.totalWattsEnsamble.toInt(),
                  amazonPrecios: _preciosAmazon,
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _exportarImagen() async {
    setState(() => _cargando = true);
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 100));
      if (image == null) throw Exception('No se pudo capturar la imagen');
      
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/ensamble.png').create();
      await imagePath.writeAsBytes(image);
      
      await Share.shareXFiles([XFile(imagePath.path)], text: '¡Mira mi ensamble de PC!');
    } catch (e) {
      _mostrarSnackbar('Error al exportar: $e', esError: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Consulta Amazon para TODOS los componentes del ensamble de una sola vez
  Future<void> _consultarAmazonGeneral() async {
    if (_estado.ensamble.isEmpty) {
      _mostrarSnackbar('Agrega piezas al ensamble primero.', esError: true);
      return;
    }
    setState(() => _consultandoAmazon = true);

    final piezas = _estado.ensamble.toList();
    final Map<String, List<dynamic>> todosResultados = {};
    final Map<String, String> nuevosPreciosAmazon = {};

    for (final pieza in piezas) {
      final resultados = await ApiService.searchAmazon(pieza.nombre);
      todosResultados[pieza.nombre] = resultados;
      // Guardar el primer precio encontrado para el PDF
      if (resultados.isNotEmpty && resultados.first['precio'] != null) {
        nuevosPreciosAmazon[pieza.nombre] = resultados.first['precio'];
      }
    }

    if (!mounted) return;
    setState(() {
      _consultandoAmazon = false;
      _preciosAmazon = nuevosPreciosAmazon;
    });

    if (todosResultados.values.every((r) => r.isEmpty)) {
      _mostrarSnackbar('No se pudo conectar con el bot de Amazon. Verifica que el servidor Python esté corriendo.', esError: true, duracion: const Duration(seconds: 5));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Row(
          children: [
            Icon(Icons.shopping_cart_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Precios en Amazon', style: TextStyle(color: AppColors.textPrimary, fontSize: 18))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...todosResultados.entries.map((entry) {
                  final resultados = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(entry.key,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (resultados.isEmpty)
                        const Text('Sin resultados', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                      else
                        ...resultados.take(2).map((res) {
                          final precioUSD = res['precio'] ?? '';
                          final precioGTQ = _convertirAQuetzales(precioUSD);
                          final mostrarPrecio = precioUSD != 'No disponible' && precioUSD.isNotEmpty
                              ? '$precioUSD (~ $precioGTQ)'
                              : 'No disponible';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(res['nombre'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(mostrarPrecio, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_browser_rounded, color: AppColors.primary, size: 20),
                              onPressed: () async {
                                final enlace = res['enlace'];
                                if (enlace != null && enlace.toString().isNotEmpty) {
                                  final uri = Uri.parse(enlace);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                }
                              },
                            ),
                          );
                        }),
                      const Divider(color: AppColors.border),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Ensamble en Amazon (Referencia)',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total USD:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text(
                            '\$${_calcularTotalAmazon(nuevosPreciosAmazon).toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total GTQ (Quetzales):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text(
                            'Q${(_calcularTotalAmazon(nuevosPreciosAmazon) * 7.80).toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textOnDark),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('Exportar con estos precios'),
            onPressed: () {
              Navigator.pop(ctx);
              PdfGenerator.exportAndSharePdf(
                _estado.ensamble.toList(),
                _estado.totalPrecioEnsamble,
                _estado.totalWattsEnsamble.toInt(),
                amazonPrecios: _preciosAmazon,
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Funciones Generales ───────────────────────────────────────────────────
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

  void _deshacer() {
    final pieza = _estado.deshacer();
    if (pieza == null) {
      _mostrarSnackbar('No hay acciones para deshacer.', esError: true);
    } else {
      final piezasActuales = _estado.ensamble.toList();
      setState(() {
        _conflictos = _grafo.verificarEnsamble(piezasActuales);
      });
      _mostrarSnackbar('Se quitó: ${pieza.nombre}');
    }
  }

  Future<void> _consultarIA() async {
    if (_estado.ensamble.isEmpty) {
      _mostrarSnackbar('Agrega piezas al ensamble primero.', esError: true);
      return;
    }
    setState(() => _consultandoIA = true);
    final resultado = await ApiService.checkCompatibility(_estado.ensamble.toList());
    if (!mounted) return;
    setState(() => _consultandoIA = false);
    _mostrarResultadosIA(resultado);
  }

  void _mostrarResultadosIA(Map<String, dynamic> res) {
    final idsSugeridos = res['idsSugeridos'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Row(
          children: [
            Icon(res['compatible'] ? Icons.check_circle_rounded : Icons.warning_rounded, 
                 color: res['compatible'] ? AppColors.success : AppColors.error),
            const SizedBox(width: 8),
            const Expanded(child: Text('Análisis IA', style: TextStyle(color: AppColors.textPrimary, fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(res['resumen'] ?? '', style: const TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              if (res['problemas'] != null && (res['problemas'] as List).isNotEmpty) ...[
                const Text('Problemas:', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                ...((res['problemas'] as List).map((p) => Text('• $p', style: const TextStyle(color: AppColors.textSecondary)))),
                const SizedBox(height: 16),
              ],
              if (res['sugerencias'] != null && (res['sugerencias'] as List).isNotEmpty) ...[
                const Text('Sugerencias del Inventario:', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ...((res['sugerencias'] as List).map((s) => Text('• $s', style: const TextStyle(color: AppColors.textSecondary)))),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          if (idsSugeridos.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnDark,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _cargando = true);
                final catalogoCompleto = await ApiService.fetchData();
                for (var id in idsSugeridos) {
                  final idInt = id is int ? id : int.tryParse(id.toString());
                  final pieza = catalogoCompleto.where((p) => p.id == idInt).firstOrNull;
                  if (pieza != null) {
                    _grafo.agregarPieza(pieza);
                    _estado.agregarAlEnsamble(pieza);
                  }
                }
                setState(() {
                  _cargando = false;
                  _conflictos = _grafo.verificarEnsamble(_estado.ensamble.toList());
                });
                _mostrarSnackbar('Sugerencias añadidas al ensamble.');
              },
              child: const Text('Añadir Sugerencias', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Future<ItemModel?> _mostrarDialogoEleccion(List<ItemModel> piezas) {
    String filtroCategoria = 'Todas';
    final categorias = ['Todas', ...piezas.map((p) => p.categoria).toSet().toList()];

    return showModalBottomSheet<ItemModel>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final piezasFiltradas = filtroCategoria == 'Todas'
              ? piezas
              : piezas.where((p) => p.categoria == filtroCategoria).toList();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, controller) => Column(
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
                    child: Text('Elige una pieza',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categorias.length,
                    itemBuilder: (context, i) {
                      final cat = categorias[i];
                      final isSelected = cat == filtroCategoria;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.textOnDark : AppColors.textPrimary)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          onSelected: (selected) {
                            if (selected) setModalState(() => filtroCategoria = cat);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: piezasFiltradas.length,
                    itemBuilder: (context, i) {
                      final p = piezasFiltradas[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surface,
                          child: Icon(Icons.memory_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: Text(p.nombre, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        subtitle: Text('${p.categoria} · ${p.watts}W', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        trailing: Text('Q${p.precio.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        onTap: () => Navigator.pop(ctx, p),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarSnackbar(String mensaje, {bool esError = false, Duration duracion = const Duration(seconds: 2)}) {
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
          // IA y Amazon con su indicador de carga
          if (_consultandoIA || _consultandoAmazon)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.textOnDark, strokeWidth: 2.5)),
            )
          else ...[  
            IconButton(
              tooltip: 'Análisis IA',
              icon: const Icon(Icons.psychology_rounded),
              color: AppColors.textOnDark,
              onPressed: _consultarIA,
            ),
            IconButton(
              tooltip: 'Precios en Amazon',
              icon: const Icon(Icons.shopping_cart_outlined),
              color: AppColors.textOnDark,
              onPressed: _consultarAmazonGeneral,
            ),
          ],
          // Menú secundario con más opciones
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textOnDark),
            color: AppColors.background,
            onSelected: (value) {
              if (value == 'deshacer') _deshacer();
              if (value == 'exportar') _mostrarMenuExportar();
              if (value == 'logout') {
                AppState().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'deshacer',
                enabled: hayHistorial,
                child: Row(
                  children: [
                    Icon(Icons.undo_rounded, color: hayHistorial ? AppColors.textPrimary : AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text('Deshacer', style: TextStyle(color: hayHistorial ? AppColors.textPrimary : AppColors.textSecondary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'exportar',
                child: Row(
                  children: [
                    Icon(Icons.ios_share_rounded, color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 12),
                    Text('Exportar ensamble', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: AppColors.background,
          child: Column(
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
        ),
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

  // ── Tarjeta de Pieza Combinada (Jose y Marly) ─────────────────────────────
  Widget _buildTarjetaPieza(ItemModel pieza, int index) {
    // Resaltado Rojo (Jose)
    final tieneConflicto = _conflictos.any((c) => c.piezaA.id == pieza.id || c.piezaB.id == pieza.id);

    // Swipe to Delete (Marly)
    return Dismissible(
      key: ValueKey('${pieza.id}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _estado.eliminarDelEnsamble(pieza);
        final piezasActuales = _estado.ensamble.toList();
        setState(() {
          _conflictos = _grafo.verificarEnsamble(piezasActuales);
        });
        _mostrarSnackbar('${pieza.nombre} eliminado.');
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: tieneConflicto ? AppColors.error.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tieneConflicto ? AppColors.error : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: tieneConflicto ? AppColors.error : AppColors.primary,
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pieza.nombre,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${pieza.categoria} · ${pieza.watts}W',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _estado.eliminarDelEnsamble(pieza);
                final piezasActuales = _estado.ensamble.toList();
                setState(() {
                  _conflictos = _grafo.verificarEnsamble(piezasActuales);
                });
                _mostrarSnackbar('${pieza.nombre} eliminado.');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _convertirAQuetzales(String? precioUSD) {
    if (precioUSD == null || precioUSD == 'No disponible' || precioUSD.isEmpty) {
      return 'No disponible';
    }
    try {
      final limpio = precioUSD.replaceAll(RegExp(r'[^\d.]'), '');
      final valorUSD = double.parse(limpio);
      final tasaCambio = 7.80;
      final valorGTQ = valorUSD * tasaCambio;
      return 'Q${valorGTQ.toStringAsFixed(2)}';
    } catch (e) {
      return precioUSD;
    }
  }

  double _calcularTotalAmazon(Map<String, String> precios) {
    double total = 0.0;
    for (final precioStr in precios.values) {
      if (precioStr != 'No disponible' && precioStr.isNotEmpty) {
        try {
          final limpio = precioStr.replaceAll(RegExp(r'[^\d.]'), '');
          total += double.parse(limpio);
        } catch (_) {}
      }
    }
    return total;
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
