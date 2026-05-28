import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/api_models/item_model.dart';

class PdfGenerator {
  /// [amazonPrecios] es un Map de nombre de pieza -> precio en Amazon (String, ej "$230.00")
  static Future<void> exportAndSharePdf(
    List<ItemModel> items,
    double totalPrecioLocal,
    int totalWatts, {
    Map<String, String> amazonPrecios = const {},
  }) async {
    final pdf = pw.Document();
    final bool tieneAmazon = amazonPrecios.isNotEmpty;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Orden de Ensamble de PC',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                tieneAmazon
                    ? 'Precios de referencia consultados en Amazon.'
                    : 'Listado de componentes seleccionados.',
                style: const pw.TextStyle(fontSize: 13),
              ),
              pw.SizedBox(height: 16),

              // ── Tabla de componentes ───────────────────────────────────────
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey400),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                data: <List<String>>[
                  // Encabezados
                  <String>[
                    'N°',
                    'Componente',
                    'Categoría',
                    'Consumo (W)',
                    tieneAmazon ? 'Precio Amazon (USD)' : 'Precio Est. (Q)',
                  ],
                  // Filas de datos
                  ...items.asMap().entries.map((e) {
                    final nombre = e.value.nombre;
                    final precioMostrar = tieneAmazon
                        ? (amazonPrecios[nombre] ?? 'No encontrado')
                        : 'Q${e.value.precio.toStringAsFixed(2)}';

                    return [
                      (e.key + 1).toString(),
                      nombre,
                      e.value.categoria,
                      e.value.watts.toString(),
                      precioMostrar,
                    ];
                  }),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // ── Totales ────────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Consumo de Energía:',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text('$totalWatts W',
                      style: const pw.TextStyle(fontSize: 13)),
                ],
              ),
              pw.SizedBox(height: 6),
              if (!tieneAmazon) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Estimado:',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Q${totalPrecioLocal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ],
              if (tieneAmazon) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  '* Precios obtenidos de Amazon. Los valores están en dólares (USD) y pueden variar.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/orden_ensamble.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Adjunto mi orden de ensamble de PC.',
    );
  }
}
