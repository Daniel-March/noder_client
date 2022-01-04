import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Storage {
  late Database _db;

  Storage();

  Future<void> init(String database) async {
    await _connect(database);
  }

  Future<void> _createDatabase(Database _db, int version) async {
    await _db.execute("CREATE TABLE clusters (title TEXT, tasks TEXT)");
  }

  Future<void> _connect(String database) async {
    String databasePath = join(await getDatabasesPath(), database);
    // await deleteDatabase(databasePath); // TODO Удалить в конце
    _db = await openDatabase(databasePath, version: 1, onCreate: _createDatabase);
  }

  Future<List<Map>> getClusters() async {
    List<Map> db_clusters = List.from(await _db.query("clusters"));
    List<Map> clusters = [];
    for (int index = 0; index < db_clusters.length; index++) {
      clusters.add(Map.from(db_clusters[index]));
      clusters[index]["tasks"] = jsonDecode(clusters[index]["tasks"]);
    }
    return clusters;
  }

  Future<void> addCluster(Map cluster) async {
    await _db.insert("clusters", {"title": cluster["title"], "tasks": jsonEncode(cluster['tasks'])});
  }

  Future<void> delCluster(Map cluster) async {
    await _db.delete("clusters", where: "title = '${cluster['title']}' AND tasks = '${jsonEncode(cluster['tasks'])}'");
  }

  Future<void> changeCluster(Map oldData, Map newData) async {
    await delCluster(oldData);
    await addCluster(newData);
  }
}
