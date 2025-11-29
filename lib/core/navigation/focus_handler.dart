import 'package:flutter/widgets.dart';

class FocusHandler {
  static void setFocus(BuildContext context, FocusNode node) {
    FocusScope.of(context).requestFocus(node);
  }

  static void clearFocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}
