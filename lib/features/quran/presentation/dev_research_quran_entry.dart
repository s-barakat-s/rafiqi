import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/quran/application/mushaf/dev_research_qpc_v4_runtime.dart';
import 'package:tasbeh/features/quran/presentation/quran_index_screen.dart';
import 'package:tasbeh/shared/widgets/app_glass_surface.dart';

final class DevResearchQuranEntry extends StatefulWidget {
  const DevResearchQuranEntry({super.key});

  @override
  State<DevResearchQuranEntry> createState() => _DevResearchQuranEntryState();
}

class _DevResearchQuranEntryState extends State<DevResearchQuranEntry> {
  late Future<DevResearchQpcV4Runtime> _runtime;
  DevResearchQpcV4Runtime? _openedRuntime;

  @override
  void initState() {
    super.initState();
    _runtime = _open();
  }

  Future<DevResearchQpcV4Runtime> _open() async {
    final runtime = await DevResearchQpcV4Runtime.open();
    _openedRuntime = runtime;
    return runtime;
  }

  void _retry() {
    final nextRuntime = _open();
    setState(() {
      _runtime = nextRuntime;
    });
  }

  @override
  void dispose() {
    _openedRuntime?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<DevResearchQpcV4Runtime>(
    future: _runtime,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return _ResearchRuntimeError(error: snapshot.error, onRetry: _retry);
      }
      final runtime = snapshot.requireData;
      return QuranIndexScreen(
        qpcPackSource: runtime.source,
        qpcPackManifest: runtime.manifest,
      );
    },
  );
}

final class _ResearchRuntimeError extends StatelessWidget {
  const _ResearchRuntimeError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text('القرآن الكريم'),
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
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: context.appColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'تعذر فتح موارد المصحف البحثية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.thmanyahSans,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.outfit,
                    color: context.appColors.textSecondary,
                  ),
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
        ),
      ),
    ),
  );
}
