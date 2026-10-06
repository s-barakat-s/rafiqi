import 'dart:collection';

import 'package:tasbeh/features/quran/application/mushaf/mushaf_page_index_mapper.dart';
import 'package:tasbeh/features/quran/application/mushaf/mushaf_prepared_page.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_rendering.dart';
import 'package:tasbeh/features/quran/domain/repositories/mushaf_layout_repository.dart';

enum MushafEngineEventType {
  initialized,
  cacheHit,
  cacheMiss,
  pagePrepared,
  pagePreparationFailed,
}

final class MushafEngineEvent {
  const MushafEngineEvent({
    required this.type,
    this.pageKey,
    this.elapsed = Duration.zero,
  });

  final MushafEngineEventType type;
  final MushafPageKey? pageKey;
  final Duration elapsed;
}

typedef MushafEngineObserver = void Function(MushafEngineEvent event);

final class MushafPagePreparationException implements Exception {
  const MushafPagePreparationException(this.message, {this.pageKey});

  final String message;
  final MushafPageKey? pageKey;

  @override
  String toString() => pageKey == null
      ? 'Mushaf page preparation failed: $message'
      : 'Mushaf page preparation failed for $pageKey: $message';
}

final class DefaultMushafEngine {
  DefaultMushafEngine({
    required MushafLayoutRepository layoutRepository,
    required MushafRendererAdapter renderer,
    this.forProduction = true,
    this.maxPreparedPages = 3,
    this.observer,
  }) : _layoutRepository = layoutRepository,
       _renderer = renderer {
    if (maxPreparedPages < 3) {
      throw ArgumentError.value(
        maxPreparedPages,
        'maxPreparedPages',
        'must hold current, previous, and next pages',
      );
    }
  }

  final MushafLayoutRepository _layoutRepository;
  final MushafRendererAdapter _renderer;
  final bool forProduction;
  final int maxPreparedPages;
  final MushafEngineObserver? observer;
  final LinkedHashMap<MushafPageKey, Future<MushafPreparedPage>> _cache =
      LinkedHashMap();

  Future<MushafEdition>? _initialization;
  MushafEdition? _edition;

  MushafEdition get edition {
    final value = _edition;
    if (value == null) throw StateError('Mushaf engine is not initialized');
    return value;
  }

  MushafPageIndexMapper get pageIndexMapper => MushafPageIndexMapper(
    editionId: edition.id,
    pageCount: edition.pageCount,
  );

  int get cachedPageCount => _cache.length;
  Set<MushafPageKey> get cachedPageKeys => Set.unmodifiable(_cache.keys);

  Future<MushafEdition> initialize() => _initialization ??= _initialize();

  Future<MushafEdition> _initialize() async {
    final stopwatch = Stopwatch()..start();
    try {
      final loadedEdition = await _layoutRepository.getEdition();
      MushafRendererActivationValidator.validate(
        edition: loadedEdition,
        renderer: _renderer,
        forProduction: forProduction,
      );
      await _renderer.initialize(loadedEdition);
      _edition = loadedEdition;
      observer?.call(
        MushafEngineEvent(
          type: MushafEngineEventType.initialized,
          elapsed: stopwatch.elapsed,
        ),
      );
      return loadedEdition;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<MushafPreparedPage> preparePage(MushafPageKey key) async {
    final loadedEdition = await initialize();
    _validatePageKey(key, loadedEdition);
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      observer?.call(
        MushafEngineEvent(type: MushafEngineEventType.cacheHit, pageKey: key),
      );
      return cached;
    }

    observer?.call(
      MushafEngineEvent(type: MushafEngineEventType.cacheMiss, pageKey: key),
    );
    final preparation = _preparePage(key, loadedEdition);
    _cache[key] = preparation;
    _evictOverflow();
    try {
      return await preparation;
    } catch (_) {
      if (identical(_cache[key], preparation)) _cache.remove(key);
      rethrow;
    }
  }

  Future<MushafPreparedPage> prepareWindow(MushafPageKey current) async {
    final prepared = await preparePage(current);
    final mapper = pageIndexMapper;
    final adjacent = [mapper.previousPage(current), mapper.nextPage(current)];
    for (final key in adjacent) {
      if (key != null) await preparePage(key);
    }
    final currentFuture = _cache.remove(current);
    if (currentFuture != null) _cache[current] = currentFuture;
    return prepared;
  }

  Future<MushafPreparedPage> _preparePage(
    MushafPageKey key,
    MushafEdition loadedEdition,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final results = await Future.wait<Object?>([
        _layoutRepository.getPage(key),
        _layoutRepository.getPageLines(key),
        _layoutRepository.getWordPlacements(key),
      ]);
      final page = results[0] as MushafPage?;
      if (page == null) {
        throw MushafPagePreparationException('page is missing', pageKey: key);
      }
      final lines = results[1] as List<MushafLine>;
      final placements = results[2] as List<MushafWordPlacement>;
      _validateStoragePage(key, lines, placements);

      final rendererPage = await _renderer.preparePage(
        MushafRenderRequest(
          edition: loadedEdition,
          page: page,
          lines: lines,
          placements: placements,
        ),
      );
      final prepared = _assemble(
        edition: loadedEdition,
        page: page,
        lines: lines,
        placements: placements,
        rendererPage: rendererPage,
      );
      observer?.call(
        MushafEngineEvent(
          type: MushafEngineEventType.pagePrepared,
          pageKey: key,
          elapsed: stopwatch.elapsed,
        ),
      );
      return prepared;
    } catch (error) {
      observer?.call(
        MushafEngineEvent(
          type: MushafEngineEventType.pagePreparationFailed,
          pageKey: key,
          elapsed: stopwatch.elapsed,
        ),
      );
      if (error is MushafPagePreparationException) rethrow;
      throw MushafPagePreparationException('$error', pageKey: key);
    }
  }

