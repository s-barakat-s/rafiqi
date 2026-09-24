import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_recording_service.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/manual_tasbeeh_entry.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

class ManualTasbeehDraft {
  const ManualTasbeehDraft({required this.phrase, required this.count});
  final TasbeehPhrase phrase;
  final int count;
}

class ManualTasbeehEntrySheet extends StatefulWidget {
  const ManualTasbeehEntrySheet({
    required this.phrases,
    required this.initialPhrase,
    this.initialCount,
    this.onOpenHistory,
    super.key,
  });

  final List<TasbeehPhrase> phrases;
  final TasbeehPhrase initialPhrase;
  final int? initialCount;
  final VoidCallback? onOpenHistory;

  @override
  State<ManualTasbeehEntrySheet> createState() =>
      _ManualTasbeehEntrySheetState();
}

class _ManualTasbeehEntrySheetState extends State<ManualTasbeehEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _countController = TextEditingController(
    text: widget.initialCount?.toString() ?? '',
  );
  late TasbeehPhrase _selected = widget.initialPhrase;

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  int? _parsedCount(String value) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    var normalized = value.trim();
    for (var index = 0; index < arabicDigits.length; index++) {
      normalized = normalized.replaceAll(arabicDigits[index], '$index');
    }
    return int.tryParse(normalized);
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(
      context,
      ManualTasbeehDraft(
        phrase: _selected,
        count: _parsedCount(_countController.text)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineStrong,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.initialCount == null ? 'تسجيل ذكر' : 'تعديل التسجيل',
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<TasbeehPhrase>(
                  initialValue: _selected,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'الذكر'),
                  items: [
                    for (final phrase in widget.phrases)
                      DropdownMenuItem(
                        value: phrase,
                        child: Text(phrase.text, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (phrase) {
                    if (phrase != null) setState(() => _selected = phrase);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _countController,
                  autofocus: widget.initialCount == null,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]')),
                  ],
                  decoration: const InputDecoration(labelText: 'العدد'),
                  validator: (value) {
                    final count = _parsedCount(value ?? '');
                    if (count == null || count <= 0) {
                      return 'أدخل عددًا صحيحًا أكبر من صفر';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _submit,
                  child: Text(
                    widget.initialCount == null
                        ? 'إضافة للسجل'
                        : 'حفظ التعديل',
                  ),
                ),
                if (widget.onOpenHistory != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onOpenHistory!();
                    },
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('تسجيلاتي اليدوية'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ManualTasbeehHistoryScreen extends StatefulWidget {
  const ManualTasbeehHistoryScreen({required this.phrases, super.key});
  final List<TasbeehPhrase> phrases;

  @override
  State<ManualTasbeehHistoryScreen> createState() =>
      _ManualTasbeehHistoryScreenState();
}

class _ManualTasbeehHistoryScreenState
    extends State<ManualTasbeehHistoryScreen> {
  final _repository = TasbeehRepository();
  final _recording = TasbeehRecordingService();
  List<ManualTasbeehEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _repository.loadManualEntries();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  List<TasbeehPhrase> _phrasesFor(ManualTasbeehEntry entry) {
    if (widget.phrases.any((phrase) => phrase.id == entry.dhikrId)) {
      return widget.phrases;
    }
    return [
      ...widget.phrases,
      TasbeehPhrase(
        id: entry.dhikrId,
        text: entry.dhikrTextSnapshot,
        isBuiltIn: false,
      ),
    ];
  }

  Future<void> _edit(ManualTasbeehEntry entry) async {
    final phrases = _phrasesFor(entry);
    final selected = phrases.firstWhere((phrase) => phrase.id == entry.dhikrId);
    final draft = await showModalBottomSheet<ManualTasbeehDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ManualTasbeehEntrySheet(
        phrases: phrases,
        initialPhrase: selected,
        initialCount: entry.count,
      ),
    );
    if (draft == null) return;
    final completed = await _recording.updatePhysicalManual(
      entry.copyWith(
        dhikrId: draft.phrase.id,
        dhikrTextSnapshot: draft.phrase.text,
        count: draft.count,
      ),
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completed
              ? 'تم حفظ التعديل وإكمال المهمة'
              : 'تم حفظ التعديل',
        ),
      ),
    );
  }

  Future<void> _delete(ManualTasbeehEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التسجيل؟'),
        content: Text(
          'سيُحذف تسجيل ${entry.dhikrTextSnapshot} بعدد '
          '${ArabicNumerals.integer(entry.count)} من الإحصائيات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _recording.deletePhysicalManual(entry);
    await _load();
  }

  String _timeLabel(ManualTasbeehEntry entry) {
    final local = entry.timestamp.toLocal();
    final today = LocalDay.key(DateTime.now());
    final day = entry.dayKey == today
        ? 'اليوم'
        : ArabicNumerals.digits(
            '${local.year}/${local.month.toString().padLeft(2, '0')}/'
            '${local.day.toString().padLeft(2, '0')}',
          );
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final time = ArabicNumerals.digits(
      '$hour:${local.minute.toString().padLeft(2, '0')}',
    );
    return '$day، $time ${local.hour >= 12 ? 'م' : 'ص'}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('تسجيلاتي اليدوية')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
            ? Center(
                child: Text(
                  'لا توجد تسجيلات يدوية بعد',
                  style: TextStyle(color: colors.textSecondary),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return Material(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        10,
                        8,
                        10,
                      ),
                      child: Row(
                        children: [
                          const RafiqiSvgIcon(RafiqiIcons.tasbeeh, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.dhikrTextSnapshot,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${ArabicNumerals.integer(entry.count)} · ${_timeLabel(entry)}',
                                  style: TextStyle(color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _edit(entry),
                            tooltip: 'تعديل التسجيل',
                            icon: const RafiqiSvgIcon(
                              RafiqiIcons.edit,
                              size: 21,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _delete(entry),
                            tooltip: 'حذف التسجيل',
                            icon: RafiqiSvgIcon(
                              RafiqiIcons.delete,
                              size: 21,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
