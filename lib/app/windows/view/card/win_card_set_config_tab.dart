import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wenznote/app/windows/controller/card/win_card_set_config_tab_controller.dart';
import 'package:wenznote/editor/theme/theme.dart';
import 'package:wenznote/editor/widget/drop_menu.dart';
import 'package:wenznote/editor/widget/toggle_item.dart';
import 'package:window_manager/window_manager.dart';

class WinCardSetConfigTab extends StatelessWidget {
  final WinCardSetConfigTabController controller;

  const WinCardSetConfigTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildNav(context),
        Expanded(
          child: buildContent(context),
        ),
      ],
    );
  }

  Widget buildNav(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // drawer button
          ToggleItem(
            onTap: (ctx) {
              controller.closeTab();
            },
            itemBuilder:
                (BuildContext context, bool checked, bool hover, bool pressed) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Icon(
                  Icons.arrow_back,
                  size: 24,
                ),
              );
            },
          ),
          Expanded(
              child: DragToMoveArea(
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "学习设置",
                style: TextStyle(fontSize: 16),
              ),
            ),
          )),
          // actions
        ],
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Obx(() {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...buildConfigGroupItem(
                context,
                "学习数量",
                [
                  buildInputTextConfigItem(
                      context, "每日学习数量", "${controller.studyCount}", (text) {
                    controller.studyCount = int.tryParse(
                          text,
                        ) ??
                        controller.studyCount;
                  }),
                ],
              ),
              ...buildConfigGroupItem(
                context,
                "学习偏好",
                [
                  buildSingleSelectConfigItem(
                    context: context,
                    title: "学习顺序",
                    content: CheckItem(
                      id: controller.studyOrderType,
                      label: controller.studyOrderTypeName,
                    ),
                    onChanged: (val) {
                      controller.studyOrderType = val.id;
                    },
                    items: [
                      CheckItem(
                        id: "createTime",
                        label: controller.getOrderTypeName("createTime"),
                      ),
                      CheckItem(
                        id: "random",
                        label: controller.getOrderTypeName("random"),
                      ),
                    ],
                  ),
                  buildSingleSelectConfigItem(
                    context: context,
                    title: "学习模式",
                    content: CheckItem(
                      id: controller.studyQueueMode,
                      label: controller.studyQueueModeName,
                    ),
                    onChanged: (val) {
                      controller.studyQueueMode = val.id;
                    },
                    items: [
                      CheckItem(
                        id: "mixin",
                        label: controller.getStudyQueueModeName("mixin"),
                      ),
                      CheckItem(
                        id: "study",
                        label: controller.getStudyQueueModeName("study"),
                      ),
                      CheckItem(
                        id: "review",
                        label: controller.getStudyQueueModeName("review"),
                      ),
                    ],
                  ),
                ],
              ),
              ...buildConfigGroupItem(
                context,
                "阅读设置",
                [
                  buildMultiSelectConfigItem(
                    context: context,
                    title: "挖空设置",
                    content: controller.hideTextMode
                        .map((e) => CheckItem(
                            id: e, label: controller.getHideTextModeName(e)))
                        .toList(),
                    onChanged: (val) {
                      controller.hideTextMode = val.map((e) => e.id).toList();
                    },
                    items: controller.hideTextModes
                        .map((e) => CheckItem(
                            id: e, label: controller.getHideTextModeName(e)))
                        .toList(),
                  ),
                  buildSingleSelectConfigItem(
                    context: context,
                    title: "显示设置",
                    content: CheckItem(
                        id: controller.showMode,
                        label: controller.showModeName),
                    onChanged: (val) {
                      controller.showMode = val.id;
                    },
                    items: controller.showModes
                        .map((e) => CheckItem(
                            id: e, label: controller.getShowModeName(e)))
                        .toList(),
                  ),
                ],
              ),
              ...buildConfigGroupItem(
                context,
                "语音播放",
                [
                  buildSingleSelectConfigItem(
                    context: context,
                    title: "播放模式",
                    content: CheckItem(
                        id: controller.playTtsMode,
                        label: controller.playTssModeName),
                    onChanged: (val) {
                      controller.playTtsMode = val.id;
                    },
                    items: controller.playTtsModes
                        .map((e) => CheckItem(
                            id: e, label: controller.getPlayTtsModeName(e)))
                        .toList(),
                  ),
                  buildSingleSelectConfigItem(
                    context: context,
                    title: "播放类型",
                    content: CheckItem(
                        id: controller.ttsType, label: controller.ttsTypeName),
                    onChanged: (val) {
                      controller.ttsType = val.id;
                    },
                    items: controller.ttsTypes
                        .map((e) => CheckItem(
                            id: e, label: controller.getTtsTypeName(e)))
                        .toList(),
                  ),
                ],
              ),
              ...buildConfigGroupItem(
                context,
                "记忆算法",
                [
                  buildSingleSelectConfigItem(
                    context: context,
                    title: "记忆算法",
                    content: CheckItem(
                        id: controller.reviewAlgorithm,
                        label: controller.reviewAlgorithmName),
                    onChanged: (val) {
                      controller.reviewAlgorithm = val.id;
                    },
                    items: controller.reviewAlgorithms
                        .map((e) => CheckItem(
                            id: e, label: controller.getReviewAlgorithmName(e)))
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget buildConfigTitleItem(BuildContext context, String title) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 20,
      ),
      // color: Colors.red,
      child: Text(
        title,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  List<Widget> buildConfigGroupItem(
      BuildContext context, String title, List<Widget> items) {
    return [
      buildConfigTitleItem(context, "${title}"),
      Container(
        margin: EdgeInsets.symmetric(
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade100),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: items,
        ),
      ),
    ];
  }

  Widget buildConfigItem(
      BuildContext context, String title, String content, VoidCallback? onTap) {
    return ToggleItem(
      itemBuilder:
          (BuildContext context, bool checked, bool hover, bool pressed) {
        return Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 10),
          color: hover ? EditTheme.of(context).fontColor.withAlpha(10) : null,
          child: Row(
            children: [
              Expanded(child: Text("$title")),
              Text(
                "$content",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              SizedBox(
                width: 4,
              ),
              Icon(
                Icons.keyboard_arrow_right,
                color: EditTheme.of(context).fontColor.withAlpha(150),
              ),
            ],
          ),
        );
      },
      onTap: onTap,
    );
  }

  Widget buildInputTextConfigItem(BuildContext context, String title,
      String content, ValueChanged<String> onChanged) {
    return buildConfigItem(context, title, content, (context) {
      showDialog(
        context: context,
        builder: (context) {
          var controller = TextEditingController(text: content);
          return fluent.Container(
            padding: MediaQuery.of(context).viewInsets,
            child: fluent.ContentDialog(
              title: Text("${title}"),
              content: fluent.TextBox(
                placeholder: "请输入${title}",
                controller: controller,
                autofocus: true,
                onChanged: (text) {
                  onChanged.call(text);
                },
              ),
              actions: [
                fluent.OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("取消"),
                ),
                fluent.FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("确定"),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget buildSingleSelectConfigItem({
    required BuildContext context,
    required String title,
    required CheckItem content,
    required ValueChanged<CheckItem> onChanged,
    required List<CheckItem> items,
    double itemWidth = 150,
    double itemHeight = 40,
  }) {
    return buildConfigItem(context, title, content.label, (context) {
      showDropMenu(
        context,
        menus: [
          for (var value in items)
            DropMenu(
              text: Row(
                children: [
                  Expanded(child: Text(value.label)),
                  if (value == content) Icon(Icons.check),
                ],
              ),
              onPress: (ctx) {
                hideDropMenu(ctx);
                onChanged.call(value);
              },
            ),
        ],
        modal: true,
        popupAlignment: Alignment.bottomRight,
        overflowAlignment: Alignment.topRight,
        childrenWidth: itemWidth,
        childrenHeight: itemHeight,
      );
    });
  }

  Widget buildMultiSelectConfigItem({
    required BuildContext context,
    required String title,
    required List<CheckItem> content,
    required ValueChanged<List<CheckItem>> onChanged,
    required List<CheckItem> items,
    double itemWidth = 150,
    double itemHeight = 40,
  }) {
    var contentObs = content.obs;
    return buildConfigItem(
        context, title, content.map((e) => e.label).join("、"), (context) {
      showDropMenu(
        context,
        menus: [
          for (var value in items)
            DropMenu(
              text: Obx(
                () {
                  var checked = contentObs.contains(value);
                  return Row(
                    children: [
                      Expanded(child: Text(value.label)),
                      if (checked) Icon(Icons.check),
                    ],
                  );
                },
              ),
              onPress: (ctx) {
                var checked = contentObs.contains(value);
                if (checked) {
                  contentObs.remove(value);
                } else {
                  contentObs.add(value);
                }
                onChanged.call(items
                    .where((element) => contentObs.contains(element))
                    .toList());
              },
            ),
        ],
        modal: true,
        popupAlignment: Alignment.bottomRight,
        overflowAlignment: Alignment.topRight,
        childrenWidth: itemWidth,
        childrenHeight: itemHeight,
      );
    });
  }
}

class CheckItem {
  String id;
  String label;

  CheckItem({
    required this.id,
    required this.label,
  });

  @override
  bool operator ==(Object other) {
    if (other is CheckItem) {
      return id == other.id;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => id.hashCode;
}
