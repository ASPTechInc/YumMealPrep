import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:yummealprep/app.dart';
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/sample_data.dart';
import 'package:yummealprep/utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lists YumMealPrep's own licence alongside its dependencies' licences on
  // the "View licences" page.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      Constants.appName,
    ], await rootBundle.loadString(Constants.licence));
    yield LicenseEntryWithLineBreaks([
      'Noto Sans',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });

  final AppServices services;
  try {
    services = await AppServices.open();
  } on Object catch (error) {
    runApp(StartupErrorApp(error: error));
    return;
  }

  try {
    await SampleData(services.database, services.settings).addIfNeeded();
  } on Object catch (error, stackTrace) {
    // The app is still usable without the sample meals and recipes.
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'yummealprep',
        context: ErrorDescription('while adding the sample data'),
      ),
    );
  }

  runApp(YumMealPrepApp(services: services));
}
