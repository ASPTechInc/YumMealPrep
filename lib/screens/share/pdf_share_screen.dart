import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Previews a PDF with buttons to print it or share it with another app.
class PdfShareScreen extends StatelessWidget {
  const PdfShareScreen({
    required this.title,
    required this.fileName,
    required this.buildPdf,
    super.key,
  });

  final String title;
  final String fileName;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: buildPdf,
        pdfFileName: fileName,
        canDebug: false,
        canChangeOrientation: false,
        initialPageFormat: PdfPageFormat.a4,
        onError: (context, error) =>
            Center(child: Text('The PDF could not be created.\n$error')),
      ),
    );
  }
}
