import 'package:flutter/material.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_collection_overrides_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_collection_overrides.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

class AdhkarCollectionCustomizationScreen extends StatefulWidget {
  const AdhkarCollectionCustomizationScreen({
    required this.category,
    super.key,
  });

  final AdhkarCategory category;

  @override
  State<AdhkarCollectionCustomizationScreen> createState() =>
      _AdhkarCollectionCustomizationScreenState();
}

class _AdhkarCollectionCustomizationScreenState
    extends State<AdhkarCollectionCustomizationScreen> {
  final _repository = AdhkarCollectionOverridesRepository.instance;
  AdhkarCollectionOverrides? _overrides;
  List<DhikrItem> _items = const [];
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _repository.load(widget.category.id);
    if (!mounted) return;
    setState(() {
      _overrides = value;
      _items = _orderedItems(value);
    });
  }

  List<DhikrItem> _orderedItems(AdhkarCollectionOverrides overrides) {
    final all = <DhikrItem>[
      ...widget.category.items,
      ...overrides.addedDhikrItems.map(
        (item) => DhikrItem(
          id: item.id,
          order: widget.category.items.length * 100,
          category: widget.category.id,
          text: item.text,
          repeatCount: item.repeatCount,
          entryType: DhikrEntryType.single,
        ),
      ),
    ];
    final byId = {for (final item in all) item.id: item};
    return [
      for (final id in overrides.customOrder)
        if (byId.containsKey(id)) byId.remove(id)!,
      ...byId.values,
    ];
  }

  Future<void> _save(AdhkarCollectionOverrides value) async {
    setState(() => _overrides = value);
    await _repository.save(widget.category.id, value);
  }

  AdhkarCollectionOverrides _with({
    Set<String>? hidden,
    Map<String, int>? counts,
    List<String>? order,
    List<UserAddedDhikr>? added,
  }) {
    final current = _overrides!;
    return AdhkarCollectionOverrides(
      hiddenDhikrIds: hidden ?? current.hiddenDhikrIds,
      repeatCountOverrides: counts ?? current.repeatCountOverrides,
      customOrder: order ?? current.customOrder,
      addedDhikrItems: added ?? current.addedDhikrItems,
    );
  }

  bool _isAdded(String id) =>
      _overrides!.addedDhikrItems.any((item) => item.id == id);

  int _originalCount(DhikrItem item) {
    for (final canonical in widget.category.items) {
      if (canonical.id == item.id) return canonical.repeatCount;
    }
    return _overrides!.addedDhikrItems
        .firstWhere((added) => added.id == item.id)
        .repeatCount;
  }

  Future<void> _setEnabled(DhikrItem item, bool enabled) async {
    final current = _overrides!;
    final hidden = {...current.hiddenDhikrIds};
    if (enabled) {
      hidden.remove(item.id);
    } else {
      final enabledCount = _items
          .where((entry) => !hidden.contains(entry.id))
          .length;
      if (enabledCount <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب إبقاء ذكر واحد على الأقل')),
        );
        return;
      }
      hidden.add(item.id);
    }
    await _save(_with(hidden: hidden));
  }

  Future<void> _setRepeatCount(DhikrItem item, int count) async {
    if (count < 1 || count > 100) return;
    final counts = {..._overrides!.repeatCountOverrides};
    if (count == _originalCount(item)) {
      counts.remove(item.id);
    } else {
      counts[item.id] = count;
    }
    await _save(_with(counts: counts));
  }

  Future<void> _editRepeatCount(DhikrItem item) async {
    final current = (_overrides!.repeatCountOverrides[item.id] ??
            item.repeatCount)
        .clamp(1, 100)
        .toInt();
    var selected = current;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل عدد التكرار'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'العدد الحالي: ${ArabicNumerals.integer(current)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'العدد الجديد',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: selected > 1
                        ? () => setDialogState(() => selected--)
                        : null,
                    tooltip: 'تقليل العدد',
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: 88,
                    child: Text(
                      ArabicNumerals.integer(selected),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: selected < 100
                        ? () => setDialogState(() => selected++)
                        : null,
                    tooltip: 'زيادة العدد',
                    icon: const RafiqiSvgIcon(RafiqiIcons.add, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'يمكن اختيار عدد من ١ إلى ١٠٠',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) await _setRepeatCount(item, result);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final items = [..._items];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _items = items);
    await _save(_with(order: items.map((item) => item.id).toList()));
  }

  Future<void> _addDhikr() async {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var count = 1;
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة ذكر'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: textController,
                  minLines: 2,
                  maxLines: 5,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: AppFonts.reading,
                    fontSize: 18,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'نص الذكر',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اكتب نص الذكر أولًا'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('عدد المرات'),
                    const Spacer(),
                    IconButton(
                      onPressed: count > 1
                          ? () => setDialogState(() => count--)
                          : null,
                      tooltip: 'تقليل العدد',
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        ArabicNumerals.integer(count),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: count < 100
                          ? () => setDialogState(() => count++)
                          : null,
                      tooltip: 'زيادة العدد',
                      icon: const RafiqiSvgIcon(RafiqiIcons.add, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(dialogContext, (textController.text.trim(), count));
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
    textController.dispose();
    if (result == null || !mounted) return;
    final added = UserAddedDhikr(
      id: 'user_${widget.category.id}_${DateTime.now().microsecondsSinceEpoch}',
      text: result.$1,
      repeatCount: result.$2,
    );
    final item = DhikrItem(
      id: added.id,
      order: _items.length,
      category: widget.category.id,
      text: added.text,
      repeatCount: added.repeatCount,
      entryType: DhikrEntryType.single,
    );
    final items = [..._items, item];
    setState(() => _items = items);
    await _save(
      _with(
        added: [..._overrides!.addedDhikrItems, added],
        order: items.map((entry) => entry.id).toList(),
      ),
    );
  }

  Future<void> _removeAdded(DhikrItem item) async {
    final hiddenBeforeRemoval = _overrides!.hiddenDhikrIds;
    final enabledCount = _items
        .where((entry) => !hiddenBeforeRemoval.contains(entry.id))
        .length;
    if (!hiddenBeforeRemoval.contains(item.id) && enabledCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إبقاء ذكر واحد على الأقل')),
      );
      return;
    }
    final items = _items.where((entry) => entry.id != item.id).toList();
    final hidden = {..._overrides!.hiddenDhikrIds}..remove(item.id);
    final counts = {..._overrides!.repeatCountOverrides}..remove(item.id);
    setState(() => _items = items);
    await _save(
      _with(
        hidden: hidden,
        counts: counts,
        order: items.map((entry) => entry.id).toList(),
        added: _overrides!.addedDhikrItems
            .where((entry) => entry.id != item.id)
            .toList(),
      ),
    );
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة الإعدادات الأصلية؟'),
        content: const Text(
          'سيُستعاد الترتيب والعدد الأصليان، وتظهر جميع الأذكار، وتُحذف الأذكار التي أضفتها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('العودة للأصل'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.clear(widget.category.id);
    if (!mounted) return;
    setState(() {
      _overrides = const AdhkarCollectionOverrides();
      _items = [...widget.category.items];
      _isReordering = false;
    });
  }

  Widget _buildNormalList(AdhkarCollectionOverrides overrides) {
    final visible = _items
        .where((item) => !overrides.hiddenDhikrIds.contains(item.id))
        .toList();
    final hidden = _items
        .where((item) => overrides.hiddenDhikrIds.contains(item.id))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      children: [
        _SectionLabel(title: 'الأذكار الظاهرة', count: visible.length),
        for (final item in visible) ...[
          _buildItemTile(item, overrides, isReordering: false),
          const SizedBox(height: 10),
        ],
        if (hidden.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionLabel(title: 'الأذكار المخفية', count: hidden.length),
          for (final item in hidden) ...[
            _buildItemTile(item, overrides, isReordering: false),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _buildReorderList(AdhkarCollectionOverrides overrides) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      buildDefaultDragHandles: false,
      itemCount: _items.length,
      onReorder: _reorder,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildItemTile(
            item,
            overrides,
            isReordering: true,
            reorderIndex: index,
          ),
        );
      },
    );
  }

  Widget _buildItemTile(
    DhikrItem item,
    AdhkarCollectionOverrides overrides, {
    required bool isReordering,
    int? reorderIndex,
  }) {
    final enabled = !overrides.hiddenDhikrIds.contains(item.id);
    final count = overrides.repeatCountOverrides[item.id] ?? item.repeatCount;
    final added = _isAdded(item.id);
    return _CustomizationItemTile(
      item: item,
      count: count,
      enabled: enabled,
      isAdded: added,
      isReordering: isReordering,
      reorderIndex: reorderIndex,
      onEditCount: () => _editRepeatCount(item),
      onHide: () => _setEnabled(item, false),
      onRestore: () => _setEnabled(item, true),
      onDelete: added ? () => _removeAdded(item) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final overrides = _overrides;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text('تخصيص ${widget.category.title}')),
      body: overrides == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isReordering
                              ? 'اسحب الأذكار لوضعها بالترتيب المناسب لك'
                              : 'عدّل العدد أو أخفِ ذكرًا دون تغيير المحتوى الأصلي',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                height: 1.45,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => setState(
                          () => _isReordering = !_isReordering,
                        ),
                        icon: Icon(
                          _isReordering
                              ? Icons.check_rounded
                              : Icons.swap_vert_rounded,
                          size: 19,
                        ),
                        label: Text(_isReordering ? 'تم' : 'ترتيب'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isReordering
                      ? _buildReorderList(overrides)
                      : _buildNormalList(overrides),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final addButton = FilledButton.icon(
                          onPressed: _addDhikr,
                          icon: const RafiqiSvgIcon(
                            RafiqiIcons.add,
                            size: 20,
                          ),
                          label: const Text('إضافة ذكر'),
                        );
                        final resetButton = OutlinedButton.icon(
                          onPressed: overrides.isEmpty ? null : _reset,
                          icon: const RafiqiSvgIcon(
                            RafiqiIcons.reset,
                            size: 20,
                          ),
                          label: const Text('العودة للأصل'),
                        );
                        if (constraints.maxWidth < 350) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              addButton,
                              const SizedBox(height: 8),
                              resetButton,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: addButton),
                            const SizedBox(width: 10),
                            Expanded(child: resetButton),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              ArabicNumerals.integer(count),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomizationItemTile extends StatelessWidget {
  const _CustomizationItemTile({
    required this.item,
    required this.count,
    required this.enabled,
    required this.isAdded,
    required this.isReordering,
    required this.onEditCount,
    required this.onHide,
    required this.onRestore,
    required this.onDelete,
    this.reorderIndex,
  });

  final DhikrItem item;
  final int count;
  final bool enabled;
  final bool isAdded;
  final bool isReordering;
  final int? reorderIndex;
  final VoidCallback onEditCount;
  final VoidCallback onHide;
  final VoidCallback onRestore;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Material(
      color: enabled ? colors.surface : colors.surfaceSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: enabled && !isReordering ? onEditCount : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isReordering)
                    ReorderableDragStartListener(
                      index: reorderIndex!,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(2, 8, 8, 8),
                        child: Icon(Icons.drag_handle_rounded),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      item.text,
                      maxLines: isReordering ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.reading,
                        fontSize: 18,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (isAdded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'مضاف',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (isAdded) const SizedBox(width: 6),
                  if (!enabled)
                    Text(
                      'مخفي',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const Spacer(),
                  if (isReordering)
                    Text(
                      'التكرار ${ArabicNumerals.integer(count)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    )
                  else ...[
                    if (enabled)
                      TextButton.icon(
                        onPressed: onEditCount,
                        icon: const Icon(Icons.repeat_rounded, size: 18),
                        label: Text('التكرار ${ArabicNumerals.integer(count)}'),
                      ),
                    if (enabled)
                      IconButton(
                        onPressed: onHide,
                        tooltip: 'إخفاء الذكر',
                        icon: const Icon(Icons.visibility_off_outlined),
                      )
                    else
                      TextButton.icon(
                        onPressed: onRestore,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('استعادة'),
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        tooltip: 'حذف الذكر المضاف',
                        icon: const RafiqiSvgIcon(
                          RafiqiIcons.delete,
                          size: 20,
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
