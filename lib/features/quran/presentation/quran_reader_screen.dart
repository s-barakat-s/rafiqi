import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/quran/application/mushaf/qpc_v4_tajweed_pack_source.dart';
import 'package:tasbeh/features/quran/application/text/quran_text_mode_controller.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/qpc_v4_tajweed_pack.dart';
import 'package:tasbeh/features/quran/domain/navigation/quran_navigation.dart';
import 'package:tasbeh/features/quran/domain/repositories/quran_repository.dart';
import 'package:tasbeh/features/quran/presentation/qpc_v4_tajweed_reader.dart';
import 'package:tasbeh/shared/widgets/app_glass_surface.dart';

enum QuranReadingMode { paper, text }

final class QpcV4QuranPaperReaderScreen extends StatelessWidget {
  const QpcV4QuranPaperReaderScreen({
    required this.source,
    required this.manifest,
    required this.initialPageNumber,
    super.key,
  });

  final QpcV4TajweedPackSource source;
  final QpcV4TajweedManifest manifest;
  final int initialPageNumber;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: QpcV4TajweedReader(
      source: source,
      manifest: manifest,
      initialPageNumber: initialPageNumber,
    ),
  );
}

final class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({
    required this.repository,
    required this.target,
    this.qpcPackSource,
    this.qpcPackManifest,
    this.initialMode = QuranReadingMode.text,
    super.key,
  });

  final QuranRepository repository;
  final QuranNavigationTarget target;
  final QpcV4TajweedPackSource? qpcPackSource;
  final QpcV4TajweedManifest? qpcPackManifest;
  final QuranReadingMode initialMode;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late final QuranTextModeController _textMode;
  late QuranReadingMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _textMode = QuranTextModeController(widget.repository)
      ..loadSurah(
        widget.target.ayahKey.surahNumber,
        target: widget.target.ayahKey,
      ).ignore();
  }

  @override
  void dispose() {
    _textMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == QuranReadingMode.paper &&
        widget.qpcPackSource != null &&
        widget.qpcPackManifest != null) {
      return Scaffold(
        body: QpcV4TajweedReader(
          source: widget.qpcPackSource!,
          manifest: widget.qpcPackManifest!,
          initialPageNumber: widget.target.pageKey.pageNumber,
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: AnimatedBuilder(
          animation: _textMode,
          builder: (context, _) => Text(
            _textMode.surah?.nameArabic ?? 'القرآن الكريم',
            style: const TextStyle(fontFamily: AppFonts.thmanyahSans),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<QuranReadingMode>(
                  segments: const [
                    ButtonSegment(
                      value: QuranReadingMode.paper,
                      icon: Icon(Icons.menu_book_outlined),
                      label: Text('المصحف'),
                    ),
                    ButtonSegment(
                      value: QuranReadingMode.text,
                      icon: Icon(Icons.format_align_right_rounded),
                      label: Text('النص'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() => _mode = selection.single);
                  },
                  style: ButtonStyle(
                    minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontFamily: AppFonts.thmanyahSans),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _mode == QuranReadingMode.paper
                  ? widget.qpcPackSource != null &&
                            widget.qpcPackManifest != null
                        ? QpcV4TajweedReader(
                            source: widget.qpcPackSource!,
                            manifest: widget.qpcPackManifest!,
                            initialPageNumber: widget.target.pageKey.pageNumber,
                          )
                        : _PaperPendingView(target: widget.target)
                  : _TextModeView(controller: _textMode),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PaperPendingView extends StatelessWidget {
  const _PaperPendingView({required this.target});

  final QuranNavigationTarget target;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
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
              children: [
                Icon(Icons.menu_book_outlined, size: 48, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  'المصحف الدلالي محدد تقنيًا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.thmanyahSans,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'الصفحة ${ArabicNumerals.integer(target.pageKey.pageNumber)} · '
                  'الآية ${ArabicNumerals.integer(target.ayahKey.ayahNumber)}',
                  style: TextStyle(
                    fontFamily: AppFonts.thmanyahSans,
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'لم تُضمَّن صفحات المصحف في نسخة الإنتاج بعد. يلزم أولًا '
                  'اعتماد المصدر ومراجعة المطابقة والمراجعة المتخصصة. وضع النص '
                  'متاح من البيانات الدلالية المحلية عند اعتمادها.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.thmanyahSans,
                    height: 1.6,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _TextModeView extends StatelessWidget {
  const _TextModeView({required this.controller});

  final QuranTextModeController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error != null) {
        return const _TextModeMessage(
          icon: Icons.error_outline_rounded,
          message: 'تعذر فتح نص السورة من المصدر المحلي.',
        );
      }
      if (controller.ayahs.isEmpty) {
        return const _TextModeMessage(
          icon: Icons.inventory_2_outlined,
          message: 'لا توجد بيانات نصية معتمدة لهذه السورة.',
        );
      }
      final targetIndex = controller.scrollTargetIndex ?? 0;
      final centerKey = ValueKey(
        'quran-text-target-${controller.scrollTarget}',
      );
      return CustomScrollView(
        key: PageStorageKey('quran-text-${controller.surah?.number}'),
        center: centerKey,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          if (targetIndex > 0)
            SliverList.builder(
              itemCount: targetIndex,
              itemBuilder: (context, index) => _AyahTile(
                ayah: controller.ayahs[targetIndex - index - 1],
                selected:
                    controller.selectedAyah ==
                    controller.ayahs[targetIndex - index - 1].key,
                onSelected: controller.selectAyah,
              ),
            ),
          SliverList.builder(
            key: centerKey,
            itemCount: controller.ayahs.length - targetIndex,
            itemBuilder: (context, index) => _AyahTile(
              ayah: controller.ayahs[targetIndex + index],
              selected:
                  controller.selectedAyah ==
                  controller.ayahs[targetIndex + index].key,
              onSelected: controller.selectAyah,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      );
    },
  );
}

final class _AyahTile extends StatelessWidget {
  const _AyahTile({
    required this.ayah,
    required this.selected,
    required this.onSelected,
  });

  final QuranAyah ayah;
  final bool selected;
  final ValueChanged<AyahKey> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      label:
          'الآية ${ArabicNumerals.integer(ayah.key.ayahNumber, groupThousands: false)}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: AppGlassSurface(
          borderRadius: BorderRadius.circular(20),
          level: AppGlassSurfaceLevel.reader,
          borderColor: selected ? colors.primary : colors.outline,
          backgroundColor: selected
              ? colors.selected.withValues(alpha: .96)
              : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onSelected(ayah.key),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        ArabicNumerals.integer(
                          ayah.key.ayahNumber,
                          groupThousands: false,
                        ),
                        style: TextStyle(
                          fontFamily: AppFonts.outfit,
                          color: colors.onPrimaryContainer ?? colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectionArea(
                    child: Text(
                      ayah.textUthmani,
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: AppFonts.reading,
                        fontSize: 25,
                        height: 1.9,
                        color: colors.textPrimary,
                      ),
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

final class _TextModeMessage extends StatelessWidget {
  const _TextModeMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: context.appColors.primary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.thmanyahSans,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
