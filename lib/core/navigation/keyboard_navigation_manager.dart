import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class KeyboardNavigationManager {
  static final KeyboardNavigationManager _instance = KeyboardNavigationManager._internal();
  factory KeyboardNavigationManager() => _instance;
  KeyboardNavigationManager._internal();

  static FocusNode getFocus(BuildContext context) => Focus.of(context);

  /// Registers global keyboard shortcuts for navigation.
  static Widget withArrowNavigation({
    required Widget child,
    required void Function(LogicalKeyboardKey key) onArrowKey,
  }) {
    return Focus(
      autofocus: true,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.escape) {
              onArrowKey(event.logicalKey);
            }
          }
        },
        child: child,
      ),
    );
  }
}
