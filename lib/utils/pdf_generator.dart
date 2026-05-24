import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/api_models/item_model.dart';

class PdfGenerator {
  static Future<void> exportAndSharePdf(List<ItemModel> items, double totalPrecio, int totalWatts) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Orden de Ensamble de PC', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Listado de componentes seleccionados para tu ensamble.', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey400),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellAlignment: pw.Alignment.centerLeft,
                data: <List<String>>[
                  <String>['N°', 'Componente', 'Categoría', 'Consumo (W)', 'Precio (Q)'],
                  ...items.asMap().entries.map((e) => [
                        (e.key + 1).toString(),
                        e.value.nombre,
                        e.value.categoria,
                        e.value.watts.toString(),
                        e.value.precio.toStringAsFixed(2),
                      ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Consumo de Energía:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('$totalWatts W', style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Estimado:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Q${totalPrecio.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Guardar el PDF temporalmente
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/orden_ensamble.pdf');
    await file.writeAsBytes(await pdf.save());

    // Compartir el archivo
    await Share.shareXFiles([XFile(file.path)], text: 'Adjunto mi orden de ensamble de PC en formato PDF.');
  }
}
