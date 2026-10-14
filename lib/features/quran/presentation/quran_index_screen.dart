import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/quran/application/mushaf/qpc_v4_tajweed_pack_source.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/qpc_v4_tajweed_pack.dart';
import 'package:tasbeh/features/quran/domain/navigation/quran_navigation.dart';
import 'package:tasbeh/features/quran/domain/repositories/quran_repository.dart';
import 'package:tasbeh/features/quran/domain/search/quran_search.dart';
import 'package:tasbeh/features/quran/presentation/quran_reader_screen.dart';
import 'package:tasbeh/features/quran/presentation/quran_routes.dart';
import 'package:tasbeh/features/quran/presentation/quran_search_screen.dart';
import 'package:tasbeh/shared/widgets/app_glass_surface.dart';

final class QuranIndexScreen extends StatefulWidget {
  const QuranIndexScreen({
    this.navigation,
    this.searchRepository,
    this.quranRepository,
    this.qpcPackSource,
    this.qpcPackManifest,
    super.key,
  }) : assert(
         (navigation == null &&
                 searchRepository == null &&
                 quranRepository == null) ||
             (navigation != null &&
                 searchRepository != null &&
                 quranRepository != null),
       );

  final QuranNavigation? navigation;
  final QuranSearchRepository? searchRepository;
  final QuranRepository? quranRepository;
  final QpcV4TajweedPackSource? qpcPackSource;
  final QpcV4TajweedManifest? qpcPackManifest;

  bool get hasCanonicalIndex => navigation != null;
  bool get hasPaperMushaf =>
      qpcPackSource != null && qpcPackManifest != null;

