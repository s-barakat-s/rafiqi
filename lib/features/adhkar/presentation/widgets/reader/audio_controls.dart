part of '../../screens/wird_reader_screen.dart';

class _CollectionAudioBar extends StatelessWidget {
  const _CollectionAudioBar({
    required this.audio,
    required this.manifests,
    required this.collectionId,
    required this.onOpen,
  });

  final DhikrAudioController? audio;
  final DhikrAudioManifestRepository manifests;
  final String collectionId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reciterId = audio?.selectedReciterId ?? manifests.reciters.first.id;
    final reciter = manifests.reciters.firstWhere(
      (value) => value.id == reciterId,
      orElse: () => manifests.reciters.first,
    );
    final playingThisCollection =
        audio?.selectedCollectionId == collectionId && audio!.isActive;
    return Semantics(
      container: true,
      label: 'تشغيل صوتي للأذكار',
      child: Material(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
              child: Row(
                children: [
                  Icon(
                    playingThisCollection
                        ? Icons.graphic_eq_rounded
                        : Icons.headphones_rounded,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playingThisCollection
                              ? 'جارٍ تشغيل الورد'
                              : 'الاستماع إلى الورد',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          reciter.nameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (playingThisCollection) ...[
                    IconButton(
                      tooltip: audio!.status == DhikrPlaybackStatus.playing
                          ? 'إيقاف مؤقت'
                          : 'متابعة',
                      onPressed: audio!.status == DhikrPlaybackStatus.playing
                          ? audio!.pause
                          : audio!.resume,
                      icon: Icon(
                        audio!.status == DhikrPlaybackStatus.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    IconButton(
                      tooltip: 'إيقاف',
                      onPressed: audio!.stop,
                      icon: const Icon(Icons.stop_rounded),
                    ),
                  ] else
                    const Icon(Icons.expand_more_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DhikrAudioAction extends StatelessWidget {
  const _DhikrAudioAction({
    required this.active,
    required this.phase,
    required this.status,
    required this.onPressed,
  });

  final bool active;
  final DhikrPlaybackPhase? phase;
  final DhikrPlaybackStatus? status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final repeating = active && phase == DhikrPlaybackPhase.repeatSilence;
    final label = repeating
        ? 'حان وقت الترديد'
        : active
        ? 'يُشغّل الآن'
        : 'استماع';
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: active ? colors.secondary : colors.textSecondary,
          backgroundColor: active ? colors.selected : Colors.transparent,
        ),
        icon: Icon(
          repeating
              ? Icons.mic_none_rounded
              : active && status == DhikrPlaybackStatus.playing
              ? Icons.graphic_eq_rounded
              : Icons.play_circle_outline_rounded,
          size: 21,
        ),
        label: Text(label),
      ),
    );
  }
}

class _ReciterSelectorSheet extends StatefulWidget {
  const _ReciterSelectorSheet({
    required this.runtime,
    required this.collectionId,
    required this.onPlay,
    this.dhikrId,
  });

  final DhikrAudioRuntime runtime;
  final String collectionId;
  final String? dhikrId;
  final ValueChanged<DhikrPlaybackMode> onPlay;

  @override
  State<_ReciterSelectorSheet> createState() => _ReciterSelectorSheetState();
}

class _ReciterSelectorSheetState extends State<_ReciterSelectorSheet> {
  @override
  void initState() {
    super.initState();
    for (final reciter in widget.runtime.manifests.reciters) {
      widget.runtime.downloads.refresh(reciter.id, widget.collectionId);
    }
    widget.runtime.downloads.addListener(_refresh);
    widget.runtime.playback.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.runtime.downloads.removeListener(_refresh);
    widget.runtime.playback.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = widget.runtime.playback;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('القارئ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...widget.runtime.manifests.reciters.map((reciter) {
              final collection = widget.runtime.manifests.collectionFor(
                reciter.id,
                widget.collectionId,
              );
              final mappedForContent = widget.dhikrId == null
                  ? collection?.hasMappedAudio ?? false
                  : collection?.sourceFor(widget.dhikrId!) != null;
              final snapshot = widget.runtime.downloads.snapshot(
                reciter.id,
                widget.collectionId,
              );
              final selected = playback.selectedReciterId == reciter.id;
              return RadioGroup<String>(
                groupValue: playback.selectedReciterId,
                onChanged: (value) {
                  if (mappedForContent && value != null) {
                    unawaited(playback.selectReciter(value));
                  }
                },
                child: ListTile(
                  minTileHeight: 56,
                  contentPadding: EdgeInsets.zero,
                  enabled: mappedForContent,
                  leading: Radio<String>(
                    value: reciter.id,
                    enabled: mappedForContent,
                  ),
                  title: Text(reciter.nameAr),
                  subtitle: Text(
                    mappedForContent
                        ? reciter.coverage == ReciterCoverage.partial
                              ? 'تغطية جزئية'
                              : 'تغطية كاملة'
                        : 'غير متاح لهذا المحتوى حاليًا',
                  ),
                  trailing: _DownloadTrailing(
                    snapshot: snapshot,
                    selected: selected,
                    onDownload: () => widget.runtime.downloads.download(
                      reciter.id,
                      widget.collectionId,
                    ),
                    onRetry: () => widget.runtime.downloads.retry(
                      reciter.id,
                      widget.collectionId,
                    ),
                    onCancel: () => widget.runtime.downloads.cancel(
                      reciter.id,
                      widget.collectionId,
                    ),
                    onDelete: () => widget.runtime.downloads.delete(
                      reciter.id,
                      widget.collectionId,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            SegmentedButton<DhikrPlaybackMode>(
              segments: const [
                ButtonSegment(
                  value: DhikrPlaybackMode.listen,
                  icon: Icon(Icons.headphones_rounded),
                  label: Text('استماع'),
                ),
                ButtonSegment(
                  value: DhikrPlaybackMode.repeatAfterMe,
                  icon: Icon(Icons.record_voice_over_outlined),
                  label: Text('ردّد خلفي'),
                ),
              ],
              selected: {playback.mode},
              onSelectionChanged: (value) => playback.selectMode(value.single),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => widget.onPlay(playback.mode),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                widget.dhikrId == null ? 'تشغيل الورد' : 'تشغيل الذكر',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTrailing extends StatelessWidget {
  const _DownloadTrailing({
    required this.snapshot,
    required this.selected,
    required this.onDownload,
    required this.onRetry,
    required this.onCancel,
    required this.onDelete,
  });

  final AudioDownloadSnapshot snapshot;
  final bool selected;
  final VoidCallback onDownload;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.isAvailable) {
      return const Icon(Icons.block_rounded, semanticLabel: 'غير متاح');
    }
    if (snapshot.isBundledDevelopment) {
      return const Icon(
        Icons.offline_pin_rounded,
        semanticLabel: 'متاح محليًا للتطوير',
      );
    }
    return switch (snapshot.status) {
      AudioDownloadStatus.notDownloaded => IconButton(
        tooltip: 'تنزيل',
        onPressed: onDownload,
        icon: const Icon(Icons.download_rounded),
      ),
      AudioDownloadStatus.queued ||
      AudioDownloadStatus.downloading => IconButton(
        tooltip: 'إلغاء التنزيل',
        onPressed: onCancel,
        icon: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(value: snapshot.progress),
        ),
      ),
      AudioDownloadStatus.downloaded => IconButton(
        tooltip: 'حذف الصوت المحلي',
        onPressed: onDelete,
        icon: const Icon(Icons.download_done_rounded),
      ),
      AudioDownloadStatus.failed => IconButton(
        tooltip: 'إعادة المحاولة',
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
      ),
    };
  }
}
