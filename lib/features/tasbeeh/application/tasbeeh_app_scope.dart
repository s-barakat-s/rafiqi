import 'package:flutter/foundation.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_controller.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';

/// Application-scoped authority for Tasbeeh counter state within the main
/// Flutter engine.
///
/// One instance exists per process; pushed routes (ordinary Tasbeeh, linked
/// Daily Wird task sessions) observe it through [TasbeehSessionScope] instead
/// of creating competing controllers. Closing a route never disposes this
/// instance, and it owns the main-app named port for its whole lifetime.
///
/// NOTE: a Dart singleton is NOT shared across Flutter engines. The overlay
/// runs in a separate engine; its synchronization bridge is Phase 2B scope.
final class TasbeehAppScope {
  TasbeehAppScope._();

  static TasbeehController? _instance;
  static Future<void>? _initialization;

  /// The authoritative main-engine controller. Created lazily and never
  /// disposed by route lifecycle.
  static TasbeehController get controller {
    _instance ??= TasbeehController();
    return _instance!;
  }

  /// Idempotent initialization. Concurrent callers share one future, and a
  /// completed call is never re-run (so a stale reload cannot overwrite
  /// newer accepted state).
  static Future<void> ensureInitialized() {
    if (_initialization != null) return _initialization!;
    return _initialization = controller.initialize();
  }

  /// Test-only: drops the singleton so a test can build a fresh scope.
  @visibleForTesting
  static void resetForTesting() {
    _instance?.dispose();
    _instance = null;
    _initialization = null;
  }
}

/// Lightweight per-route adapter exposing [TasbeehAppScope.controller] state
/// to a pushed route without taking ownership.
///
/// The adapter re-emits listener notifications as long as it is attached; the
/// route disposes only the adapter, never the underlying controller.
class TasbeehSessionScope extends ChangeNotifier {
  TasbeehSessionScope._(this._controller) {
    _controller.addListener(_forward);
  }

  final TasbeehController _controller;

  TasbeehState get state => _controller.state;
  List<TasbeehPhrase> get phrases => _controller.phrases;
  TasbeehController get controller => _controller;

  /// Creates an adapter over the application-scoped authority.
  static TasbeehSessionScope inheritAppScope() =>
      TasbeehSessionScope._(TasbeehAppScope.controller);

  Future<bool> increment() => _controller.increment();

  Future<void> resetSession() => _controller.resetSession();

  Future<void> decrement() => _controller.decrement();

  Future<void> selectDhikr(TasbeehPhrase phrase) =>
      _controller.selectDhikr(phrase);

  Future<TasbeehPhrase> addCustomPhrase(String text) =>
      _controller.addCustomPhrase(text);

  void _forward() => notifyListeners();

  @override
  void dispose() {
    _controller.removeListener(_forward);
    super.dispose();
  }
}