  static MushafPreparedPage _assemble({
    required MushafEdition edition,
    required MushafPage page,
    required List<MushafLine> lines,
    required List<MushafWordPlacement> placements,
    required MushafRendererPage rendererPage,
  }) {
    if (rendererPage.pageKey != page.key) {
      throw MushafPagePreparationException(
        'renderer returned a different page',
        pageKey: page.key,
      );
    }
    final rendererWords = <WordKey, MushafRenderWord>{};
    for (final word in rendererPage.words) {
      if (rendererWords.containsKey(word.wordKey)) {
        throw MushafPagePreparationException(
          'renderer returned duplicate WordKey ${word.wordKey}',
          pageKey: page.key,
        );
      }
      rendererWords[word.wordKey] = word;
    }
    final placementKeys = placements.map((value) => value.wordKey).toSet();
    if (rendererWords.keys.toSet().difference(placementKeys).isNotEmpty ||
        placementKeys.difference(rendererWords.keys.toSet()).isNotEmpty) {
      throw MushafPagePreparationException(
        'renderer word set does not match layout word set',
        pageKey: page.key,
      );
    }

    final placementsByLine = <int, List<MushafWordPlacement>>{};
    for (final placement in placements) {
      placementsByLine
          .putIfAbsent(placement.lineNumber, () => [])
          .add(placement);
    }
    return MushafPreparedPage(
      edition: edition,
      page: page,
      rendererPage: rendererPage,
      lines: List.unmodifiable(
        lines.map(
          (line) => MushafPreparedLine(
            line: line,
            words: List.unmodifiable(
              (placementsByLine[line.lineNumber] ?? const []).map(
                (placement) => MushafPreparedWord(
                  placement: placement,
                  rendererWord: rendererWords[placement.wordKey]!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _validateStoragePage(
    MushafPageKey key,
    List<MushafLine> lines,
    List<MushafWordPlacement> placements,
  ) {
    var expectedLine = 1;
    for (final line in lines) {
      if (line.pageKey != key || line.lineNumber != expectedLine++) {
        throw MushafPagePreparationException(
          'layout returned invalid line ordering',
          pageKey: key,
        );
      }
    }
    final nextPositionByLine = <int, int>{};
    for (final placement in placements) {
      final expected = nextPositionByLine[placement.lineNumber] ?? 1;
      if (placement.pageKey != key || placement.positionInLine != expected) {
        throw MushafPagePreparationException(
          'layout returned invalid word ordering',
          pageKey: key,
        );
      }
      if (!lines.any((line) => line.lineNumber == placement.lineNumber)) {
        throw MushafPagePreparationException(
          'layout word references a missing line',
          pageKey: key,
        );
      }
      nextPositionByLine[placement.lineNumber] = expected + 1;
    }
  }

  static void _validatePageKey(MushafPageKey key, MushafEdition edition) {
    if (key.mushafId != edition.id) {
      throw MushafPagePreparationException(
        'page belongs to another Mushaf edition',
        pageKey: key,
      );
    }
    if (key.pageNumber > edition.pageCount) {
      throw MushafPagePreparationException(
        'page is outside the edition range',
        pageKey: key,
      );
    }
  }

  void _evictOverflow() {
    while (_cache.length > maxPreparedPages) {
      _cache.remove(_cache.keys.first);
    }
  }

  Future<MushafPageKey?> pageForAyah(AyahKey key) =>
      _layoutRepository.getPageForAyah(key);

  Future<MushafPageKey?> pageForWord(WordKey key) =>
      _layoutRepository.getPageForWord(key);

  void clearPreparedPages() => _cache.clear();
}
