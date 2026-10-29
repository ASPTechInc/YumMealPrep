import 'dart:convert';
import 'dart:io';

import 'package:pdf/widgets.dart' as pw;

import 'package:flutter_test/flutter_test.dart';

import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/models/recipe.dart';
import 'package:yummealprep/screens/settings/text_document_screen.dart';
import 'package:yummealprep/services/pdf_documents.dart';

void main() {
  group('PdfDocuments', () {
    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(
        File(PdfDocuments.regularFont).readAsBytesSync().buffer.asByteData(),
      ),
      bold: pw.Font.ttf(
        File(PdfDocuments.boldFont).readAsBytesSync().buffer.asByteData(),
      ),
    );

    test('builds a recipe PDF without any network access', () async {
      final bytes = await PdfDocuments.recipe(
        Recipe(
          id: 'r',
          name: 'Sweat Ground Provisions',
          type: MealType.lunch,
          description: 'Sautéed with onions — ½ tsp salt.',
          ingredients: List.generate(60, (i) => 'Ingredient ${i + 1}'),
          instructions: List.generate(40, (i) => 'Step ${i + 1}'),
          preparationMinutes: 10,
          cookingMinutes: 20,
          servings: 5,
        ),
        theme: theme,
      );
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('builds a meal PDF', () async {
      final bytes = await PdfDocuments.meal(
        const Meal(
          id: 'm',
          name: 'Pelau',
          type: MealType.lunch,
          drink: 'Sorrel',
          sideDishes: ['Coleslaw'],
        ),
      );
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('makes safe file names', () {
      expect(
        PdfDocuments.fileName('White Rice (Plain)!', 'recipe'),
        'white_rice_plain_recipe.pdf',
      );
      expect(PdfDocuments.fileName('???', 'meal'), 'meal_meal.pdf');
    });
  });

  test('markdownBlocks splits headings, bullets and paragraphs', () {
    const markdown = '''
# Privacy policy

Line one
continues here.

## Summary

- First point
  wraps onto a second line.
- Second point
''';
    final blocks = markdownBlocks(markdown);
    expect(blocks.map((block) => block.kind), [
      BlockKind.heading1,
      BlockKind.paragraph,
      BlockKind.heading2,
      BlockKind.bullet,
      BlockKind.bullet,
    ]);
    expect(blocks[1].text, 'Line one continues here.');
    expect(blocks[3].text, 'First point wraps onto a second line.');
  });

  test('inlineRuns finds Markdown links', () {
    final runs = inlineRuns(
      '**Pelau**: [Dish.jpg](https://commons.wikimedia.org/x) by K6ka',
    );
    expect(runs.map((run) => run.text), ['Pelau: ', 'Dish.jpg', ' by K6ka']);
    expect(runs[1].url, 'https://commons.wikimedia.org/x');
    expect(runs[0].url, isNull);
  });
}
