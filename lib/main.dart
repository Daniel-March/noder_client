import 'package:flutter/material.dart';
import 'package:noder/screens/main_screen.dart';
import 'package:noder/storage.dart';

Storage storage = Storage();

Future<void> main() async {
 WidgetsFlutterBinding.ensureInitialized();
 await storage.init("database.sqlite3");

 runApp(MaterialApp(home: MainScreen(storage), theme: ThemeData(fontFamily: "Montserrat")));
}
