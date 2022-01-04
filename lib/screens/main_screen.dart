import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:noder/requests.dart';
import 'package:noder/storage.dart';

class MainScreen extends StatefulWidget {
  Storage storage;

  MainScreen(this.storage, {Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String title = "Нет списков задач";
  PageController pageController = PageController();
  List<Map>? clusters;

  void updateClustersList() {
    widget.storage.getClusters().then((clusters) {
      setState(() {
        for (int i = 0; i < clusters.length; i++) {
          clusters[i]["color"] = Color.fromRGBO(Random().nextInt(255), 180, Random().nextInt(255), 1);
        }
        this.clusters = clusters;

        if (clusters.isNotEmpty) title = clusters[0]["title"];
      });
    });
  }

  void shareCluster() {
    Navigator.of(context).pop();
    String name = clusters![pageController.page!.ceil()]["title"];
    showDialog(context: context, builder: (context) => shareClusterDialog(context, name, uploadClusterToServer));
  }

  void downloadCluster() {
    Navigator.of(context).pop();
    showDialog(context: context, builder: (context) => downloadClusterDialog(context, downloadClusterToStorage));
  }

  void newCluster() {
    Navigator.of(context).pop();
    showDialog(context: context, builder: (context) => newClusterDialog(context, createCluster));
  }

  void renameCluster() {
    String name = clusters![pageController.page!.ceil()]["title"];
    showDialog(context: context, builder: (context) => changeClusterDialog(context, name, changeCluster));
  }

  void removeCluster() {
    String name = clusters![pageController.page!.ceil()]["title"];
    showDialog(context: context, builder: (context) => removeClusterDialog(context, name, deleteCluster));
  }

  void newTask() {
    showDialog(context: context, builder: (context) => newTaskDialog(context, createTask));
  }

  void renameTask(int taskIndex) {
    String name = clusters![pageController.page!.ceil()]["tasks"][taskIndex]["title"];

    showDialog(context: context, builder: (context) => changeTaskDialog(context, name, (String name) => changeTask(taskIndex, name)));
  }

  void removeTask(int taskIndex) {
    String name = clusters![pageController.page!.ceil()]["tasks"][taskIndex]["title"];

    showDialog(context: context, builder: (context) => removeTaskDialog(context, name, () => deleteTask(taskIndex)));
  }

  void uploadClusterToServer() {
    int page = pageController.page!.ceil();
    Map cluster = clusters![page];
    cluster.remove("color");
    Requests.uploadCluster(cluster).then((value) {
      setState(() {
        showDialog(context: context, builder: (context) => clusterUploadedDialog(context, value));
      });
    });
  }

  void downloadClusterToStorage(String token) {
    Requests.downloadCluster(token).then((value) {
      if (value != null) {
        setState(() {
          clusters!.add(value);
          showDialog(context: context, builder: (context) => clusterDownloadedDialog(context, value["title"]));
          widget.storage.addCluster(value);
        });
        goToPage(clusters!.length - 1);
      } else {
        showDialog(context: context, builder: (context) => clusterDownloadingFailedDialog(context, token));
      }
    });
  }

  void createCluster(String name) {
    Map<String, Object?> cluster = {"title": name, "tasks": [], "color": Color.fromRGBO(Random().nextInt(255), 180, Random().nextInt(255), 1)};
    setState(() {
      clusters!.add(cluster);
      widget.storage.addCluster(cluster);
    });
    goToPage(clusters!.length - 1);
  }

  void changeCluster(String name) {
    int clusterIndex = pageController.page!.ceil();
    setState(() {
      Map oldData = Map.from(clusters![clusterIndex]);
      oldData.remove('color');
      oldData = jsonDecode(jsonEncode(oldData));
      clusters![clusterIndex]["title"] = name;
      Map newData = clusters![clusterIndex];
      widget.storage.changeCluster(oldData, newData);
      title = name;
    });
  }

  void deleteCluster() {
    int clusterIndex = pageController.page!.ceil();
    widget.storage.delCluster(clusters![clusterIndex]);
    setState(() {
      clusters!.removeAt(clusterIndex);
      if (clusters!.isNotEmpty) {
        if (clusterIndex == 0) clusterIndex++;
        goToPage(clusterIndex - 1);
      } else {
        title = "У вас нет списков задач";
      }
    });
  }

  void changeTaskStatus(int taskIndex, bool status) {
    int clusterIndex = pageController.page!.ceil();
    setState(() {
      Map oldData = Map.from(clusters![clusterIndex]);
      oldData.remove('color');
      oldData = jsonDecode(jsonEncode(oldData));
      clusters![clusterIndex]["tasks"][taskIndex]["completed"] = status;
      Map newData = clusters![clusterIndex];
      widget.storage.changeCluster(oldData, newData);
    });
  }

  void createTask(String name) {
    int clusterIndex = pageController.page!.ceil();
    Map task = {"title": name, "completed": false};
    setState(() {
      Map oldData = Map.from(clusters![clusterIndex]);
      oldData.remove('color');
      oldData = jsonDecode(jsonEncode(oldData));
      clusters![clusterIndex]["tasks"].add(task);
      Map newData = clusters![clusterIndex];
      widget.storage.changeCluster(oldData, newData);
    });
  }

  void changeTask(int taskIndex, String name) {
    int clusterIndex = pageController.page!.ceil();
    setState(() {
      Map oldData = Map.from(clusters![clusterIndex]);
      oldData.remove('color');
      oldData = jsonDecode(jsonEncode(oldData));
      clusters![clusterIndex]["tasks"][taskIndex]["title"] = name;
      Map newData = clusters![clusterIndex];
      widget.storage.changeCluster(oldData, newData);
    });
  }

  void deleteTask(int taskIndex) {
    setState(() {
      Map oldData = Map.from(clusters![pageController.page!.ceil()]);
      oldData.remove('color');
      oldData = jsonDecode(jsonEncode(oldData));
      clusters![pageController.page!.ceil()]["tasks"].removeAt(taskIndex);
      Map newData = clusters![pageController.page!.ceil()];
      widget.storage.changeCluster(oldData, newData);
    });
  }

  void goToPage(int page) {
    if (clusters!.length != 1) pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.ease);
    setState(() {
      title = clusters![page]["title"];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (clusters == null) {
      clusters = [];
      updateClustersList();
    }
    return Scaffold(
      backgroundColor: Colors.white60,
      appBar: AppBar(
        title: Tooltip(message: title, child: Text(title)),
        backgroundColor: const Color.fromRGBO(221, 179, 103, 1.0),
        actions: clusters!.isNotEmpty
            ? [
                IconButton(onPressed: renameCluster, icon: const Icon(Icons.edit)),
                IconButton(onPressed: removeCluster, icon: const Icon(Icons.delete))
              ]
            : null,
      ),
      body: clusters!.isEmpty
          ? const Center(child: Text("Нет списков задач", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)))
          : PageView(
              controller: pageController,
              children: createClustersList(clusters!, changeTaskStatus, renameTask, removeTask),
              onPageChanged: (page) {
                setState(() {
                  title = clusters![page]["title"];
                });
              },
            ),
      floatingActionButton: clusters!.isEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: const Color.fromRGBO(221, 179, 103, 1.0),
              onPressed: newTask,
              child: const Icon(Icons.add, size: 40),
            ),
      drawerEdgeDragWidth: 0,
      drawer: Drawer(
        child: Container(
          color: const Color.fromRGBO(212, 190, 152, 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Container(
                    color: const Color.fromRGBO(221, 179, 103, 1.0),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(25, 50, 25, 25),
                      child: Text("Noder", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                )
              ]),
              TextButton.icon(
                style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: newCluster,
                label: const Text("Новый список задач", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              clusters!.isNotEmpty
                  ? TextButton.icon(
                      style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: shareCluster,
                      label: const Text("Поделиться списком задач", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
                    )
                  : Container(),
              TextButton.icon(
                style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: downloadCluster,
                label: const Text("Загрузить список задач", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> createClustersList(List<Map> clusters, Function onChangeStatus, Function onChange, Function onDelete) {
  List<Widget> clustersList = [];
  for (int clusterIndex = 0; clusterIndex < clusters.length; clusterIndex++) {
    Map cluster = clusters[clusterIndex];
    List<Widget> tasksList = [];
    for (int taskIndex = 0; taskIndex < cluster["tasks"].length; taskIndex++) {
      Map task = cluster["tasks"][taskIndex];
      tasksList.add(Row(
        children: [
          Checkbox(
            value: task["completed"],
            onChanged: (bool? value) {
              onChangeStatus(taskIndex, value);
            },
          ),
          Expanded(
              child: Text(
            task["title"],
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
          )),
          IconButton(onPressed: () => onChange(taskIndex), icon: const Icon(Icons.edit)),
          IconButton(onPressed: () => onDelete(taskIndex), icon: const Icon(Icons.delete_forever_outlined))
        ],
      ));
    }
    clustersList.add(Container(
        color: cluster["color"],
        child: ListView(
          children: tasksList,
        )));
  }
  return clustersList;
}

Widget newClusterDialog(BuildContext context, Function createCluster) {
  TextEditingController textEditingController = TextEditingController();
  textEditingController.text = "Новый список задач";
  return AlertDialog(
    title: const Text('Новый список задач'),
    content: TextField(
      controller: textEditingController,
    ),
    actions: [
      ElevatedButton(
        onPressed: () {
          createCluster(textEditingController.text);
          Navigator.of(context).pop();
        },
        child: const Text('Создать'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Отмена'),
      ),
    ],
  );
}

Widget changeClusterDialog(BuildContext context, String name, Function changeCluster) {
  TextEditingController textEditingController = TextEditingController();
  textEditingController.text = name;
  return AlertDialog(
    title: const Text('Новое название'),
    content: TextField(
      controller: textEditingController,
    ),
    actions: [
      ElevatedButton(
        onPressed: () {
          changeCluster(textEditingController.text);
          Navigator.of(context).pop();
        },
        child: const Text('Изменить'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Отмена'),
      ),
    ],
  );
}

Widget removeClusterDialog(BuildContext context, String clusterName, Function deleteCluster) {
  return AlertDialog(
    title: const Text('Удалить список задач?'),
    content: Text(clusterName),
    actions: [
      ElevatedButton(
        onPressed: () {
          deleteCluster();
          Navigator.of(context).pop();
        },
        child: const Text('Удалить'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Отмена'),
      ),
    ],
  );
}

Widget newTaskDialog(BuildContext context, Function createTask) {
  TextEditingController textEditingController = TextEditingController();
  textEditingController.text = "Новая задача";
  return AlertDialog(
    title: const Text('Новая задача'),
    content: TextField(
      controller: textEditingController,
    ),
    actions: [
      ElevatedButton(
        onPressed: () {
          createTask(textEditingController.text);
          Navigator.of(context).pop();
        },
        child: const Text('Создать'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Отмена'),
      ),
    ],
  );
}

Widget changeTaskDialog(BuildContext context, String name, Function changeTask) {
  TextEditingController textEditingController = TextEditingController();
  textEditingController.text = name;
  return AlertDialog(
    title: const Text('Новая задача'),
    content: TextField(
      controller: textEditingController,
    ),
    actions: [
      ElevatedButton(
        onPressed: () {
          changeTask(textEditingController.text);
          Navigator.of(context).pop();
        },
        child: const Text('Изменить'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Отмена'),
      ),
    ],
  );
}

Widget removeTaskDialog(BuildContext context, String taskName, Function deleteTask) {
  return AlertDialog(
    title: const Text('Удалить задачу?'),
    content: Text(taskName),
    actions: [
      ElevatedButton(
        onPressed: () {
          deleteTask();
          Navigator.of(context).pop();
        },
        child: const Text('Удалить'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Отмена'),
      ),
    ],
  );
}

Widget downloadClusterDialog(BuildContext context, Function downloadCluster) {
  TextEditingController textEditingController = TextEditingController();
  return AlertDialog(
    title: const Text('Загрузить список задач'),
    content: TextField(
      controller: textEditingController,
    ),
    actions: [
      ElevatedButton(
        onPressed: () {
          downloadCluster(textEditingController.text);
          Navigator.of(context).pop();
        },
        child: const Text('Загрузить'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Отмена'),
      ),
    ],
  );
}

Widget shareClusterDialog(BuildContext context, String clusterName, Function shareCluster) {
  return AlertDialog(
    title: Text('Поделиться списком задач "$clusterName"?'),
    actions: [
      ElevatedButton(
        onPressed: () {
          shareCluster();
          Navigator.of(context).pop();
        },
        child: const Text('Поделиться'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Отмена'),
      ),
    ],
  );
}

Widget clusterDownloadedDialog(BuildContext context, String name) {
  return AlertDialog(
    title: Text('Список задач скачен: $name'),
    actions: [
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Ок'),
      ),
    ],
  );
}

Widget clusterDownloadingFailedDialog(BuildContext context, String token) {
  return AlertDialog(
    title: Text("Список задач c токеном '$token' не найден"),
    actions: [
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Ок'),
      ),
    ],
  );
}

Widget clusterUploadedDialog(BuildContext context, String token) {
  return AlertDialog(
    title: const Text('Список задач отправлен.'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Не потеряйте токен:",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SelectableText(token)
      ],
    ),
    actions: [
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Ок'),
      ),
    ],
  );
}
