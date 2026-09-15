import 'package:flutter/widgets.dart';

import '../state/app_state.dart';

/// Exposes [JhAppState] to the tree and rebuilds dependants when it notifies.
///
/// The module has one state object and no async data, so an
/// [InheritedNotifier] keeps the app dependency-free -- there is nothing here
/// a package would do better.
class JhScope extends InheritedNotifier<JhAppState> {
  const JhScope({super.key, required JhAppState state, required super.child})
    : super(notifier: state);

  static JhAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<JhScope>();
    assert(scope != null, 'No JhScope found in context');
    return scope!.notifier!;
  }

  /// Reads the state without subscribing to changes -- for callbacks.
  static JhAppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<JhScope>();
    assert(scope != null, 'No JhScope found in context');
    return scope!.notifier!;
  }
}
