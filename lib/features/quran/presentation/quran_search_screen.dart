import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/quran/application/mushaf/qpc_v4_tajweed_pack_source.dart';
import 'package:tasbeh/features/quran/domain/mushaf/qpc_v4_tajweed_pack.dart';
import 'package:tasbeh/features/quran/domain/navigation/quran_navigation.dart';
import 'package:tasbeh/features/quran/domain/repositories/quran_repository.dart';
import 'package:tasbeh/features/quran/domain/search/quran_search.dart';
import 'package:tasbeh/features/quran/presentation/quran_reader_screen.dart';
import 'package:tasbeh/features/quran/presentation/quran_routes.dart';
import 'package:tasbeh/shared/widgets/app_glass_surface.dart';

final class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({
    required this.searchRepository,
    required this.navigation,
    required this.quranRepository,
    this.qpcPackSource,
    this.qpcPackManifest,
    super.key,
  });

  final QuranSearchRepository searchRepository;
  final QuranNavigation navigation;
  final QuranRepository quranRepository;
  final QpcV4TajweedPackSource? qpcPackSource;
  final QpcV4TajweedManifest? qpcPackManifest;

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<QuranSearchResult> _results = const [];
  bool _searching = false;
  bool _hasSearched = false;
  String? _error;
  int _requestVersion = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = const [];
        _hasSearched = false;
        _searching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(value));
  }

  Future<void> _search(String value) async {
    final version = ++_requestVersion;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await widget.searchRepository.search(value);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _results = results;
        _hasSearched = true;
      });
    } on QuranSearchQueryException catch (error) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _results = const [];
        _hasSearched = true;
        _error = error.message;
      });
    } on Object {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _results = const [];
        _hasSearched = true;
        _error = 'تعذر البحث في البيانات المحلية.';
      });
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _openResult(QuranSearchResult result) async {
    final target = await widget.navigation.resolveAyah(result.ayahKey);
    if (!mounted) return;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إسقاط الآية على المصحف المحدد.')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      quranFadeRoute(
        (_) => QuranReaderScreen(
          repository: widget.quranRepository,
          target: target,
          qpcPackSource: widget.qpcPackSource,
          qpcPackManifest: widget.qpcPackManifest,
          initialMode:
              widget.qpcPackSource == null
              ? QuranReadingMode.text
              : QuranReadingMode.paper,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'البحث في القرآن',
          style: TextStyle(fontFamily: AppFonts.thmanyahSans),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _query,
                onChanged: _onQueryChanged,
                onSubmitted: _search,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontFamily: AppFonts.thmanyahSans),
                decoration: InputDecoration(
                  labelText: 'كلمات البحث',
                  hintText: 'اكتب كلمة أو أكثر',
                  helperText: 'بحث محلي دون اتصال بالإنترنت',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'مسح البحث',
                          onPressed: () {
                            _query.clear();
                            _onQueryChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: colors.surface.withValues(alpha: .92),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: colors.outline),
                  ),
                ),
              ),
            ),
            if (_searching) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return _SearchMessage(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تنفيذ البحث',
        message: _error!,
      );
    }
    if (!_hasSearched) {
      return const _SearchMessage(
        icon: Icons.manage_search_rounded,
        title: 'ابحث بالنص الدلالي',
        message: 'يمكن البحث مع الحركات أو بدونها، ويظل نص العرض دون تغيير.',
      );
    }
    if (_results.isEmpty) {
      return const _SearchMessage(
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج',
        message: 'جرّب كلمة أقصر أو احذف علامات الترقيم.',
      );
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final result = _results[index];
        return Semantics(
          button: true,
          label:
              '${result.surahNameArabic}، الآية ${ArabicNumerals.integer(result.ayahKey.ayahNumber, groupThousands: false)}',
          child: AppGlassSurface(
            borderRadius: BorderRadius.circular(18),
            level: AppGlassSurfaceLevel.reader,
            child: ListTile(
              minTileHeight: 72,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              title: Text(
                '${result.surahNameArabic} · ${ArabicNumerals.integer(result.ayahKey.ayahNumber, groupThousands: false)}',
                style: const TextStyle(
                  fontFamily: AppFonts.thmanyahSans,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  result.displayText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.reading,
                    fontSize: 19,
                    height: 1.6,
                  ),
                ),
              ),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _openResult(result),
            ),
          ),
        );
      },
    );
  }
}

final class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.thmanyahSans,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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
    );
  }
}
