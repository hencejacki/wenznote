import 'package:ydart/ydart.dart';

import 'YsTree.dart';

class YsItem {
  YsTree tree;
  YMap yMap;
  List<YsItem>? children;
  int updateTime = 0;

  YsItem({
    required this.tree,
    required this.yMap,
  });
}
