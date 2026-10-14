import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/quran/application/mushaf/mushaf_page_index_mapper.dart';
import 'package:tasbeh/features/quran/application/mushaf/qpc_v4_tajweed_pack_source.dart';
import 'package:tasbeh/features/quran/data/annotations/quran_annotation_store.dart';
import 'package:tasbeh/features/quran/domain/annotations/quran_annotation.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/qpc_v4_tajweed_pack.dart';

/// RESEARCH ONLY — renders the unapproved QPC V4 content pack in debug builds.
final class QpcV4TajweedReader extends StatefulWidget {
  const QpcV4TajweedReader({
    required this.source,
    required this.manifest,
    required this.initialPageNumber,
    super.key,
  });

  final QpcV4TajweedPackSource source;
  final QpcV4TajweedManifest manifest;
  final int initialPageNumber;

  @override
  State<QpcV4TajweedReader> createState() => _QpcV4TajweedReaderState();
}

enum _SelectionEndpoint { anchor, extent }

class _QpcV4TajweedReaderState extends State<QpcV4TajweedReader> {
  static const _darkShaderAsset = 'assets/shaders/qpc_tajweed_dark.frag';
  late final MushafPageIndexMapper _mapper;
  late final PageController _controller;
  Map<int, _QpcPageSlot> _window = const {};
  AyahKey? _anchorAyahKey;
  AyahKey? _extentAyahKey;
  WordKey? _wordAnchorKey;
  WordKey? _wordExtentKey;
  final _annotationStore = QuranAnnotationStore();
  List<QuranAnnotation> _annotations = const [];
  Object? _initialError;
  ui.FragmentProgram? _darkShaderProgram;
  late int _pageNumber;
  var _generation = 0;
  var _initializing = true;
  var _chromeVisible = false;
  var _wordHighlightMode = false;
  var _savingAnnotation = false;
  var _activeSelectionHandlePointers = 0;

  void _setSelectionHandlePointerActive(bool active) {
    if (!mounted) return;
    final nextCount = active
        ? _activeSelectionHandlePointers + 1
        : _activeSelectionHandlePointers > 0
        ? _activeSelectionHandlePointers - 1
        : 0;
    if (nextCount == _activeSelectionHandlePointers) return;
    setState(() => _activeSelectionHandlePointers = nextCount);
  }

  @override
  void initState() {
    super.initState();
    _mapper = MushafPageIndexMapper(
      editionId: qpcV4TajweedEditionId,
      pageCount: widget.manifest.pageCount,
    );
    final valid =
        widget.initialPageNumber >= 1 &&
        widget.initialPageNumber <= widget.manifest.pageCount;
    _pageNumber = valid ? widget.initialPageNumber : 1;
    _controller = PageController(
      initialPage: _mapper.viewIndexFor(
        MushafPageKey(qpcV4TajweedEditionId, _pageNumber),
      ),
    );
    _loadDarkShader();
    _loadAnnotations();
    _initialize(valid);
  }

  Future<void> _loadAnnotations() async {
    try {
      final annotations = await _annotationStore.load();
      if (!mounted) return;
      setState(() => _annotations = annotations);
    } on Object catch (error) {
      debugPrint('Quran annotations unavailable: $error');
    }
  }

  @override
  void dispose() {
    _generation++;
    for (final slot in _window.values) {
      slot.page?.image.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDarkShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(_darkShaderAsset);
      if (!mounted) return;
      setState(() => _darkShaderProgram = program);
    } on Object catch (error) {
      debugPrint('QPC dark-palette shader unavailable: $error');
    }
  }

  Future<void> _initialize(bool valid) async {
    final generation = ++_generation;
    if (!valid) {
      setState(() {
        _initializing = false;
        _initialError = RangeError.range(
          widget.initialPageNumber,
          1,
          widget.manifest.pageCount,
          'initialPageNumber',
        );
      });
      return;
    }
    try {
      widget.manifest.validateResearchPack();
      final window = await _prepareWindowMap(_pageNumber);
      if (!mounted || generation != _generation) {
        _disposePreparedPages(window, const {});
        return;
      }
      setState(() {
        _window = window;
        _initializing = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _initialError = error;
        _initializing = false;
      });
    }
  }

  Future<Map<int, _QpcPageSlot>> _prepareWindowMap(
    int current, {
    Map<int, _QpcPageSlot> reuse = const {},
  }) async {
    final numbers = <int>[
      if (current > 1) current - 1,
      current,
      if (current < widget.manifest.pageCount) current + 1,
    ];
    final prepared = <int, _QpcPageSlot>{};
    await Future.wait([
      for (final number in numbers)
        () async {
          final existing = reuse[number];
          if (existing?.page != null) {
            prepared[number] = existing!;
            return;
          }
          try {
            prepared[number] = _QpcPageSlot(
              page: await widget.source.loadPage(number),
            );
          } on Object catch (error) {
            prepared[number] = _QpcPageSlot(error: error);
          }
        }(),
    ]);
    return Map.unmodifiable(prepared);
  }

