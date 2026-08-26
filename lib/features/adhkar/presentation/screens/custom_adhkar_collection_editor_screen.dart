import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/data/repositories/custom_adhkar_collections_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/custom_adhkar_collection.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';

class CustomAdhkarCollectionEditorScreen extends StatefulWidget {
  const CustomAdhkarCollectionEditorScreen({this.collection, super.key});

  final CustomAdhkarCollection? collection;

  @override
  State<CustomAdhkarCollectionEditorScreen> createState() =>
      _CustomAdhkarCollectionEditorScreenState();
}

class _CustomAdhkarCollectionEditorScreenState
    extends State<CustomAdhkarCollectionEditorScreen> {
  final _repository = CustomAdhkarCollectionsRepository.instance;
  final _dailyWird = DailyWirdRepository.instance;
  late final TextEditingController _nameController;
  late final List<_DhikrDraft> _items;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection?.name);
    _items = widget.collection == null
        ? [_DhikrDraft.create()]
        : widget.collection!.items.map(_DhikrDraft.fromItem).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_DhikrDraft.create()));

  void _removeItem(int index) {
    if (_items.length == 1) return;
    final removed = _items.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final validItems = _items
        .where((item) => item.text.text.trim().isNotEmpty && item.count >= 1)
        .toList();
    if (name.isEmpty || validItems.length != _items.length || validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل اسم الورد ونص كل ذكر وعددًا صحيحًا لا يقل عن ١'),
        ),
      );
      return;
    }
    final now = DateTime.now();
    final existing = widget.collection;
    final collection = CustomAdhkarCollection(
      id: existing?.id ?? 'custom_collection_${now.microsecondsSinceEpoch}',
      name: name,
      items: [
        for (var index = 0; index < validItems.length; index++)
          CustomDhikrItem(
            id: validItems[index].id,
            text: validItems[index].text.text.trim(),
            repeatCount: validItems[index].count,
            order: index,
          ),
      ],
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.save(collection);
    if (existing != null && existing.name != name) {
      await _dailyWird.initialize();
      await _dailyWird.renameLinkedCollectionTask(existing.id, name);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final collection = widget.collection;
    if (collection == null) return;
    await _dailyWird.initialize();
    final linked = _dailyWird.hasLinkedCollection(collection.id);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الورد الخاص؟'),
        content: Text(
          linked
              ? 'سيُحذف الورد وتُزال مهمته المرتبطة من ورد اليوم. لن تتغير السجلات التاريخية.'
              : 'سيُحذف هذا الورد نهائيًا من مجموعاتك الخاصة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (linked) await _dailyWird.removeLinkedCollectionTask(collection.id);
    await _repository.delete(collection.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection == null ? 'إنشاء ورد خاص' : 'تعديل الورد'),
        actions: [
          if (widget.collection != null)
            IconButton(
              onPressed: _delete,
              tooltip: 'حذف الورد',
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'اسم الورد',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < _items.length; index++) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'ذكر ${ArabicNumerals.integer(index + 1)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _items.length > 1
                            ? () => _removeItem(index)
                            : null,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _items[index].text,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'نص الذكر',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('عدد المرات'),
                      const Spacer(),
                      IconButton(
                        onPressed: _items[index].count > 1
                            ? () => setState(() => _items[index].count--)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Text(
                        ArabicNumerals.integer(_items[index].count),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _items[index].count++),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة ذكر آخر'),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: _save, child: const Text('حفظ الورد')),
        ],
      ),
    );
  }
}

class _DhikrDraft {
  _DhikrDraft({required this.id, required this.text, required this.count});

  factory _DhikrDraft.create() => _DhikrDraft(
    id: 'custom_dhikr_${DateTime.now().microsecondsSinceEpoch}',
    text: TextEditingController(),
    count: 1,
  );

  factory _DhikrDraft.fromItem(CustomDhikrItem item) => _DhikrDraft(
    id: item.id,
    text: TextEditingController(text: item.text),
    count: item.repeatCount,
  );

  final String id;
  final TextEditingController text;
  int count;

  void dispose() => text.dispose();
}