  @override
  State<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends State<QuranIndexScreen> {
  Future<_QuranIndexData>? _data;

  @override
  void initState() {
    super.initState();
    if (widget.hasCanonicalIndex) _data = _loadIndex();
  }

  Future<_QuranIndexData> _loadIndex() async {
    final navigation = widget.navigation!;
    final values = await Future.wait<Object>([
      navigation.getSurahs(),
      navigation.getJuzs(),
      navigation.getHizbs(),
      navigation.getRubs(),
    ]);
    return _QuranIndexData(
      surahs: values[0] as List<QuranSurah>,
      juzs: values[1] as List<QuranJuz>,
      hizbs: values[2] as List<QuranHizb>,
      rubs: values[3] as List<QuranRubElHizb>,
    );
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push<void>(
      quranFadeRoute(
        (_) => QuranSearchScreen(
          searchRepository: widget.searchRepository!,
          navigation: widget.navigation!,
          quranRepository: widget.quranRepository!,
          qpcPackSource: widget.qpcPackSource,
          qpcPackManifest: widget.qpcPackManifest,
        ),
      ),
    );
  }

  Future<void> _openTarget(QuranNavigationTarget? target) async {
    if (!mounted) return;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد موضع القراءة محليًا.')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      quranFadeRoute(
        (_) => QuranReaderScreen(
          repository: widget.quranRepository!,
          target: target,
          qpcPackSource: widget.qpcPackSource,
          qpcPackManifest: widget.qpcPackManifest,
          initialMode: !widget.hasPaperMushaf
              ? QuranReadingMode.text
              : QuranReadingMode.paper,
        ),
      ),
    );
  }

  Future<void> _openJump() async {
    final target = await showModalBottomSheet<QuranNavigationTarget>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _QuranJumpSheet(navigation: widget.navigation!),
    );
    if (target != null) await _openTarget(target);
  }

  Future<void> _openPaperPage(int pageNumber) async {
    if (widget.qpcPackSource != null && widget.qpcPackManifest != null) {
      await Navigator.of(context).push<void>(
        quranFadeRoute(
          (_) => QpcV4QuranPaperReaderScreen(
            source: widget.qpcPackSource!,
            manifest: widget.qpcPackManifest!,
            initialPageNumber: pageNumber,
          ),
        ),
      );
      return;
    }
    throw StateError('QPC V4 Tajweed pack is unavailable');
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasCanonicalIndex) {
      if (widget.hasPaperMushaf) {
        return _PaperOnlyQuranView(
          pageCount: widget.qpcPackManifest!.pageCount,
          onOpenPage: _openPaperPage,
        );
      }
      return const _QuranUnavailableView();
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'القرآن الكريم',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'انتقال إلى صفحة أو آية',
              onPressed: _openJump,
              icon: const Icon(Icons.my_location_rounded),
            ),
            IconButton(
              tooltip: 'البحث في القرآن',
              onPressed: _openSearch,
              icon: const Icon(Icons.search_rounded),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'السور'),
              Tab(text: 'الأجزاء'),
              Tab(text: 'الأحزاب'),
              Tab(text: 'الأرباع'),
            ],
          ),
        ),
        body: FutureBuilder<_QuranIndexData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _IndexError(
                onRetry: () {
                  setState(() => _data = _loadIndex());
                },
              );
            }
            final data = snapshot.requireData;
            return TabBarView(
              children: [
                _SurahList(
                  surahs: data.surahs,
                  onSelected: (surah) async => _openTarget(
                    await widget.navigation!.resolveSurahStart(surah.number),
                  ),
                ),
                _BoundaryList(
                  label: 'الجزء',
                  boundaries: data.juzs,
                  onSelected: (boundary) async => _openTarget(
                    await widget.navigation!.resolveJuzStart(boundary.number),
                  ),
                ),
                _BoundaryList(
                  label: 'الحزب',
                  boundaries: data.hizbs,
                  onSelected: (boundary) async => _openTarget(
                    await widget.navigation!.resolveHizbStart(boundary.number),
                  ),
                ),
                _BoundaryList(
                  label: 'الربع',
                  boundaries: data.rubs,
                  onSelected: (boundary) async => _openTarget(
                    await widget.navigation!.resolveRubStart(boundary.number),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _PaperOnlyQuranView extends StatefulWidget {
  const _PaperOnlyQuranView({
    required this.pageCount,
    required this.onOpenPage,
  });

  final int pageCount;
  final ValueChanged<int> onOpenPage;

  @override
  State<_PaperOnlyQuranView> createState() => _PaperOnlyQuranViewState();
}

class _PaperOnlyQuranViewState extends State<_PaperOnlyQuranView> {
  final _pageController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openRequestedPage() {
    final page = int.tryParse(_pageController.text);
    if (page == null || page < 1 || page > widget.pageCount) {
      setState(() => _error = 'أدخل رقم صفحة من ١ إلى ${widget.pageCount}.');
      return;
    }
    setState(() => _error = null);
    widget.onOpenPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'القرآن الكريم',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AppGlassSurface(
            borderRadius: BorderRadius.circular(24),
            level: AppGlassSurfaceLevel.reader,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 52,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'المصحف الشريف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.thmanyahSans,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'نسخة بحثية محلية · ${widget.pageCount} صفحة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.thmanyahSans,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => widget.onOpenPage(1),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('فتح المصحف'),
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size.fromHeight(52)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _openRequestedPage(),
                    decoration: InputDecoration(
                      labelText: 'الانتقال إلى صفحة',
                      errorText: _error,
                      suffixIcon: IconButton(
                        tooltip: 'انتقال',
                        onPressed: _openRequestedPage,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'البحث ووضع النص غير متاحين حتى تُضاف بيانات القرآن الأساسية المعتمدة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.thmanyahSans,
                      height: 1.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _QuranIndexData {
  const _QuranIndexData({
    required this.surahs,
    required this.juzs,
    required this.hizbs,
    required this.rubs,
  });

  final List<QuranSurah> surahs;
  final List<QuranJuz> juzs;
  final List<QuranHizb> hizbs;
  final List<QuranRubElHizb> rubs;
}

final class _SurahList extends StatelessWidget {
  const _SurahList({required this.surahs, required this.onSelected});

  final List<QuranSurah> surahs;
  final ValueChanged<QuranSurah> onSelected;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    itemCount: surahs.length,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (context, index) {
      final surah = surahs[index];
      return _IndexTile(
        title: surah.nameArabic,
        subtitle:
            '${ArabicNumerals.integer(surah.ayahCount, groupThousands: false)} آية',
        number: surah.number,
        semanticsLabel: 'سورة ${surah.nameArabic}',
        onTap: () => onSelected(surah),
      );
    },
  );
}

final class _BoundaryList extends StatelessWidget {
  const _BoundaryList({
    required this.label,
    required this.boundaries,
    required this.onSelected,
  });

  final String label;
  final List<QuranBoundary> boundaries;
  final ValueChanged<QuranBoundary> onSelected;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    itemCount: boundaries.length,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (context, index) {
      final boundary = boundaries[index];
      return _IndexTile(
        title:
            '$label ${ArabicNumerals.integer(boundary.number, groupThousands: false)}',
        subtitle:
            'يبدأ من ${boundary.startsAt.surahNumber}:${boundary.startsAt.ayahNumber}',
        number: boundary.number,
        semanticsLabel: '$label ${boundary.number}',
        onTap: () => onSelected(boundary),
      );
    },
  );
}

final class _IndexTile extends StatelessWidget {
  const _IndexTile({
    required this.title,
    required this.subtitle,
    required this.number,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int number;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: AppGlassSurface(
        borderRadius: BorderRadius.circular(18),
        level: AppGlassSurfaceLevel.reader,
        child: ListTile(
          minTileHeight: 72,
          leading: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              ArabicNumerals.integer(number, groupThousands: false),
              style: TextStyle(
                fontFamily: AppFonts.outfit,
                color: colors.onPrimaryContainer ?? colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.thmanyahSans,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontFamily: AppFonts.thmanyahSans),
          ),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

final class _QuranUnavailableView extends StatelessWidget {
  const _QuranUnavailableView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'القرآن الكريم',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AppGlassSurface(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 52,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'البنية المحلية جاهزة',
                    style: TextStyle(
                      fontFamily: AppFonts.thmanyahSans,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'لم تُضف بيانات القرآن الإنتاجية المعتمدة بعد. ستظهر هنا '
                    'الفهارس والبحث ووضع النص فور اعتماد المصدر والتحقق من سلامته.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.thmanyahSans,
                      height: 1.7,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.offline_bolt_outlined,
                          color: colors.onPrimaryContainer ?? colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'القراءة والبحث سيعملان دون إنترنت',
                            style: TextStyle(
                              fontFamily: AppFonts.thmanyahSans,
                              color:
                                  colors.onPrimaryContainer ?? colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _IndexError extends StatelessWidget {
  const _IndexError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48),
          const SizedBox(height: 12),
          const Text(
            'تعذر تحميل الفهرس المحلي.',
            style: TextStyle(fontFamily: AppFonts.thmanyahSans),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

enum _JumpKind { page, ayah }

final class _QuranJumpSheet extends StatefulWidget {
  const _QuranJumpSheet({required this.navigation});

  final QuranNavigation navigation;

  @override
  State<_QuranJumpSheet> createState() => _QuranJumpSheetState();
}

class _QuranJumpSheetState extends State<_QuranJumpSheet> {
  final _page = TextEditingController();
  final _surah = TextEditingController();
  final _ayah = TextEditingController();
  _JumpKind _kind = _JumpKind.page;
  String? _error;
  bool _resolving = false;

  @override
  void dispose() {
    _page.dispose();
    _surah.dispose();
    _ayah.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() {
      _resolving = true;
      _error = null;
    });
    QuranNavigationTarget? target;
    if (_kind == _JumpKind.page) {
      final page = int.tryParse(_page.text);
      if (page != null && page > 0) {
        target = await widget.navigation.resolvePage(
          MushafPageKey(widget.navigation.edition.id, page),
        );
      }
    } else {
      final surah = int.tryParse(_surah.text);
      final ayah = int.tryParse(_ayah.text);
      if (surah != null &&
          surah >= 1 &&
          surah <= 114 &&
          ayah != null &&
          ayah > 0) {
        target = await widget.navigation.resolveAyah(AyahKey(surah, ayah));
      }
    }
    if (!mounted) return;
    if (target == null) {
      setState(() {
        _resolving = false;
        _error = 'الموضع غير موجود في البيانات المحلية المحددة.';
      });
      return;
    }
    Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'انتقال مباشر',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: AppFonts.thmanyahSans,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<_JumpKind>(
          segments: const [
            ButtonSegment(value: _JumpKind.page, label: Text('صفحة')),
            ButtonSegment(value: _JumpKind.ayah, label: Text('آية')),
          ],
          selected: {_kind},
          onSelectionChanged: (selection) {
            setState(() {
              _kind = selection.single;
              _error = null;
            });
          },
        ),
        const SizedBox(height: 16),
        if (_kind == _JumpKind.page)
          TextField(
            controller: _page,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText:
                  'رقم الصفحة (١–${ArabicNumerals.integer(widget.navigation.edition.pageCount)})',
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _surah,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'رقم السورة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ayah,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'رقم الآية'),
                ),
              ),
            ],
          ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(
              fontFamily: AppFonts.thmanyahSans,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _resolving ? null : _resolve,
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
          ),
          child: _resolving
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('انتقال'),
        ),
      ],
    ),
  );
}
