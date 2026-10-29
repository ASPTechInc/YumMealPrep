import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openAppDatabase(String name) async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return databaseFactoryIo.openDatabase(p.join(directory.path, name));
}