  Future<void> _prepareWindow(int current) async {
    final generation = ++_generation;
    final prepared = await _prepareWindowMap(current, reuse: _window);
    if (!mounted || generation != _generation) {
      _disposePreparedPages(prepared, _window);
      return;
    }
    final previous = _window;
    setState(() => _window = prepared);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disposePreparedPages(previous, prepared);
    });
  }

  void _disposePreparedPages(
    Map<int, _QpcPageSlot> candidates,
    Map<int, _QpcPageSlot> retained,
  ) {
    for (final entry in candidates.entries) {
      final page = entry.value.page;
      if (page != null && !identical(retained[entry.key]?.page, page)) {
        page.image.dispose();
      }
    }
  }

  void _onPageChanged(int index) {
    final key = _mapper.pageKeyForViewIndex(index);
    if (key.pageNumber == _pageNumber) return;
    _pageNumber = key.pageNumber;
    unawaited(_prepareWindow(key.pageNumber));
  }

  void _handleAyahTap(AyahKey? tappedAyah) {
    if (tappedAyah != null && _anchorAyahKey == null) return;
    setState(() {
      if (tappedAyah == null) {
        _anchorAyahKey = null;
        _extentAyahKey = null;
        _chromeVisible = !_chromeVisible;
        return;
      }
      _extentAyahKey = tappedAyah;
    });
  }

  void _handleWordTap(WordKey? tappedWord) {
    if (_wordHighlightMode) {
      setState(() {
        if (tappedWord == null) {
          _wordAnchorKey = null;
          _wordExtentKey = null;
        } else if (_wordAnchorKey == null) {
          _wordAnchorKey = tappedWord;
          _wordExtentKey = tappedWord;
        } else {
          _wordExtentKey = tappedWord;
        }
      });
      return;
    }
    if (tappedWord != null) {
      final matches = _annotations
          .where((annotation) => annotation.containsWord(tappedWord))
          .toList(growable: false);
      if (matches.isNotEmpty) {
        unawaited(_showAnnotationDetails(matches));
        return;
      }
    }
    _handleAyahTap(tappedWord?.ayahKey);
  }

  void _restartWordSelection(WordKey word) {
    if (!_wordHighlightMode) return;
    setState(() {
      _wordAnchorKey = word;
      _wordExtentKey = word;
    });
  }

  void _enterWordHighlightMode() {
    setState(() {
      _wordHighlightMode = true;
      _wordAnchorKey = null;
      _wordExtentKey = null;
      _anchorAyahKey = null;
      _extentAyahKey = null;
      _chromeVisible = false;
    });
  }

  void _cancelWordHighlightMode() {
    setState(() {
      _wordHighlightMode = false;
      _wordAnchorKey = null;
      _wordExtentKey = null;
    });
  }

  void _startSelection(AyahKey ayah) {
    setState(() {
      _wordHighlightMode = false;
      _wordAnchorKey = null;
      _wordExtentKey = null;
      _anchorAyahKey = ayah;
      _extentAyahKey = ayah;
    });
  }

  void _moveWordSelectionEndpoint(
    _SelectionEndpoint endpoint,
    WordKey word,
  ) {
    if (_wordAnchorKey == null || _wordExtentKey == null) return;
    final current = endpoint == _SelectionEndpoint.anchor
        ? _wordAnchorKey
        : _wordExtentKey;
    if (current == word) return;
    setState(() {
      if (endpoint == _SelectionEndpoint.anchor) {
        _wordAnchorKey = word;
      } else {
        _wordExtentKey = word;
      }
    });
  }

  void _moveSelectionEndpoint(_SelectionEndpoint endpoint, AyahKey ayah) {
    if (_anchorAyahKey == null || _extentAyahKey == null) return;
    final current = endpoint == _SelectionEndpoint.anchor
        ? _anchorAyahKey
        : _extentAyahKey;
    if (current == ayah) return;
    setState(() {
      if (endpoint == _SelectionEndpoint.anchor) {
        _anchorAyahKey = ayah;
      } else {
        _extentAyahKey = ayah;
      }
    });
  }

  int? _boundaryPageFor(AyahKey ayah, {required bool start}) {
    final pages = <int>[
      for (final entry in _window.entries)
        if (entry.value.page?.geometry.ayahRegions.any(
              (region) => region.key == ayah,
            ) ??
            false)
          entry.key,
    ]..sort();
    if (pages.isEmpty) return null;
    return start ? pages.first : pages.last;
  }

  int? _wordBoundaryPageFor(WordKey word, {required bool start}) {
    final pages = <int>[
      for (final entry in _window.entries)
        if (entry.value.page?.geometry.wordRegions.any(
              (region) => region.key == word,
            ) ??
            false)
          entry.key,
    ]..sort();
    if (pages.isEmpty) return null;
    return start ? pages.first : pages.last;
  }

  Future<void> _saveAyahSelection() async {
    final anchor = _anchorAyahKey;
    final extent = _extentAyahKey;
    if (anchor == null || extent == null) return;
    final saved = await _createAnnotation(
      granularity: QuranAnnotationGranularity.ayah,
      startIdentity: anchor.serialize(),
      endIdentity: extent.serialize(),
    );
    if (!saved || !mounted) return;
    setState(() {
      _anchorAyahKey = null;
      _extentAyahKey = null;
    });
  }

  Future<void> _saveWordSelection() async {
    final anchor = _wordAnchorKey;
    final extent = _wordExtentKey;
    if (anchor == null || extent == null) return;
    final saved = await _createAnnotation(
      granularity: QuranAnnotationGranularity.word,
      startIdentity: anchor.serialize(),
      endIdentity: extent.serialize(),
    );
    if (!saved || !mounted) return;
    _cancelWordHighlightMode();
  }

  Future<bool> _createAnnotation({
    required QuranAnnotationGranularity granularity,
    required String startIdentity,
    required String endIdentity,
  }) async {
    if (_annotations.length >=
        QuranAnnotationStore.maximumAnnotationsPerEdition) {
      _showMessage('بلغت الحد الأقصى: ٥٠٠ تمييز لهذه النسخة البحثية.');
      return false;
    }
    final edit = await _showAnnotationEditor(context);
    if (edit == null || !mounted) return false;
    final now = DateTime.now().toUtc();
    var id = 'qra-${now.microsecondsSinceEpoch.toRadixString(36)}';
    var suffix = 1;
    while (_annotations.any((annotation) => annotation.id == id)) {
      id = 'qra-${now.microsecondsSinceEpoch.toRadixString(36)}-${suffix++}';
    }
    final annotation = QuranAnnotation(
      id: id,
      editionId: qpcV4ResearchAnnotationEditionId,
      granularity: granularity,
      startIdentity: startIdentity,
      endIdentity: endIdentity,
      colorId: edit.colorId,
      comment: edit.comment,
      createdAt: now,
      lastModifiedAt: now,
    );
    return _persistAnnotations([..._annotations, annotation]);
  }

  Future<void> _editAnnotation(QuranAnnotation annotation) async {
    final edit = await _showAnnotationEditor(
      context,
      initialColor: annotation.colorId,
      initialComment: annotation.comment,
    );
    if (edit == null || !mounted) return;
    final replacement = annotation.copyWith(
      colorId: edit.colorId,
      comment: edit.comment,
      clearComment: edit.comment == null,
      lastModifiedAt: DateTime.now().toUtc(),
    );
    await _persistAnnotations([
      for (final value in _annotations)
        if (value.id == annotation.id) replacement else value,
    ]);
  }

  Future<void> _deleteAnnotation(QuranAnnotation annotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التمييز؟'),
        content: const Text('سيُحذف اللون والتعليق المحفوظان من هذا الجهاز.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _persistAnnotations([
      for (final value in _annotations)
        if (value.id != annotation.id) value,
    ], successMessage: 'حُذف التمييز.');
  }

  Future<bool> _persistAnnotations(
    List<QuranAnnotation> annotations, {
    String successMessage = 'حُفظ التمييز على هذا الجهاز.',
  }) async {
    if (_savingAnnotation) return false;
    setState(() => _savingAnnotation = true);
    try {
      await _annotationStore.save(annotations);
      if (!mounted) return true;
      setState(() => _annotations = List.unmodifiable(annotations));
      _showMessage(successMessage);
      return true;
    } on Object catch (error) {
      debugPrint('Unable to save Quran annotation: $error');
      if (mounted) _showMessage('تعذر حفظ التمييز. حاول مرة أخرى.');
      return false;
    } finally {
      if (mounted) setState(() => _savingAnnotation = false);
    }
  }

  Future<void> _showAnnotationDetails(
    List<QuranAnnotation> annotations,
  ) async {
    final selected = await showModalBottomSheet<_AnnotationAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              annotations.length == 1
                  ? 'تفاصيل التمييز'
                  : 'التمييزات المتداخلة (${annotations.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final annotation in annotations)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _highlightColor(annotation.colorId),
                    child: const Icon(Icons.format_color_fill_rounded),
                  ),
                  title: Text(
                    annotation.granularity == QuranAnnotationGranularity.ayah
                        ? 'تمييز آيات'
                        : 'تمييز كلمات',
                  ),
                  subtitle: Text(
                    annotation.comment?.isNotEmpty == true
                        ? annotation.comment!
                        : 'بلا تعليق',
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'تعديل',
                        onPressed: () => Navigator.pop(
                          context,
                          _AnnotationAction(annotation, delete: false),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'حذف',
                        onPressed: () => Navigator.pop(
                          context,
                          _AnnotationAction(annotation, delete: true),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (selected.delete) {
      await _deleteAnnotation(selected.annotation);
    } else {
      await _editAnnotation(selected.annotation);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: brightness,
      systemNavigationBarColor: colors.background,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
    );
    late final Widget content;
    if (_initializing) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_initialError != null) {
      content = const _QpcMessage('تعذر فتح حزمة QPC البحثية المحلية.');
    } else {
      final anchor = _anchorAyahKey;
      final extent = _extentAyahKey;
      final anchorStarts =
          anchor != null && extent != null && anchor.compareTo(extent) <= 0;
      final selectionStart = anchorStarts ? anchor : extent;
      final selectionEnd = anchorStarts ? extent : anchor;
      final startHandleEndpoint = anchorStarts
          ? _SelectionEndpoint.anchor
          : _SelectionEndpoint.extent;
      final endHandleEndpoint = anchorStarts
          ? _SelectionEndpoint.extent
          : _SelectionEndpoint.anchor;
      final startBoundaryPage = selectionStart == null
          ? null
          : _boundaryPageFor(selectionStart, start: true);
      final endBoundaryPage = selectionEnd == null
          ? null
          : _boundaryPageFor(selectionEnd, start: false);
      final wordAnchor = _wordAnchorKey;
      final wordExtent = _wordExtentKey;
      final wordAnchorStarts =
          wordAnchor != null &&
          wordExtent != null &&
          wordAnchor.compareTo(wordExtent) <= 0;
      final wordSelectionStart = wordAnchorStarts ? wordAnchor : wordExtent;
      final wordSelectionEnd = wordAnchorStarts ? wordExtent : wordAnchor;
      final wordStartHandleEndpoint = wordAnchorStarts
          ? _SelectionEndpoint.anchor
          : _SelectionEndpoint.extent;
      final wordEndHandleEndpoint = wordAnchorStarts
          ? _SelectionEndpoint.extent
          : _SelectionEndpoint.anchor;
      final wordStartBoundaryPage = wordSelectionStart == null
          ? null
          : _wordBoundaryPageFor(wordSelectionStart, start: true);
      final wordEndBoundaryPage = wordSelectionEnd == null
          ? null
          : _wordBoundaryPageFor(wordSelectionEnd, start: false);
      final ayahSelectionActive = anchor != null && extent != null;
      final toolbarMode = _wordHighlightMode
          ? _MushafToolbarMode.wordHighlight
          : ayahSelectionActive
          ? _MushafToolbarMode.ayahSelection
          : _MushafToolbarMode.reading;
      final toolbarVisible =
          _wordHighlightMode || ayahSelectionActive || _chromeVisible;
      content = Stack(
        fit: StackFit.expand,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: PageView.builder(
              controller: _controller,
              itemCount: _mapper.pageCount,
              allowImplicitScrolling: true,
              physics: _activeSelectionHandlePointers > 0
                  ? const NeverScrollableScrollPhysics()
                  : null,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final key = _mapper.pageKeyForViewIndex(index);
                final slot = _window[key.pageNumber];
                if (slot == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (slot.page == null || slot.error != null) {
                  return const _QpcMessage('تعذر تجهيز صفحة المصحف البحثية.');
                }
                return _FullScreenMushafLayout(
                  page: slot.page!,
                  darkShaderProgram: _darkShaderProgram,
                  anchorAyahKey: _anchorAyahKey,
                  extentAyahKey: _extentAyahKey,
                  wordAnchorKey: _wordAnchorKey,
                  wordExtentKey: _wordExtentKey,
                  wordHighlightMode: _wordHighlightMode,
                  annotations: _annotations,
                  onTapAyah: _handleAyahTap,
                  onTapWord: _handleWordTap,
                  onLongPressWord: _restartWordSelection,
                  onLongPressAyah: _startSelection,
                  startHandleEndpoint: key.pageNumber == startBoundaryPage
                      ? startHandleEndpoint
                      : null,
                  endHandleEndpoint: key.pageNumber == endBoundaryPage
                      ? endHandleEndpoint
                      : null,
                  onMoveSelectionEndpoint: _moveSelectionEndpoint,
                  wordStartHandleEndpoint:
                      key.pageNumber == wordStartBoundaryPage
                      ? wordStartHandleEndpoint
                      : null,
                  wordEndHandleEndpoint: key.pageNumber == wordEndBoundaryPage
                      ? wordEndHandleEndpoint
                      : null,
                  onMoveWordSelectionEndpoint: _moveWordSelectionEndpoint,
                  onHandlePointerActiveChanged:
                      _setSelectionHandlePointerActive,
                );
              },
            ),
          ),
          IgnorePointer(
            ignoring: !toolbarVisible,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              offset: toolbarVisible ? Offset.zero : const Offset(0, .18),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: toolbarVisible ? 1 : 0,
                child: _MushafBottomToolbar(
                  mode: toolbarMode,
                  saving: _savingAnnotation,
                  canSaveWordSelection:
                      _wordAnchorKey != null && _wordExtentKey != null,
                  onBack: () => Navigator.of(context).maybePop(),
                  onEnterWordHighlightMode: _enterWordHighlightMode,
                  onSaveAyahSelection: _saveAyahSelection,
                  onCancelWordHighlightMode: _cancelWordHighlightMode,
                  onSaveWordSelection: _saveWordSelection,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: ColoredBox(color: colors.background, child: content),
    );
  }
}

final class _QpcPageSlot {
  const _QpcPageSlot({this.page, this.error});
  final QpcPreparedPage? page;
  final Object? error;
}

final class _FullScreenMushafLayout extends StatelessWidget {
  const _FullScreenMushafLayout({
    required this.page,
    required this.darkShaderProgram,
    required this.anchorAyahKey,
    required this.extentAyahKey,
    required this.wordAnchorKey,
    required this.wordExtentKey,
    required this.wordHighlightMode,
    required this.annotations,
    required this.onTapAyah,
    required this.onTapWord,
    required this.onLongPressWord,
    required this.onLongPressAyah,
    required this.startHandleEndpoint,
    required this.endHandleEndpoint,
    required this.onMoveSelectionEndpoint,
    required this.wordStartHandleEndpoint,
    required this.wordEndHandleEndpoint,
    required this.onMoveWordSelectionEndpoint,
    required this.onHandlePointerActiveChanged,
  });

  final QpcPreparedPage page;
  final ui.FragmentProgram? darkShaderProgram;
  final AyahKey? anchorAyahKey;
  final AyahKey? extentAyahKey;
  final WordKey? wordAnchorKey;
  final WordKey? wordExtentKey;
  final bool wordHighlightMode;
  final List<QuranAnnotation> annotations;
  final ValueChanged<AyahKey?> onTapAyah;
  final ValueChanged<WordKey?> onTapWord;
  final ValueChanged<WordKey> onLongPressWord;
  final ValueChanged<AyahKey> onLongPressAyah;
  final _SelectionEndpoint? startHandleEndpoint;
  final _SelectionEndpoint? endHandleEndpoint;
  final void Function(_SelectionEndpoint endpoint, AyahKey ayah)
  onMoveSelectionEndpoint;
  final _SelectionEndpoint? wordStartHandleEndpoint;
  final _SelectionEndpoint? wordEndHandleEndpoint;
  final void Function(_SelectionEndpoint endpoint, WordKey word)
  onMoveWordSelectionEndpoint;
  final ValueChanged<bool> onHandlePointerActiveChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final requestedDark = Theme.of(context).brightness == Brightness.dark;
    final dark = requestedDark && darkShaderProgram != null;
    final paperColor = dark
        ? colors.surface
        : requestedDark
        ? AppPalette.rafiqiLightCardSurface
        : colors.surface;
    final inkColor = requestedDark && !dark
        ? AppPalette.rafiqiLightPrimary
        : colors.textPrimary;
    final highlightColor = requestedDark && !dark
        ? AppPalette.rafiqiLightPrimary
        : colors.primary;
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final safeInsets = MediaQuery.paddingOf(context);
        final mushafLayout = _MinimalMushafLayout.calculate(size, safeInsets);
        final qpcTransform = QpcPageTransform.fit(
          sourceRect: _QpcPageViewport.displaySourceRectFor(page),
          viewportRect: mushafLayout.quranViewportRect,
          nonUniform: true,
        );
        AyahKey? ayahAtPosition(Offset position) =>
            page.geometry.ayahAt(qpcTransform.toCanonical(position));
        WordKey? wordAtPosition(Offset position) {
          final point = qpcTransform.toCanonical(position);
          for (final word in page.geometry.wordRegions) {
            if (word.bounds.rect.contains(point)) return word.key;
          }
          return null;
        }
        return Semantics(
          label:
              'صفحة ${ArabicNumerals.integer(page.geometry.pageNumber, groupThousands: false)}، '
              'سورة ${page.primarySurah.nameArabic}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final word = wordAtPosition(details.localPosition);
              if (word != null || wordHighlightMode) {
                onTapWord(word);
              } else {
                onTapAyah(ayahAtPosition(details.localPosition));
              }
            },
            onLongPressStart: (details) {
              if (wordHighlightMode) {
                final word = wordAtPosition(details.localPosition);
                if (word != null) onLongPressWord(word);
                return;
              }
              final ayah = ayahAtPosition(details.localPosition);
              if (ayah != null) onLongPressAyah(ayah);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: paperColor),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _SavedAnnotationPainter(
                      annotations: annotations,
                      geometry: page.geometry,
                      transform: qpcTransform,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: AyahHighlightPainter(
                      ayahRegions: page.geometry.ayahRegions,
                      anchorAyahKey: anchorAyahKey,
                      extentAyahKey: extentAyahKey,
                      color: highlightColor,
                      transform: qpcTransform,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _WordSelectionPainter(
                      wordRegions: page.geometry.wordRegions,
                      anchorWordKey: wordAnchorKey,
                      extentWordKey: wordExtentKey,
                      color: highlightColor,
                      transform: qpcTransform,
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: RepaintBoundary(
                    child: _QpcPageViewport(
                      image: page.image,
                      imageRect: page.geometry.imageRect,
                      transform: qpcTransform,
                      darkShaderProgram: dark ? darkShaderProgram : null,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: _MushafSemanticOverlay(
                    words: page.geometry.wordRegions,
                    markers: page.geometry.ayahMarkerRegions,
                    transform: qpcTransform,
                    onTapAyah: onTapAyah,
                    onTapWord: onTapWord,
                    onLongPressWord: onLongPressWord,
                    onLongPressAyah: onLongPressAyah,
                    wordHighlightMode: wordHighlightMode,
                  ),
                ),
                _SelectionHandlesOverlay(
                  geometry: page.geometry,
                  anchorAyahKey: anchorAyahKey,
                  extentAyahKey: extentAyahKey,
                  startHandleEndpoint: startHandleEndpoint,
                  endHandleEndpoint: endHandleEndpoint,
                  color: highlightColor,
                  transform: qpcTransform,
                  onMoveSelectionEndpoint: onMoveSelectionEndpoint,
                  onHandlePointerActiveChanged:
                      onHandlePointerActiveChanged,
                ),
                _WordSelectionHandlesOverlay(
                  geometry: page.geometry,
                  anchorWordKey: wordAnchorKey,
                  extentWordKey: wordExtentKey,
                  startHandleEndpoint: wordStartHandleEndpoint,
                  endHandleEndpoint: wordEndHandleEndpoint,
                  color: highlightColor,
                  transform: qpcTransform,
                  onMoveSelectionEndpoint: onMoveWordSelectionEndpoint,
                  onHandlePointerActiveChanged:
                      onHandlePointerActiveChanged,
                ),
                _MinimalMushafFooter(
                  surahName: page.primarySurah.nameArabic,
                  pageNumber: page.geometry.pageNumber,
                  juzNumber: page.juzNumber,
                  backgroundColor: paperColor,
                  textColor: inkColor,
                  safeInsets: safeInsets,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

@immutable
final class _MinimalMushafLayout {
  const _MinimalMushafLayout({required this.quranViewportRect});

  factory _MinimalMushafLayout.calculate(Size size, EdgeInsets safeInsets) {
    return _MinimalMushafLayout(
      quranViewportRect: Rect.fromLTRB(
        safeInsets.left,
        safeInsets.top,
        size.width - safeInsets.right,
        size.height - safeInsets.bottom,
      ),
    );
  }

  final Rect quranViewportRect;
}

final class _MinimalMushafFooter extends StatelessWidget {
  const _MinimalMushafFooter({
    required this.surahName,
    required this.pageNumber,
    required this.juzNumber,
    required this.backgroundColor,
    required this.textColor,
    required this.safeInsets,
  });

  static const height = 22.0;

  final String surahName;
  final int pageNumber;
  final int juzNumber;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsets safeInsets;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: safeInsets.bottom,
    height: height,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: .92),
          border: Border(
            top: BorderSide(
              color: AppPalette.rafiqiLightPrimary.withValues(alpha: .55),
              width: .75,
            ),
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: textColor.withValues(alpha: .82),
            fontFamily: AppFonts.thmanyahSans,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: safeInsets.left + 8,
                  right: safeInsets.right + 8,
                ),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Expanded(
                      child: Text(
                        'الجزء ${ArabicNumerals.integer(juzNumber, groupThousands: false)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        textScaler: TextScaler.noScaling,
                      ),
                    ),
                    const SizedBox(width: 56),
                    Expanded(
                      child: Text(
                        'سورة $surahName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        textScaler: TextScaler.noScaling,
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Text(
                  ArabicNumerals.integer(pageNumber, groupThousands: false),
                  textScaler: TextScaler.noScaling,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

@immutable
final class QpcPageTransform {
  const QpcPageTransform({
    required this.sourceRect,
    required this.destinationRect,
    required this.scaleX,
    required this.scaleY,
  });

  factory QpcPageTransform.fit({
    required Rect sourceRect,
    required Rect viewportRect,
    required bool nonUniform,
  }) {
    if (nonUniform) {
      return QpcPageTransform(
        sourceRect: sourceRect,
        destinationRect: viewportRect,
        scaleX: viewportRect.width / sourceRect.width,
        scaleY: viewportRect.height / sourceRect.height,
      );
    }
    final scale = math.min(
      viewportRect.width / sourceRect.width,
      viewportRect.height / sourceRect.height,
    );
    final size = Size(sourceRect.width * scale, sourceRect.height * scale);
    final destination = Rect.fromCenter(
      center: viewportRect.center,
      width: size.width,
      height: size.height,
    );
    return QpcPageTransform(
      sourceRect: sourceRect,
      destinationRect: destination,
      scaleX: scale,
      scaleY: scale,
    );
  }

  final Rect sourceRect;
  final Rect destinationRect;
  final double scaleX;
  final double scaleY;
  Offset toScreen(Offset point) => Offset(
    destinationRect.left + (point.dx - sourceRect.left) * scaleX,
    destinationRect.top + (point.dy - sourceRect.top) * scaleY,
  );

  Offset toCanonical(Offset point) => Offset(
    sourceRect.left + (point.dx - destinationRect.left) / scaleX,
    sourceRect.top + (point.dy - destinationRect.top) / scaleY,
  );

  Rect rectToScreen(Rect rect) =>
      Rect.fromPoints(toScreen(rect.topLeft), toScreen(rect.bottomRight));
}

final class _MushafSemanticOverlay extends StatelessWidget {
  const _MushafSemanticOverlay({
    required this.words,
    required this.markers,
    required this.transform,
    required this.onTapAyah,
    required this.onTapWord,
    required this.onLongPressWord,
    required this.onLongPressAyah,
    required this.wordHighlightMode,
  });

  final List<QpcWordRegion> words;
  final List<QpcAyahMarkerRegion> markers;
  final QpcPageTransform transform;
  final ValueChanged<AyahKey?> onTapAyah;
  final ValueChanged<WordKey?> onTapWord;
  final ValueChanged<WordKey> onLongPressWord;
  final ValueChanged<AyahKey> onLongPressAyah;
  final bool wordHighlightMode;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final word in words)
        Positioned.fromRect(
          rect: transform.rectToScreen(word.bounds.rect),
          child: Semantics(
            button: true,
            label:
                'الكلمة ${word.key.wordNumber} من الآية '
                '${word.key.ayahNumber}',
            onLongPress: wordHighlightMode
                ? () => onLongPressWord(word.key)
                : () => onLongPressAyah(word.key.ayahKey),
            onTap: () => onTapWord(word.key),
            child: const SizedBox.expand(),
          ),
        ),
      for (final marker in markers)
        Positioned.fromRect(
          rect: transform.rectToScreen(marker.bounds.rect),
          child: Semantics(
            button: true,
            label: 'علامة الآية ${marker.key.ayahNumber}',
            onLongPress: wordHighlightMode
                ? null
                : () => onLongPressAyah(marker.key),
            onTap: wordHighlightMode ? null : () => onTapAyah(marker.key),
            child: const SizedBox.expand(),
          ),
        ),
    ],
  );
}

enum _SelectionHandleRole { start, end }

final class _SelectionHandlesOverlay extends StatelessWidget {
  const _SelectionHandlesOverlay({
    required this.geometry,
    required this.anchorAyahKey,
    required this.extentAyahKey,
    required this.startHandleEndpoint,
    required this.endHandleEndpoint,
    required this.color,
    required this.transform,
    required this.onMoveSelectionEndpoint,
    required this.onHandlePointerActiveChanged,
  });

  final QpcPageGeometry geometry;
  final AyahKey? anchorAyahKey;
  final AyahKey? extentAyahKey;
  final _SelectionEndpoint? startHandleEndpoint;
  final _SelectionEndpoint? endHandleEndpoint;
  final Color color;
  final QpcPageTransform transform;
  final void Function(_SelectionEndpoint endpoint, AyahKey ayah)
  onMoveSelectionEndpoint;
  final ValueChanged<bool> onHandlePointerActiveChanged;

  @override
  Widget build(BuildContext context) {
    final anchor = anchorAyahKey;
    final extent = extentAyahKey;
    if (anchor == null || extent == null) return const SizedBox.shrink();
    final anchorStarts = anchor.compareTo(extent) <= 0;
    final startKey = anchorStarts ? anchor : extent;
    final endKey = anchorStarts ? extent : anchor;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (startHandleEndpoint case final endpoint?)
          if (_regionFor(startKey) case final region?)
            if (region.lineBounds.isNotEmpty)
              _buildHandle(
                role: _SelectionHandleRole.start,
                endpoint: endpoint,
                segment: transform.rectToScreen(region.lineBounds.first.rect),
              ),
        if (endHandleEndpoint case final endpoint?)
          if (_regionFor(endKey) case final region?)
            if (region.lineBounds.isNotEmpty)
              _buildHandle(
                role: _SelectionHandleRole.end,
                endpoint: endpoint,
                segment: transform.rectToScreen(region.lineBounds.last.rect),
              ),
      ],
    );
  }

  QpcAyahRegion? _regionFor(AyahKey key) {
    for (final region in geometry.ayahRegions) {
      if (region.key == key) return region;
    }
    return null;
  }

  Widget _buildHandle({
    required _SelectionHandleRole role,
    required _SelectionEndpoint endpoint,
    required Rect segment,
  }) {
    final handle = _SelectionHandleGeometry.fromSegment(segment, role);
    return Positioned.fromRect(
      key: ValueKey(endpoint),
      rect: handle.hitRect,
      child: _SelectionDragHandle(
        handle: handle,
        role: role,
        color: color,
        semanticsLabel: role == _SelectionHandleRole.start
            ? 'مقبض بداية التحديد'
            : 'مقبض نهاية التحديد',
        onPointerActiveChanged: onHandlePointerActiveChanged,
        onDragPagePosition: (pagePoint) {
          final ayah = _nearestAyah(
            geometry,
            transform.toCanonical(pagePoint),
          );
          if (ayah != null) onMoveSelectionEndpoint(endpoint, ayah);
        },
      ),
    );
  }
}

@immutable
final class _SelectionHandleGeometry {
  const _SelectionHandleGeometry({
    required this.hitRect,
    required this.stemTop,
    required this.stemBottom,
  });

  factory _SelectionHandleGeometry.fromSegment(
    Rect segment,
    _SelectionHandleRole role,
  ) {
    const knobRadius = 6.0;
    const minimumTouchTarget = 48.0;
    final x = role == _SelectionHandleRole.start ? segment.right : segment.left;
    final stemTop = Offset(x, segment.top);
    final stemBottom = Offset(x, segment.bottom);
    final visualBounds = Rect.fromLTRB(
      x - knobRadius,
      segment.top - knobRadius,
      x + knobRadius,
      segment.bottom + knobRadius,
    );
    return _SelectionHandleGeometry(
      hitRect: Rect.fromCenter(
        center: visualBounds.center,
        width: math.max(minimumTouchTarget, visualBounds.width),
        height: math.max(minimumTouchTarget, visualBounds.height),
      ),
      stemTop: stemTop,
      stemBottom: stemBottom,
    );
  }

  final Rect hitRect;
  final Offset stemTop;
  final Offset stemBottom;
}

final class _SelectionDragHandle extends StatefulWidget {
  const _SelectionDragHandle({
    required this.handle,
    required this.role,
    required this.color,
    required this.semanticsLabel,
    required this.onPointerActiveChanged,
    required this.onDragPagePosition,
  });

  final _SelectionHandleGeometry handle;
  final _SelectionHandleRole role;
  final Color color;
  final String semanticsLabel;
  final ValueChanged<bool> onPointerActiveChanged;
  final ValueChanged<Offset> onDragPagePosition;

  @override
  State<_SelectionDragHandle> createState() => _SelectionDragHandleState();
}

final class _SelectionDragHandleState extends State<_SelectionDragHandle> {
  Offset? _dragStartPointer;
  Offset? _dragStartHandlePosition;
  Offset _accumulatedPointerDelta = Offset.zero;
  var _pointerActive = false;

  void _capturePointer(PointerDownEvent event) {
    if (_pointerActive) return;
    _pointerActive = true;
    widget.onPointerActiveChanged(true);
  }

  void _releasePointer() {
    if (!_pointerActive) return;
    _pointerActive = false;
    widget.onPointerActiveChanged(false);
  }

  void _startDrag(DragStartDetails details) {
    _dragStartPointer = details.localPosition;
    _dragStartHandlePosition = widget.role == _SelectionHandleRole.start
        ? widget.handle.stemTop
        : widget.handle.stemBottom;
    _accumulatedPointerDelta = Offset.zero;
  }

  void _updateDrag(DragUpdateDetails details) {
    final startPointer = _dragStartPointer;
    final startHandlePosition = _dragStartHandlePosition;
    if (startPointer == null || startHandlePosition == null) return;
    _accumulatedPointerDelta += details.delta;
    final currentPointer = startPointer + _accumulatedPointerDelta;
    final movement = currentPointer - startPointer;
    if (movement == Offset.zero) return;
    widget.onDragPagePosition(startHandlePosition + movement);
  }

  void _finishDrag() {
    _dragStartPointer = null;
    _dragStartHandlePosition = null;
    _accumulatedPointerDelta = Offset.zero;
    _releasePointer();
  }

  @override
  void dispose() {
    if (_pointerActive) {
      _pointerActive = false;
      final releasePointer = widget.onPointerActiveChanged;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => releasePointer(false),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticsLabel,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _capturePointer,
      onPointerUp: (_) => _releasePointer(),
      onPointerCancel: (_) => _releasePointer(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        onLongPress: () {},
        onPanStart: _startDrag,
        onPanUpdate: _updateDrag,
        onPanEnd: (_) => _finishDrag(),
        onPanCancel: _finishDrag,
        child: CustomPaint(
          painter: _SelectionHandlePainter(
            role: widget.role,
            color: widget.color,
            stemTop: widget.handle.stemTop - widget.handle.hitRect.topLeft,
            stemBottom:
                widget.handle.stemBottom - widget.handle.hitRect.topLeft,
          ),
        ),
      ),
    ),
  );
}

final class _SelectionHandlePainter extends CustomPainter {
  const _SelectionHandlePainter({
    required this.role,
    required this.color,
    required this.stemTop,
    required this.stemBottom,
  });

  final _SelectionHandleRole role;
  final Color color;
  final Offset stemTop;
  final Offset stemBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(stemTop, stemBottom, paint);
    canvas.drawCircle(
      role == _SelectionHandleRole.start ? stemTop : stemBottom,
      6,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SelectionHandlePainter old) =>
      old.role != role ||
      old.color != color ||
      old.stemTop != stemTop ||
      old.stemBottom != stemBottom;
}

AyahKey? _nearestAyah(QpcPageGeometry geometry, Offset point) {
  AyahKey? nearest;
  var nearestDistance = double.infinity;
  for (final ayah in geometry.ayahRegions) {
    for (final line in ayah.lineBounds) {
      final distance = _squaredDistanceToRect(point, line.rect);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = ayah.key;
      }
    }
  }
  return nearest;
}

double _squaredDistanceToRect(Offset point, Rect bounds) {
  final dx = point.dx < bounds.left
      ? bounds.left - point.dx
      : point.dx > bounds.right
      ? point.dx - bounds.right
      : 0.0;
  final dy = point.dy < bounds.top
      ? bounds.top - point.dy
      : point.dy > bounds.bottom
      ? point.dy - bounds.bottom
      : 0.0;
  return dx * dx + dy * dy;
}

final class _QpcPageViewport extends StatelessWidget {
  const _QpcPageViewport({
    required this.image,
    required this.imageRect,
    required this.transform,
    this.darkShaderProgram,
  });

  static const _stableDisplaySourceRect = Rect.fromLTRB(90, 70, 1110, 1660);
  static const _phoneNativeTopTrim = 72.0;

  static Rect displaySourceRectFor(QpcPreparedPage page) {
    if (!page.geometry.phoneNativeLayout) return _stableDisplaySourceRect;
    final canonicalRect = page.geometry.canonicalRect;
    final displayTop = math.min(
      page.geometry.imageRect.top,
      canonicalRect.top + _phoneNativeTopTrim,
    );
    return Rect.fromLTRB(
      canonicalRect.left,
      math.max(canonicalRect.top, displayTop),
      canonicalRect.right,
      canonicalRect.bottom,
    );
  }

  final ui.Image image;
  final Rect imageRect;
  final QpcPageTransform transform;
  final ui.FragmentProgram? darkShaderProgram;

  @override
  Widget build(BuildContext context) {
    final program = darkShaderProgram;
    if (program == null) {
      return CustomPaint(
        painter: _QpcLightPagePainter(
          image: image,
          imageRect: imageRect,
          transform: transform,
        ),
      );
    }
    return _DarkQpcPageImage(
      image: image,
      imageRect: imageRect,
      program: program,
      transform: transform,
    );
  }
}

final class _QpcLightPagePainter extends CustomPainter {
  const _QpcLightPagePainter({
    required this.image,
    required this.imageRect,
    required this.transform,
  });

  final ui.Image image;
  final Rect imageRect;
  final QpcPageTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    final visibleImageRect = imageRect.intersect(transform.sourceRect);
    if (visibleImageRect.isEmpty) return;
    final source = Rect.fromLTWH(
      visibleImageRect.left - imageRect.left,
      visibleImageRect.top - imageRect.top,
      visibleImageRect.width,
      visibleImageRect.height,
    );
    canvas.drawImageRect(
      image,
      source,
      transform.rectToScreen(visibleImageRect),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_QpcLightPagePainter old) =>
      !identical(old.image, image) ||
      old.imageRect != imageRect ||
      old.transform != transform;
}

final class _DarkQpcPageImage extends StatefulWidget {
  const _DarkQpcPageImage({
    required this.image,
    required this.imageRect,
    required this.program,
    required this.transform,
  });

  final ui.Image image;
  final Rect imageRect;
  final ui.FragmentProgram program;
  final QpcPageTransform transform;

  @override
  State<_DarkQpcPageImage> createState() => _DarkQpcPageImageState();
}

class _DarkQpcPageImageState extends State<_DarkQpcPageImage> {
  late ui.FragmentShader _shader = widget.program.fragmentShader();

  @override
  void didUpdateWidget(_DarkQpcPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.program, widget.program)) {
      _shader.dispose();
      _shader = widget.program.fragmentShader();
    }
  }

  @override
  void dispose() {
    _shader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _QpcDarkPalettePainter(
      image: widget.image,
      imageRect: widget.imageRect,
      shader: _shader,
      transform: widget.transform,
    ),
  );
}

final class _QpcDarkPalettePainter extends CustomPainter {
  const _QpcDarkPalettePainter({
    required this.image,
    required this.imageRect,
    required this.shader,
    required this.transform,
  });

  final ui.Image image;
  final Rect imageRect;
  final ui.FragmentShader shader;
  final QpcPageTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, image.width.toDouble())
      ..setFloat(1, image.height.toDouble())
      ..setImageSampler(0, image);
    canvas
      ..save()
      ..clipRect(transform.destinationRect)
      ..translate(
        transform.destinationRect.left -
            transform.sourceRect.left * transform.scaleX,
        transform.destinationRect.top -
            transform.sourceRect.top * transform.scaleY,
      )
      ..scale(transform.scaleX, transform.scaleY)
      ..translate(imageRect.left, imageRect.top)
      ..drawRect(
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        Paint()..shader = shader,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_QpcDarkPalettePainter oldDelegate) =>
      !identical(oldDelegate.image, image) ||
      oldDelegate.imageRect != imageRect ||
      !identical(oldDelegate.shader, shader) ||
      oldDelegate.transform != transform;
}

final class AyahHighlightPainter extends CustomPainter {
  const AyahHighlightPainter({
    required this.ayahRegions,
    required this.anchorAyahKey,
    required this.extentAyahKey,
    required this.color,
    required this.transform,
  });

  final List<QpcAyahRegion> ayahRegions;
  final AyahKey? anchorAyahKey;
  final AyahKey? extentAyahKey;
  final Color color;
  final QpcPageTransform transform;

  AyahKey? get selected => extentAyahKey;

  List<Rect> get highlightRects {
    final anchor = anchorAyahKey;
    final extent = extentAyahKey;
    if (anchor == null || extent == null) return const [];
    final start = anchor.compareTo(extent) <= 0 ? anchor : extent;
    final end = anchor.compareTo(extent) <= 0 ? extent : anchor;
    return [
      for (final region in ayahRegions)
        if (region.key.compareTo(start) >= 0 && region.key.compareTo(end) <= 0)
          for (final bounds in region.lineBounds)
            transform.rectToScreen(bounds.rect.inflate(5)),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (anchorAyahKey == null || extentAyahKey == null) return;
    final paint = Paint()..color = color.withValues(alpha: .16);
    for (final rect in highlightRects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.elliptical(8 * transform.scaleX, 8 * transform.scaleY),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(AyahHighlightPainter old) =>
      old.anchorAyahKey != anchorAyahKey ||
      old.extentAyahKey != extentAyahKey ||
      old.color != color ||
      old.ayahRegions != ayahRegions ||
      old.transform != transform;
}

final class _WordSelectionPainter extends CustomPainter {
  const _WordSelectionPainter({
    required this.wordRegions,
    required this.anchorWordKey,
    required this.extentWordKey,
    required this.color,
    required this.transform,
  });

  final List<QpcWordRegion> wordRegions;
  final WordKey? anchorWordKey;
  final WordKey? extentWordKey;
  final Color color;
  final QpcPageTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    final anchor = anchorWordKey;
    final extent = extentWordKey;
    if (anchor == null || extent == null) return;
    final start = anchor.compareTo(extent) <= 0 ? anchor : extent;
    final end = anchor.compareTo(extent) <= 0 ? extent : anchor;
    final rects = <Rect>[
      for (final region in wordRegions)
        if (region.key.compareTo(start) >= 0 && region.key.compareTo(end) <= 0)
          transform.rectToScreen(region.bounds.rect.inflate(2)),
    ];
    final paint = Paint()..color = color.withValues(alpha: .2);
    for (final rect in _mergeAdjacentWordRects(rects)) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WordSelectionPainter old) =>
      old.wordRegions != wordRegions ||
      old.anchorWordKey != anchorWordKey ||
      old.extentWordKey != extentWordKey ||
      old.color != color ||
      old.transform != transform;
}

final class _SavedAnnotationPainter extends CustomPainter {
  const _SavedAnnotationPainter({
    required this.annotations,
    required this.geometry,
    required this.transform,
  });

  final List<QuranAnnotation> annotations;
  final QpcPageGeometry geometry;
  final QpcPageTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      final paint = Paint()
        ..color = _highlightColor(annotation.colorId).withValues(alpha: .32);
      late final List<Rect> rects;
      if (annotation.granularity == QuranAnnotationGranularity.ayah) {
        final anchor = annotation.ayahStart!;
        final extent = annotation.ayahEnd!;
        final start = anchor.compareTo(extent) <= 0 ? anchor : extent;
        final end = anchor.compareTo(extent) <= 0 ? extent : anchor;
        rects = <Rect>[
          for (final region in geometry.ayahRegions)
            if (region.key.compareTo(start) >= 0 &&
                region.key.compareTo(end) <= 0)
              for (final line in region.lineBounds)
                transform.rectToScreen(line.rect),
        ];
      } else {
        final anchor = annotation.wordStart!;
        final extent = annotation.wordEnd!;
        final start = anchor.compareTo(extent) <= 0 ? anchor : extent;
        final end = anchor.compareTo(extent) <= 0 ? extent : anchor;
        rects = <Rect>[
          for (final region in geometry.wordRegions)
            if (region.key.compareTo(start) >= 0 &&
                region.key.compareTo(end) <= 0)
              transform.rectToScreen(region.bounds.rect),
        ];
      }
      final drawable = annotation.granularity == QuranAnnotationGranularity.word
          ? _mergeAdjacentWordRects(rects)
          : rects;
      for (final rect in drawable) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SavedAnnotationPainter old) =>
      old.annotations != annotations ||
      old.geometry != geometry ||
      old.transform != transform;
}

List<Rect> _mergeAdjacentWordRects(List<Rect> source) {
  if (source.length < 2) return source;
  final merged = <Rect>[];
  for (final rect in source) {
    if (merged.isEmpty) {
      merged.add(rect);
      continue;
    }
    final previous = merged.last;
    final verticalOverlap = math.max(
      0,
      math.min(previous.bottom, rect.bottom) - math.max(previous.top, rect.top),
    );
    final sameLine =
        verticalOverlap >= math.min(previous.height, rect.height) * .7;
    final horizontalGap = math.max(
      0,
      math.max(previous.left, rect.left) - math.min(previous.right, rect.right),
    );
    if (sameLine && horizontalGap <= 3) {
      merged[merged.length - 1] = previous.expandToInclude(rect);
    } else {
      merged.add(rect);
    }
  }
  return merged;
}

final class _WordSelectionHandlesOverlay extends StatelessWidget {
  const _WordSelectionHandlesOverlay({
    required this.geometry,
    required this.anchorWordKey,
    required this.extentWordKey,
    required this.startHandleEndpoint,
    required this.endHandleEndpoint,
    required this.color,
    required this.transform,
    required this.onMoveSelectionEndpoint,
    required this.onHandlePointerActiveChanged,
  });

  final QpcPageGeometry geometry;
  final WordKey? anchorWordKey;
  final WordKey? extentWordKey;
  final _SelectionEndpoint? startHandleEndpoint;
  final _SelectionEndpoint? endHandleEndpoint;
  final Color color;
  final QpcPageTransform transform;
  final void Function(_SelectionEndpoint endpoint, WordKey word)
  onMoveSelectionEndpoint;
  final ValueChanged<bool> onHandlePointerActiveChanged;

  @override
  Widget build(BuildContext context) {
    final anchor = anchorWordKey;
    final extent = extentWordKey;
    if (anchor == null || extent == null) return const SizedBox.shrink();
    final anchorStarts = anchor.compareTo(extent) <= 0;
    final start = anchorStarts ? anchor : extent;
    final end = anchorStarts ? extent : anchor;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (startHandleEndpoint case final endpoint?)
          if (_regionFor(start) case final region?)
            _buildHandle(
              role: _SelectionHandleRole.start,
              endpoint: endpoint,
              segment: transform.rectToScreen(region.bounds.rect),
            ),
        if (endHandleEndpoint case final endpoint?)
          if (_regionFor(end) case final region?)
            _buildHandle(
              role: _SelectionHandleRole.end,
              endpoint: endpoint,
              segment: transform.rectToScreen(region.bounds.rect),
            ),
      ],
    );
  }

  QpcWordRegion? _regionFor(WordKey key) {
    for (final region in geometry.wordRegions) {
      if (region.key == key) return region;
    }
    return null;
  }

  Widget _buildHandle({
    required _SelectionHandleRole role,
    required _SelectionEndpoint endpoint,
    required Rect segment,
  }) {
    final handle = _SelectionHandleGeometry.fromSegment(segment, role);
    return Positioned.fromRect(
      key: ValueKey('word-$endpoint'),
      rect: handle.hitRect,
      child: _WordSelectionDragHandle(
        handle: handle,
        role: role,
        color: color,
        selectedWord: endpoint == _SelectionEndpoint.anchor
            ? anchorWordKey!
            : extentWordKey!,
        wordRect: segment,
        geometry: geometry,
        transform: transform,
        semanticsLabel: role == _SelectionHandleRole.start
            ? 'مقبض بداية تحديد الكلمات'
            : 'مقبض نهاية تحديد الكلمات',
        onPointerActiveChanged: onHandlePointerActiveChanged,
        onWordChanged: (word) => onMoveSelectionEndpoint(endpoint, word),
      ),
    );
  }
}

final class _WordSelectionDragHandle extends StatefulWidget {
  const _WordSelectionDragHandle({
    required this.handle,
    required this.role,
    required this.color,
    required this.selectedWord,
    required this.wordRect,
    required this.geometry,
    required this.transform,
    required this.semanticsLabel,
    required this.onPointerActiveChanged,
    required this.onWordChanged,
  });

  final _SelectionHandleGeometry handle;
  final _SelectionHandleRole role;
  final Color color;
  final WordKey selectedWord;
  final Rect wordRect;
  final QpcPageGeometry geometry;
  final QpcPageTransform transform;
  final String semanticsLabel;
  final ValueChanged<bool> onPointerActiveChanged;
  final ValueChanged<WordKey> onWordChanged;

  @override
  State<_WordSelectionDragHandle> createState() =>
      _WordSelectionDragHandleState();
}

final class _WordSelectionDragHandleState
    extends State<_WordSelectionDragHandle> {
  Offset? _dragStartPointer;
  Offset? _dragStartWordCenter;
  QpcPageTransform? _dragTransform;
  List<_WordGeometryLine>? _dragWordLines;
  WordKey? _lastWord;
  Offset _accumulatedPointerDelta = Offset.zero;
  var _pointerActive = false;

  void _capturePointer(PointerDownEvent event) {
    if (_pointerActive) return;
    _pointerActive = true;
    widget.onPointerActiveChanged(true);
  }

  void _releasePointer() {
    if (!_pointerActive) return;
    _pointerActive = false;
    widget.onPointerActiveChanged(false);
  }

  void _startDrag(DragStartDetails details) {
    _dragStartPointer = details.localPosition;
    _dragStartWordCenter = widget.wordRect.center;
    _dragTransform = widget.transform;
    _dragWordLines = _wordGeometryLines(widget.geometry);
    _lastWord = widget.selectedWord;
    _accumulatedPointerDelta = Offset.zero;
  }

  void _updateDrag(DragUpdateDetails details) {
    final startPointer = _dragStartPointer;
    final startWordCenter = _dragStartWordCenter;
    final transform = _dragTransform;
    final wordLines = _dragWordLines;
    final lastWord = _lastWord;
    if (startPointer == null ||
        startWordCenter == null ||
        transform == null ||
        wordLines == null ||
        lastWord == null) {
      return;
    }
    _accumulatedPointerDelta += details.delta;
    final currentPointer = startPointer + _accumulatedPointerDelta;
    final movement = currentPointer - startPointer;
    if (movement == Offset.zero) return;

    final probePagePosition = startWordCenter + movement;
    final canonicalPoint = transform.toCanonical(probePagePosition);
    final candidate = _resolveWordAtCanonicalPoint(wordLines, canonicalPoint);
    if (candidate == null || candidate == lastWord) return;
    _lastWord = candidate;
    widget.onWordChanged(candidate);
  }

  void _finishDrag() {
    _dragStartPointer = null;
    _dragStartWordCenter = null;
    _dragTransform = null;
    _dragWordLines = null;
    _lastWord = null;
    _accumulatedPointerDelta = Offset.zero;
    _releasePointer();
  }

  @override
  void dispose() {
    if (_pointerActive) {
      _pointerActive = false;
      final releasePointer = widget.onPointerActiveChanged;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => releasePointer(false),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticsLabel,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _capturePointer,
      onPointerUp: (_) => _releasePointer(),
      onPointerCancel: (_) => _releasePointer(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        onLongPress: () {},
        onPanStart: _startDrag,
        onPanUpdate: _updateDrag,
        onPanEnd: (_) => _finishDrag(),
        onPanCancel: _finishDrag,
        child: CustomPaint(
          painter: _SelectionHandlePainter(
            role: widget.role,
            color: widget.color,
            stemTop: widget.handle.stemTop - widget.handle.hitRect.topLeft,
            stemBottom:
                widget.handle.stemBottom - widget.handle.hitRect.topLeft,
          ),
        ),
      ),
    ),
  );
}

@immutable
final class _WordGeometryLine {
  const _WordGeometryLine({required this.words, required this.bounds});

  final List<QpcWordRegion> words;
  final Rect bounds;
}

List<_WordGeometryLine> _wordGeometryLines(QpcPageGeometry geometry) {
  final regions = [...geometry.wordRegions]
    ..sort((a, b) {
      final vertical = a.bounds.rect.center.dy.compareTo(
        b.bounds.rect.center.dy,
      );
      return vertical != 0 ? vertical : a.key.compareTo(b.key);
    });
  final grouped = <List<QpcWordRegion>>[];
  final bounds = <Rect>[];
  for (final region in regions) {
    final rect = region.bounds.rect;
    var bestLineIndex = -1;
    var bestOverlapRatio = 0.0;
    for (var index = 0; index < bounds.length; index++) {
      final lineBounds = bounds[index];
      final overlap = math.max(
        0.0,
        math.min(rect.bottom, lineBounds.bottom) -
            math.max(rect.top, lineBounds.top),
      );
      final overlapRatio = overlap / math.min(rect.height, lineBounds.height);
      if (overlapRatio > bestOverlapRatio) {
        bestOverlapRatio = overlapRatio;
        bestLineIndex = index;
      }
    }
    if (bestLineIndex < 0) {
      grouped.add([region]);
      bounds.add(rect);
    } else {
      grouped[bestLineIndex].add(region);
      bounds[bestLineIndex] = bounds[bestLineIndex].expandToInclude(rect);
    }
  }
  final lines = <_WordGeometryLine>[
    for (var index = 0; index < grouped.length; index++)
      _WordGeometryLine(words: grouped[index], bounds: bounds[index]),
  ];
  lines.sort((a, b) => a.bounds.center.dy.compareTo(b.bounds.center.dy));
  return lines;
}

WordKey? _resolveWordAtCanonicalPoint(
  List<_WordGeometryLine> lines,
  Offset point,
) {
  for (final line in lines) {
    for (final word in line.words) {
      if (word.bounds.rect.contains(point)) return word.key;
    }
  }
  if (lines.isEmpty) return null;

  _WordGeometryLine? closestLine;
  var closestVerticalDistance = double.infinity;
  var closestCenterDistance = double.infinity;
  for (final line in lines) {
    final verticalDistance = _distanceToSpan(
      point.dy,
      line.bounds.top,
      line.bounds.bottom,
    );
    final centerDistance = (point.dy - line.bounds.center.dy).abs();
    if (verticalDistance < closestVerticalDistance ||
        (verticalDistance == closestVerticalDistance &&
            centerDistance < closestCenterDistance)) {
      closestLine = line;
      closestVerticalDistance = verticalDistance;
      closestCenterDistance = centerDistance;
    }
  }

  WordKey? closestWord;
  var closestHorizontalDistance = double.infinity;
  var closestWordCenterDistance = double.infinity;
  for (final word in closestLine!.words) {
    final rect = word.bounds.rect;
    final horizontalDistance = _distanceToSpan(
      point.dx,
      rect.left,
      rect.right,
    );
    final centerDistance = (point.dx - rect.center.dx).abs();
    if (horizontalDistance < closestHorizontalDistance ||
        (horizontalDistance == closestHorizontalDistance &&
            centerDistance < closestWordCenterDistance)) {
      closestWord = word.key;
      closestHorizontalDistance = horizontalDistance;
      closestWordCenterDistance = centerDistance;
    }
  }
  return closestWord;
}

double _distanceToSpan(double value, double start, double end) {
  if (value < start) return start - value;
  if (value > end) return value - end;
  return 0;
}

enum _MushafToolbarMode { reading, ayahSelection, wordHighlight }

final class _MushafBottomToolbar extends StatelessWidget {
  const _MushafBottomToolbar({
    required this.mode,
    required this.saving,
    required this.canSaveWordSelection,
    required this.onBack,
    required this.onEnterWordHighlightMode,
    required this.onSaveAyahSelection,
    required this.onCancelWordHighlightMode,
    required this.onSaveWordSelection,
  });

  final _MushafToolbarMode mode;
  final bool saving;
  final bool canSaveWordSelection;
  final VoidCallback onBack;
  final VoidCallback onEnterWordHighlightMode;
  final VoidCallback onSaveAyahSelection;
  final VoidCallback onCancelWordHighlightMode;
  final VoidCallback onSaveWordSelection;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? colors.surfaceElevated : colors.primary;
    final foreground = dark ? colors.primary : colors.onPrimary;
    final mutedForeground = dark
        ? colors.textSecondary
        : colors.onPrimaryMuted;
    final border = dark ? colors.outline : colors.accent;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: dark ? .94 : .91),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: border.withValues(alpha: dark ? .58 : .46),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? .3 : .18),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Material(
                    type: MaterialType.transparency,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Padding(
                        key: ValueKey(mode),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: switch (mode) {
                          _MushafToolbarMode.reading => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MushafToolbarAction(
                                icon: Icons.arrow_forward_rounded,
                                label: 'رجوع',
                                foreground: foreground,
                                mutedForeground: mutedForeground,
                                onPressed: onBack,
                              ),
                              _MushafToolbarAction(
                                icon: Icons.format_color_fill_outlined,
                                label: 'تمييز',
                                foreground: foreground,
                                mutedForeground: mutedForeground,
                                onPressed: onEnterWordHighlightMode,
                              ),
                            ],
                          ),
                          _MushafToolbarMode.ayahSelection => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MushafToolbarModeLabel(
                                icon: Icons.format_quote_rounded,
                                label: 'تحديد آيات',
                                color: mutedForeground,
                              ),
                              _MushafToolbarAction(
                                icon: Icons.format_color_fill_outlined,
                                label: 'تمييز',
                                foreground: foreground,
                                mutedForeground: mutedForeground,
                                loading: saving,
                                onPressed: saving
                                    ? null
                                    : onSaveAyahSelection,
                              ),
                            ],
                          ),
                          _MushafToolbarMode.wordHighlight => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MushafToolbarAction(
                                icon: Icons.close_rounded,
                                label: 'إلغاء',
                                foreground: foreground,
                                mutedForeground: mutedForeground,
                                onPressed: onCancelWordHighlightMode,
                              ),
                              _MushafToolbarModeLabel(
                                icon: Icons.title_rounded,
                                label: 'تمييز الكلمات',
                                color: mutedForeground,
                              ),
                              _MushafToolbarAction(
                                icon: Icons.check_rounded,
                                label: 'حفظ',
                                foreground: foreground,
                                mutedForeground: mutedForeground,
                                loading: saving,
                                onPressed: canSaveWordSelection && !saving
                                    ? onSaveWordSelection
                                    : null,
                              ),
                            ],
                          ),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _MushafToolbarAction extends StatelessWidget {
  const _MushafToolbarAction({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.mutedForeground,
    required this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color mutedForeground;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(
      foregroundColor: foreground,
      disabledForegroundColor: mutedForeground.withValues(alpha: .55),
      minimumSize: const Size(64, 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      textStyle: const TextStyle(
        fontFamily: AppFonts.thmanyahSans,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
    onPressed: onPressed,
    icon: loading
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          )
        : Icon(icon, size: 20),
    label: Text(label, maxLines: 1, overflow: TextOverflow.fade),
  );
}

final class _MushafToolbarModeLabel extends StatelessWidget {
  const _MushafToolbarModeLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontFamily: AppFonts.thmanyahSans,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

@immutable
final class _AnnotationEdit {
  const _AnnotationEdit(this.colorId, this.comment);
  final QuranHighlightColorId colorId;
  final String? comment;
}

@immutable
final class _AnnotationAction {
  const _AnnotationAction(this.annotation, {required this.delete});
  final QuranAnnotation annotation;
  final bool delete;
}

Future<_AnnotationEdit?> _showAnnotationEditor(
  BuildContext context, {
  QuranHighlightColorId initialColor = QuranHighlightColorId.yellow,
  String? initialComment,
}) => showModalBottomSheet<_AnnotationEdit>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AnnotationEditorSheet(
      initialColor: initialColor,
      initialComment: initialComment,
    ),
  );

final class _AnnotationEditorSheet extends StatefulWidget {
  const _AnnotationEditorSheet({
    required this.initialColor,
    required this.initialComment,
  });

  final QuranHighlightColorId initialColor;
  final String? initialComment;

  @override
  State<_AnnotationEditorSheet> createState() =>
      _AnnotationEditorSheetState();
}

final class _AnnotationEditorSheetState extends State<_AnnotationEditorSheet> {
  late final TextEditingController _commentController;
  late QuranHighlightColorId _selectedColor;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.initialComment);
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final comment = _commentController.text.trim();
    final edit = _AnnotationEdit(
      _selectedColor,
      comment.isEmpty ? null : comment,
    );
    Navigator.pop(context, edit);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'حفظ التمييز',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Text('اللون'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final color in QuranHighlightColorId.values)
                Semantics(
                  button: true,
                  selected: _selectedColor == color,
                  label: _highlightColorLabel(color),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _selectedColor = color),
                    child: SizedBox.square(
                      dimension: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _highlightColor(color),
                          border: Border.all(
                            color: _selectedColor == color
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _selectedColor == color
                            ? const Icon(Icons.check_rounded)
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'تعليق خاص (اختياري)',
              helperText: 'يُحفظ محليًا على هذا الجهاز فقط.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _submit, child: const Text('حفظ')),
        ],
      ),
    ),
  );
}

Color _highlightColor(QuranHighlightColorId color) => switch (color) {
  QuranHighlightColorId.yellow => const Color(0xFFF5E59B),
  QuranHighlightColorId.green => const Color(0xFFBBDDC2),
  QuranHighlightColorId.pink => const Color(0xFFEFC6D4),
  QuranHighlightColorId.blue => const Color(0xFFC9DDF2),
  QuranHighlightColorId.purple => const Color(0xFFDDD0F1),
};

String _highlightColorLabel(QuranHighlightColorId color) => switch (color) {
  QuranHighlightColorId.yellow => 'أصفر',
  QuranHighlightColorId.green => 'أخضر',
  QuranHighlightColorId.pink => 'وردي',
  QuranHighlightColorId.blue => 'أزرق',
  QuranHighlightColorId.purple => 'بنفسجي',
};

final class _QpcMessage extends StatelessWidget {
  const _QpcMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
