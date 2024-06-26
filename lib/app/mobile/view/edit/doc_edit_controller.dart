import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wenznote/app/windows/outline/outline_controller.dart';
import 'package:wenznote/commons/mvc/controller.dart';
import 'package:wenznote/editor/crdt/YsEditController.dart';
import 'package:wenznote/editor/crdt/YsTree.dart';
import 'package:wenznote/model/note/po/doc_po.dart';
import 'package:wenznote/service/service_manager.dart';
import 'package:ydart/ydart.dart';

import '../../../../commons/util/log_util.dart';

typedef DocReader = Future<YDoc> Function(BuildContext context);

class MobileDocEditController extends ServiceManagerController {
  var title = "便签".obs;
  late YsEditController editController;
  YsTree? ysTree;
  var isShowBottomPane = false.obs;
  var keyboardHeight = 0.0.obs;
  var keyboardHeightRecord = 0.0.obs;
  var bottomIndex = 0.obs;
  var textLevel = 0.obs;
  var outlineController = OutlineController();
  var drawSwipeEnable = true.obs;
  var canUndo = false.obs;
  var canRedo = false.obs;
  var textLength = 0.obs;
  DocPO? doc;
  bool hiderAppbar = false;
  Widget? submitButton;
  bool editOnOpen = false;
  bool showOutline = true;
  var canUpdateTitle = false.obs;

  MobileDocEditController({
    this.doc,
    this.hiderAppbar = false,
    this.submitButton,
    this.editOnOpen = false,
    this.showOutline = true,
  });

  @override
  void onInitState(BuildContext context) {
    super.onInitState(context);
    serviceManager.editService.addOpenedDocEditor(doc?.uuid ?? "");
    canUpdateTitle.value = title.value.isEmpty;
    editController = YsEditController(
      copyService: serviceManager.copyService,
      fileManager: serviceManager.fileManager,
      initFocus: false,
      padding: const EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 100,
      ),
      scrollController: ScrollController(),
      maxEditWidth: 1000,
    );
    editController.addListener(() {
      SchedulerBinding.instance.scheduleFrameCallback((timeStamp) {
        outlineController.updateTree(
            editController.viewContext, editController);
      });
    });
    title.listen((val) {
      if (canUpdateTitle.isTrue) {
        doc!.name = val;
        serviceManager.docService.updateDoc(doc!);
      }
    });
    canUndo.value = editController.canUndo;
    canRedo.value = editController.canRedo;
    editController.onContentChanged = () {
      outlineController.updateTree(editController.viewContext, editController);
      canUndo.value = editController.canUndo;
      canRedo.value = editController.canRedo;
      textLength.value = editController.textLength;
    };
    editController.viewContext = context;
    readDoc();
  }

  @override
  void onDispose() {
    super.onDispose();
    serviceManager.editService.removeOpendDocEditor(doc?.uuid ?? "");
    ysTree?.dispose();
  }

  @override
  void onDidUpdateWidget(BuildContext context, MvcController oldController) {
    super.onDidUpdateWidget(context, oldController);
    var old = oldController as MobileDocEditController;
    title = old.title;
    editController = old.editController;
    ysTree = old.ysTree;
    isShowBottomPane = old.isShowBottomPane;
    keyboardHeight = old.keyboardHeight;
    keyboardHeightRecord = old.keyboardHeightRecord;
    bottomIndex = old.bottomIndex;
    textLevel = old.textLevel;
    outlineController = old.outlineController;
    drawSwipeEnable = old.drawSwipeEnable;
    canUndo = old.canUndo;
    canRedo = old.canRedo;
    textLength = old.textLength;
    doc = old.doc;
    hiderAppbar = old.hiderAppbar;
    submitButton = old.submitButton;
    editOnOpen = old.editOnOpen;
    showOutline = old.showOutline;
    canUpdateTitle = old.canUpdateTitle;
  }

  Future<void> readDoc() async {
    title.value = this.doc?.name ?? "";
    var doc = await serviceManager.editService.readDoc(this.doc?.uuid);
    if (doc != null) {
      initYsTree(doc);
      editController.waitLayout(() {
        editController.requestFocus();
      });
      doc.updateV2['update'] = ((data, origin, transaction) {
        if (transaction.local != true) {
          // 如果不是本地更新的话，就不需要写入文件了
          return;
        }
        serviceManager.editService.writeDoc(this.doc?.uuid, doc);
        serviceManager.p2pService
            .sendDocEditMessage(this.doc?.uuid ?? "", data);
      });
    }
  }

  void initYsTree(YDoc doc) {
    ysTree = YsTree(
      context: context,
      editController: editController,
      yDoc: doc,
    );
    ysTree!.init();
  }

  void getTextStyle() {
    int? level;
    bool isSameLevel = true;
    editController.visitSelectBlock(
      (block) {
        if (level == null) {
          level = block.element.level;
          return;
        }
        if (block.element.level != level) {
          isSameLevel = false;
        } else {
          level = block.element.level;
        }
      },
      visitCursor: true,
    );
    if (!isSameLevel) {
      level = 0;
    }
    if (level != null) {
      textLevel.value = level!;
    }
  }

  void changeAlignment(String? alignment) {
    editController.setAlignment(alignment);
  }

  void redo() {
    editController.redo();
  }

  void undo() {
    editController.undo();
  }

  void copyContent(BuildContext ctx) {
    serviceManager.copyService.copyDocContent(ctx, doc?.uuid ?? "");
  }

  void deleteNote(BuildContext ctx) {
    serviceManager.docService.deleteDoc(doc!);
    ctx.pop();
  }

  void syncNow(BuildContext ctx) async {
    printLog("手动同步笔记：${doc?.uuid},${doc?.name}");
    await serviceManager.uploadTaskService.uploadDoc(doc?.uuid ?? "", 0);
  }
}
