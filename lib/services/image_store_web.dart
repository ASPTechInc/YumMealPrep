import 'package:yummealprep/services/image_store.dart';

Future<ImageStore> openImageStore() async => DataUriImageStore();
