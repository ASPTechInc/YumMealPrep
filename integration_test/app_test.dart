import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';

import 'package:yummealprep/models/meal.dart';
import 'package:yummealprep/models/meal_type.dart';
import 'package:yummealprep/services/image_processing.dart';

import 'support.dart';

/// End-to-end tests of the real app on a device or emulator, with the real
/// database, file storage and image processing.
///
/// Run: `flutter test integration_test/app_test.dart -d <device>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch shows the planner and sample data', (tester) async {
    await startApp(tester);
    expect(find.text('Meal Planner'), findsOneWidget);
    expect(find.text('No meals planned for this day.'), findsOneWidget);

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(find.text('Breakfast'), findsOneWidget);
  });

  testWidgets('plans a sample meal for today', (tester) async {
    final services = await startApp(tester);
    await tester.tap(find.text('Plan a meal').first);
    await tester.pumpAndSettle();
    final breakfast = find.widgetWithText(ChoiceChip, 'Breakfast');
    await tester.ensureVisible(breakfast);
    await tester.pumpAndSettle();
    await tester.tap(breakfast);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pancake & Scrambled Eggs').last);
    await tester.pumpAndSettle();

    expect(find.text('1 meal'), findsOneWidget);
    expect(await services.mealPlan.getAll(), hasLength(1));
  });

  testWidgets('a photo is resized, stored once and survives a backup', (
    tester,
  ) async {
    final services = await startApp(tester);

    // A 12-megapixel "photo" with location metadata, as a phone takes.
    final photo = img.Image(width: 4000, height: 3000);
    img.fill(photo, color: img.ColorRgb8(200, 120, 40));
    photo.exif.imageIfd['Make'] = 'PhoneCam';
    final prepared = await prepareImage(img.encodeJpg(photo), extension: 'jpg');
    expect(img.decodeJpg(prepared.bytes)!.width, maxImageSide);

    final source = await services.images.save(prepared.bytes);
    expect(await services.images.save(prepared.bytes), source);
    await services.meals.save(
      Meal(
        id: 'curry',
        name: 'Curry Goat',
        type: MealType.dinner,
        image: source,
      ),
    );

    // New phone: export, wipe everything, import.
    final backup = await services.backup.export();
    await services.backup.restore(
      utf8.encode('{"format": "yummealprep-backup", "version": 1}'),
      replaceAll: true,
    );
    expect(await services.meals.get('curry'), isNull);
    expect(await services.images.readBytes(source), isNull);

    await services.backup.restore(backup, replaceAll: true);
    final restored = (await services.meals.get('curry'))!;
    expect(await services.images.readBytes(restored.image!), prepared.bytes);
  });
}
