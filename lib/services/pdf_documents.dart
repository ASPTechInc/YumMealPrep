import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/ui.dart';

/// Builds printable, shareable PDFs of meals and recipes.
///
/// Everything is generated on the device with the bundled Noto Sans font,
/// so nothing is downloaded and accented letters, fractions and other
/// scripts print correctly. Pages flow onto as many sheets as the content
/// needs.
abstract final class PdfDocuments {
  static const String regularFont = 'assets/fonts/NotoSans-Regular.ttf';
  static const String boldFont = 'assets/fonts/NotoSans-Bold.ttf';

  static Future<pw.ThemeData>? _theme;

  /// The page theme with the bundled fonts, loaded once.
  static Future<pw.ThemeData> loadTheme({AssetBundle? bundle}) =>
      _theme ??= () async {
        final assets = bundle ?? rootBundle;
        return pw.ThemeData.withFont(
          base: pw.Font.ttf(await assets.load(regularFont)),
          bold: pw.Font.ttf(await assets.load(boldFont)),
        );
      }();

  static Future<Uint8List> recipe(
    Recipe recipe, {
    PdfPageFormat format = PdfPageFormat.a4,
    pw.ThemeData? theme,
    Uint8List? image,
    Uint8List? logo,
  }) {
    final document = _document(recipe.name, 'Recipe');
    final facts = <(String, String)>[
      if (recipe.preparationMinutes case final minutes?)
        ('Preparation', formatMinutes(minutes)),
      if (recipe.cookingMinutes case final minutes? when minutes > 0)
        ('Cooking', formatMinutes(minutes)),
      if (recipe.servings case final servings?) ('Serves', '$servings'),
    ];

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        theme: theme,
        header: (context) => _header(context, logo),
        footer: _footer,
        build: (context) => [
          ..._titleBlock(recipe.name, '${recipe.type.label} recipe', image),
          if (facts.isNotEmpty) _factsTable(facts),
          if (recipe.description.isNotEmpty) ...[
            _heading('Description'),
            pw.Paragraph(text: recipe.description),
          ],
          if (recipe.ingredients.isNotEmpty) ...[
            _heading('Ingredients'),
            for (final ingredient in recipe.ingredients)
              pw.Bullet(text: ingredient),
          ],
          if (recipe.instructions.isNotEmpty) ...[
            _heading('Method'),
            // Steps stay in the order they were written.
            for (final (index, step) in recipe.instructions.indexed)
              _numberedStep(index + 1, step),
          ],
        ],
      ),
    );
    return document.save();
  }

  static Future<Uint8List> meal(
    Meal meal, {
    PdfPageFormat format = PdfPageFormat.a4,
    pw.ThemeData? theme,
    Uint8List? image,
    Uint8List? logo,
    List<Uint8List> nutritionFacts = const [],
  }) {
    final document = _document(meal.name, 'Meal');
    final facts = <(String, String)>[
      if (meal.drink.isNotEmpty) ('Drink', meal.drink),
      if (meal.sideDishes.isNotEmpty)
        ('Side dishes', meal.sideDishes.join(', ')),
    ];

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        theme: theme,
        header: (context) => _header(context, logo),
        footer: _footer,
        build: (context) => [
          ..._titleBlock(meal.name, '${meal.type.label} meal', image),
          if (facts.isNotEmpty) _factsTable(facts),
          if (meal.description.isNotEmpty) ...[
            _heading('Description'),
            pw.Paragraph(text: meal.description),
          ],
          if (nutritionFacts.isNotEmpty) ...[
            _heading('Nutrition facts'),
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final bytes in nutritionFacts)
                  pw.Image(
                    pw.MemoryImage(bytes),
                    width: 160,
                    height: 220,
                    fit: pw.BoxFit.contain,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    return document.save();
  }

  /// A file name such as `vegetable_rice_recipe.pdf`.
  static String fileName(String name, String kind) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '${slug.isEmpty ? kind : slug}_$kind.pdf';
  }

  static pw.Document _document(String title, String kind) => pw.Document(
    title: title,
    subject: '$kind from ${Constants.appName}',
    creator: Constants.appName,
    producer: Constants.appName,
  );

  static pw.Widget _header(pw.Context context, Uint8List? logo) {
    if (context.pageNumber > 1) return pw.SizedBox();
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        children: [
          if (logo != null) ...[
            pw.Image(pw.MemoryImage(logo), width: 28, height: 28),
            pw.SizedBox(width: 8),
          ],
          pw.Text(
            Constants.appName,
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context) => pw.Container(
    alignment: pw.Alignment.centerRight,
    margin: const pw.EdgeInsets.only(top: 16),
    child: pw.Text(
      'Shared from ${Constants.appName}  ·  '
      'Page ${context.pageNumber} of ${context.pagesCount}',
      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
    ),
  );

  static List<pw.Widget> _titleBlock(
    String title,
    String subtitle,
    Uint8List? image,
  ) => [
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: const pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 13,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        if (image != null)
          pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(
              pw.MemoryImage(image),
              width: 140,
              height: 105,
              fit: pw.BoxFit.cover,
            ),
          ),
      ],
    ),
    pw.SizedBox(height: 16),
  ];

  static pw.Widget _factsTable(List<(String, String)> facts) => pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        for (final (label, value) in facts)
          pw.Column(
            children: [
              pw.Text(
                label,
                style: const pw.TextStyle(color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                value,
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
      ],
    ),
  );

  static pw.Widget _heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
    child: pw.Text(
      text,
      style: const pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.teal800,
      ),
    ),
  );

  static pw.Widget _numberedStep(int number, String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 20,
          height: 20,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            color: PdfColors.teal700,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text(
            '$number',
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(child: pw.Text(text)),
      ],
    ),
  );
}
