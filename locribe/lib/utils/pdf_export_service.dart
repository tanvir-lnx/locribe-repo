import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  static Future<void> exportToPdf({
    required String transcript,
    required String summary,
  }) async {
    final pdf = pw.Document();

    // MultiPage automatically handles page breaks for long text
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'LoCribe Executive Summary',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Summary Section
            pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(summary, style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5)),
            
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 24),
            
            // Transcript Section
            pw.Text('Raw Transcript', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(
              transcript,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700, lineSpacing: 1.5),
            ),
          ];
        },
      ),
    );

    // This triggers the native macOS/iOS share sheet (Save to Files, AirDrop, etc.)
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'locribe_export_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}