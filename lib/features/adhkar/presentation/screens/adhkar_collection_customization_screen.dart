import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_collection_overrides_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_collection_overrides.dart';

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
    if (count < 1) return;
    final counts = {..._overrides!.repeatCountOverrides};
    if (count == _originalCount(item)) {
      counts.remove(item.id);
    } else {
      counts[item.id] = count;
    }
    await _save(_with(counts: counts));
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
    var count = 1;
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة ذكر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'نص الذكر',
                  border: OutlineInputBorder(),
                ),
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
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Text(ArabicNumerals.integer(count)),
                  IconButton(
                    onPressed: () => setDialogState(() => count++),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final text = textController.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(dialogContext, (text, count));
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
            child: const Text('استعادة'),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final overrides = _overrides;
    return Scaffold(
      appBar: AppBar(title: Text('تخصيص ${widget.category.title}')),
      body: overrides == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    buildDefaultDragHandles: false,
                    itemCount: _items.length,
                    onReorder: _reorder,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final enabled =
                          !overrides.hiddenDhikrIds.contains(item.id);
                      final count = overrides.repeatCountOverrides[item.id] ??
                          item.repeatCount;
                      return Container(
                        key: ValueKey(item.id),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: colors.divider),
                          ),
                        ),
                        child: Opacity(
                          opacity: enabled ? 1 : .55,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(Icons.drag_handle_rounded),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.text,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: AppFonts.reading,
                                        fontSize: 18,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                  if (_isAdded(item.id))
                                    IconButton(
                                      onPressed: () => _removeAdded(item),
                                      tooltip: 'حذف الذكر المضاف',
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    )
                                  else
                                    Switch(
                                      value: enabled,
                                      onChanged: (value) =>
                                          _setEnabled(item, value),
                                    ),
                                ],
                              ),
                              if (enabled)
                                Row(
                                  children: [
                                    const SizedBox(width: 42),
                                    Text(
                                      'عدد التكرار',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: count > 1
                                          ? () =>
                                                _setRepeatCount(item, count - 1)
                                          : null,
                                      icon: const Icon(Icons.remove_rounded),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Text(
                                      ArabicNumerals.integer(count),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _setRepeatCount(item, count + 1),
                                      icon: const Icon(Icons.add_rounded),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (count != _originalCount(item))
                                      TextButton(
                                        onPressed: () => _setRepeatCount(
                                          item,
                                          _originalCount(item),
                                        ),
                                        child: const Text('الأصلي'),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _addDhikr,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('إضافة ذكر'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: overrides.isEmpty ? null : _reset,
                          icon: const Icon(Icons.restore_rounded),
                          label: const Text('استعادة'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
