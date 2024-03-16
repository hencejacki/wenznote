import 'package:wenznote/editor/block/element/element.dart';

class LineElement extends WenElement {
  LineElement({super.type = "line"});

  @override
  String getMarkDown({FilePathBuilder? filePathBuilder}) {
    return "---";
  }
}
