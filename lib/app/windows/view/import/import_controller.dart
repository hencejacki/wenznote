import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart';
import 'package:wenznote/commons/service/import_service.dart';
import 'package:wenznote/commons/util/string.dart';
import 'package:wenznote/service/service_manager.dart';

class ImportController extends ServiceManagerController {
  var processNodeIndex = 0.obs;
  var importPaths = <String>[].obs;

  // 拖拽进入状态
  var isDropEnter = false.obs;

  // 判断是否是支持的导入路径
  bool canImportFile(String path) {
    return path.endsWith(".md") ||
        path.endsWith(".wdoc") ||
        path.endsWith(".zip");
  }

  void showImportDialog(BuildContext context) async {
    var future = () async {
      await doImport(importPaths: importPaths);
    }();
    await showDialog(
        useSafeArea: true,
        context: context,
        builder: (context) => FutureProgressDialog(
              future,
              message: const Text("正在导入..."),
            ));
    context.pop();
    showToast(
      "导入完成！",
      position: ToastPosition.bottom,
    );
  }

  Future<void> doImport({
    required List<String> importPaths,
    String toPath = "",
    ConflictMode conflictMode = ConflictMode.keepAll,
  }) async {
    for (var path in importPaths) {
      if (File(path).statSync().type == FileSystemEntityType.directory) {
        var fileList = Directory(path).listSync().map((e) => e.path).toList();
        await doImport(
            importPaths: fileList,
            conflictMode: conflictMode,
            toPath: "$toPath/${basename(path)}".trimChar("/"));
      } else if (path.endsWith(".zip")) {
        await importZipFile(file: path, conflictMode: conflictMode);
      } else if (path.endsWith(".md")) {
        await serviceManager.importService.importMarkdownFile(
          file: path,
          toPath: toPath,
          conflictMode: conflictMode,
        );
      } else if (path.endsWith(".wdoc")) {
        await serviceManager.importService.importWdoc(
          file: path,
          toPath: toPath,
          conflictMode: conflictMode,
        );
      }
    }
  }

  Future<void> importZipFile({
    required String file,
    ConflictMode conflictMode = ConflictMode.keepAll,
  }) async {
    var dir = Directory.systemTemp.createTempSync("wennote");
    try {
      await extractFileToDisk(file, dir.path);
      await doImport(importPaths: [dir.path], conflictMode: conflictMode);
    } finally {
      dir.deleteSync(recursive: true);
    }
  }
}
