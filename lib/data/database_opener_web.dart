import 'package:sembast_web/sembast_web.dart';

Future<Database> openAppDatabase(String name) =>
    databaseFactoryWeb.openDatabase(name);
