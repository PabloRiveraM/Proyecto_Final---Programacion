// lib/screens/analysis_screen.dart
// Autor: Diego (Apioide) — feature/diego-wishlist-analisis
//
// Pantalla de Análisis de Consumo:
//   - Gráfica de barras (fl_chart) con consumo (Watts) por categoría
//   - Resumen: pieza de mayor consumo, categoría con más watts

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../models/api_models/item_model.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final AppState _estado = AppState();

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

  // ── Datos para la gráfica (Watts por categoría) ──────────────────────────
  Map<String, double> get _wattsPorCategoria {
    final piezas = _estado.ensamble.toList();
    final Map<String, double> mapa = {};
    for (final p in piezas) {
      mapa[p.categoria] = (mapa[p.categoria] ?? 0) + p.watts;
    }
    return mapa;
  }

  List<ItemModel> get _piezas => _estado.ensamble.toList();

  ItemModel? get _piezaMayorConsumo {
    if (_piezas.isEmpty) return null;
    return _piezas.reduce((a, b) => a.watts > b.watts ? a : b);
  }

  String get _categoriaMayorConsumo {
    final datos = _wattsPorCategoria;
    if (datos.isEmpty) return '—';
    return datos.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Colores alternos para las barras (usando la paleta oficial)
  static const List<Color> _barColors = [
    AppColors.primary,
    AppColors.secondary,
    Color(0xFF78909C), // blueGrey shade400
    Color(0xFF455A64), // blueGrey shade700
    Color(0xFF263238), // blueGrey shade900
    Color(0xFF90A4AE), // blueGrey shade300
  ];

  @override
  Widget build(BuildContext context) {
    final piezas = _piezas;
    final datos = _wattsPorCategoria;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        title: const Text('Análisis de Consumo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: piezas.isEmpty
          ? _buildVacio()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalCard(),
                  const SizedBox(height: 20),
                  _buildGrafica(datos),
                  const SizedBox(height: 20),
                  _buildResumen(datos),
                  const SizedBox(height: 20),
                  _buildDetallePiezas(piezas),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ── Widget: Vacío ────────────────────────────────────────────────────────
  Widget _buildVacio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.secondary),
          SizedBox(height: 16),
          Text('Sin datos para analizar',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Agrega piezas al ensamble primero',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Widget: Total general ────────────────────────────────────────────────
  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consumo total del ensamble',
              style: TextStyle(
                  color: AppColors.textOnDark.withValues(alpha: 0.7),
                  fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '${_estado.totalWattsEnsamble} W',
            style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${_piezas.length} piezas en el ensamble',
            style: TextStyle(
                color: AppColors.textOnDark.withValues(alpha: 0.65),
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Widget: Gráfica de barras (fl_chart) ─────────────────────────────────
  Widget _buildGrafica(Map<String, double> datos) {
    if (datos.isEmpty) return const SizedBox.shrink();

    final categorias = datos.keys.toList();
    final maxValor = datos.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Consumo por categoría (W)',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Watts consumidos por cada tipo de componente',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValor * 1.25,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.primary,
                  getTooltipItem: (group, gI, rod, rI) => BarTooltipItem(
                    '${rod.toY.toStringAsFixed(0)}W',
                    const TextStyle(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (val, meta) => Text(
                      '${val.toInt()}W',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 9),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= categorias.length) {
                        return const SizedBox.shrink();
                      }
                      final cat = categorias[idx];
                      final corto = cat.length > 7
                          ? '${cat.substring(0, 7)}.'
                          : cat;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(corto,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9)),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(categorias.length, (i) {
                final color = _barColors[i % _barColors.length];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: datos[categorias[i]] ?? 0,
                      color: color,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // ── Widget: Resumen estadístico ──────────────────────────────────────────
  Widget _buildResumen(Map<String, double> datos) {
    final pieza = _piezaMayorConsumo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumen',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _ResumenTile(
              titulo: 'Mayor consumo',
              valor: pieza != null ? '${pieza.watts}W' : '—',
              subtitulo: pieza?.nombre ?? '',
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(width: 10),
            _ResumenTile(
              titulo: 'Categoría top',
              valor: _categoriaMayorConsumo,
              subtitulo: datos[_categoriaMayorConsumo] != null
                  ? '${datos[_categoriaMayorConsumo]!.toStringAsFixed(0)}W'
                  : '',
              icon: Icons.trending_up_rounded,
            ),
          ],
        ),
      ],
    );
  }

  // ── Widget: Detalle por pieza ────────────────────────────────────────────
  Widget _buildDetallePiezas(List<ItemModel> piezas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Desglose por pieza',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...piezas.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(p.nombre,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13)),
                  ),
                  Text(p.categoria,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(width: 12),
                  Text('${p.watts}W',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Widget auxiliar: tile de resumen ─────────────────────────────────────────
class _ResumenTile extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icon;
  const _ResumenTile(
      {required this.titulo,
      required this.valor,
      required this.subtitulo,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.secondary),
            const SizedBox(height: 8),
            Text(titulo,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(valor,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            if (subtitulo.isNotEmpty)
              Text(subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
