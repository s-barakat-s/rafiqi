part of '../../../home/presentation/home_screen.dart';

enum _DailyTaskAddChoice { custom, readyMade }

class _AddTaskChoiceSheet extends StatelessWidget {
  const _AddTaskChoiceSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'إضافة عمل يومي',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.selected.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.spa_outlined, color: colors.secondary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'أحب الأعمال إلى الله أدومها وإن قل، اختر أعمالاً يسهل عليك المداومة عليها، ولا تكثر على نفسك حتى لا تنقطع.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            onTap: () => Navigator.pop(context, _DailyTaskAddChoice.custom),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.outline),
            ),
            leading: const RafiqiSvgIcon(RafiqiIcons.edit),
            title: const Text('إضافة مهمة من عندك'),
          ),
          const SizedBox(height: 10),
          ListTile(
            onTap: () => Navigator.pop(context, _DailyTaskAddChoice.readyMade),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.outline),
            ),
            leading: const Icon(Icons.library_add_outlined),
            title: const Text('إضافة من المهام الجاهزة'),
          ),
        ],
      ),
    );
  }
}

class _ReadyTaskPickerSheet extends StatefulWidget {
  const _ReadyTaskPickerSheet({required this.categories});

  final List<AdhkarCategory> categories;

  @override
  State<_ReadyTaskPickerSheet> createState() => _ReadyTaskPickerSheetState();
}

class _ReadyTaskPickerSheetState extends State<_ReadyTaskPickerSheet> {
  final _store = DailyWirdRepository.instance;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openTasbeehConfig() async {
    final task = await showModalBottomSheet<DailyTask>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _TasbeehTaskConfigSheet(),
    );
    if (task != null && mounted) {
      Navigator.pop(context, task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final matches = widget.categories
        .where((category) => category.title.contains(_query.trim()))
        .toList();
    final builtIn = matches
        .where((category) => category.kind != AdhkarCategoryKind.custom)
        .toList();
    final custom = matches
        .where((category) => category.kind == AdhkarCategoryKind.custom)
        .toList();

    return FractionallySizedBox(
      heightFactor: .88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'المهام الجاهزة',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'بحث في الأذكار والمهام...',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _PickerSectionTitle('التسبيح', color: colors.textSecondary),
                  ListTile(
                    onTap: _openTasbeehConfig,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: colors.outline.withValues(alpha: .6),
                      ),
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.counterSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: RafiqiSvgIcon(
                        RafiqiIcons.tasbeeh,
                        size: 22,
                        color: colors.primary,
                      ),
                    ),
                    title: const Text(
                      'تسبيح بهدف محدد',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('اختر الذكر والهدف المطلوب'),
                    trailing: const RafiqiSvgIcon(RafiqiIcons.add, size: 20),
                  ),
                  const SizedBox(height: 16),
                  if (builtIn.isNotEmpty) ...[
                    _PickerSectionTitle('الأذكار', color: colors.textSecondary),
                    for (final category in builtIn)
                      _ReadyCollectionTile(
                        category: category,
                        isAlreadyAdded:
                            _store.hasLinkedCollection(category.id),
                        onSelect: () {
                          Navigator.pop(
                            context,
                            DailyTask(
                              id: 'linked_adhkar_${category.id}',
                              title: category.title,
                              type: 'ذكر',
                              taskType: DailyTask.adhkarCollectionTaskType,
                              collectionId: category.id,
                            ),
                          );
                        },
                      ),
                  ],
                  if (custom.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _PickerSectionTitle(
                      'أذكاري الخاصة',
                      color: colors.textSecondary,
                    ),
                    for (final category in custom)
                      _ReadyCollectionTile(
                        category: category,
                        isAlreadyAdded:
                            _store.hasLinkedCollection(category.id),
                        onSelect: () {
                          Navigator.pop(
                            context,
                            DailyTask(
                              id: 'linked_adhkar_${category.id}',
                              title: category.title,
                              type: 'ذكر',
                              taskType: DailyTask.adhkarCollectionTaskType,
                              collectionId: category.id,
                            ),
                          );
                        },
                      ),
                  ],
                  if (matches.isEmpty && _query.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 36),
                      child: Center(child: Text('لا توجد نتائج مطابقة')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSectionTitle extends StatelessWidget {
  const _PickerSectionTitle(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

class _ReadyCollectionTile extends StatelessWidget {
  const _ReadyCollectionTile({
    required this.category,
    required this.isAlreadyAdded,
    required this.onSelect,
  });

  final AdhkarCategory category;
  final bool isAlreadyAdded;
  final VoidCallback onSelect;

  String _iconForCategory() {
    return switch (category.id) {
      'morning' => RafiqiIcons.morningAdhkar,
      'evening' => RafiqiIcons.eveningAdhkar,
      'sleep' => RafiqiIcons.sleepAdhkar,
      'after_prayer' => RafiqiIcons.afterPrayerAdhkar,
      _ => category.kind == AdhkarCategoryKind.custom
          ? RafiqiIcons.customWird
          : RafiqiIcons.adhkar,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: isAlreadyAdded ? null : onSelect,
        enabled: !isAlreadyAdded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: colors.outline.withValues(alpha: isAlreadyAdded ? .3 : .5),
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.counterSurface.withValues(alpha: isAlreadyAdded ? .4 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: RafiqiSvgIcon(
            _iconForCategory(),
            size: 20,
            color: isAlreadyAdded ? colors.outlineStrong : colors.primary,
          ),
        ),
        title: Text(
          category.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isAlreadyAdded ? colors.textSecondary : colors.textPrimary,
          ),
        ),
        subtitle: Text(
          isAlreadyAdded
              ? 'مضافة بالفعل'
              : '${ArabicNumerals.integer(category.items.length)} أذكار',
          style: TextStyle(
            color: isAlreadyAdded ? colors.outlineStrong : colors.textSecondary,
          ),
        ),
        trailing: isAlreadyAdded
            ? const Icon(Icons.check_rounded, size: 18)
            : const RafiqiSvgIcon(RafiqiIcons.add, size: 20),
      ),
    );
  }
}

class _TasbeehTaskConfigSheet extends StatefulWidget {
  const _TasbeehTaskConfigSheet();

  @override
  State<_TasbeehTaskConfigSheet> createState() =>
      _TasbeehTaskConfigSheetState();
}

class _TasbeehTaskConfigSheetState extends State<_TasbeehTaskConfigSheet> {
  final _customPhraseController = TextEditingController();
  final _customTargetController = TextEditingController();

  String _selectedPhraseId = TasbeehPhrase.defaultPhrases.first.id;
  String _selectedPhraseText = TasbeehPhrase.defaultPhrases.first.text;
  bool _isCustomPhrase = false;

  int _selectedTarget = 33;
  bool _isCustomTarget = false;

  @override
  void dispose() {
    _customPhraseController.dispose();
    _customTargetController.dispose();
    super.dispose();
  }

  String get _effectivePhraseText {
    if (_isCustomPhrase) {
      return _customPhraseController.text.trim();
    }
    return _selectedPhraseText;
  }

  int get _effectiveTarget {
    if (_isCustomTarget) {
      final parsed = int.tryParse(_customTargetController.text.trim());
      return (parsed != null && parsed > 0) ? parsed : 0;
    }
    return _selectedTarget;
  }

  Future<void> _save() async {
    final phrase = _effectivePhraseText;
    final target = _effectiveTarget;

    if (phrase.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد أو كتابة نص الذكر')),
      );
      return;
    }

    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد هدف عددي أكبر من صفر')),
      );
      return;
    }

    final phraseId = _isCustomPhrase
        ? (await TasbeehRepository().addCustomPhrase(phrase)).id
        : _selectedPhraseId;

    if (!mounted) return;

    final formattedCount = ArabicNumerals.integer(target);
    final title = '$phrase × $formattedCount';

    final task = DailyTask(
      id: 'linked_tasbeeh_${phraseId}_$target',
      title: title,
      type: 'تسبيح',
      goal: target,
      taskType: DailyTask.tasbeehTargetTaskType,
      tasbeehPhraseId: phraseId,
      tasbeehPhraseText: phrase,
      tasbeehTargetCount: target,
    );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final previewText = _effectivePhraseText.isNotEmpty && _effectiveTarget > 0
        ? '$_effectivePhraseText × ${ArabicNumerals.integer(_effectiveTarget)}'
        : '';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تسبيح بهدف محدد',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '١. اختر الذكر',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final phrase in TasbeehPhrase.defaultPhrases)
                  ChoiceChip(
                    label: Text(phrase.text),
                    selected: !_isCustomPhrase && _selectedPhraseId == phrase.id,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isCustomPhrase = false;
                          _selectedPhraseId = phrase.id;
                          _selectedPhraseText = phrase.text;
                        });
                      }
                    },
                  ),
                ChoiceChip(
                  label: const Text('ذكر مخصص'),
                  selected: _isCustomPhrase,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isCustomPhrase = true;
                      });
                    }
                  },
                ),
              ],
            ),
            if (_isCustomPhrase) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customPhraseController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'اكتب الذكر المخصص',
                  hintText: 'مثال: أستغفر الله وأتوب إليه',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              '٢. اختر الهدف العددي',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final count in [33, 100])
                  ChoiceChip(
                    label: Text(ArabicNumerals.integer(count)),
                    selected: !_isCustomTarget && _selectedTarget == count,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isCustomTarget = false;
                          _selectedTarget = count;
                        });
                      }
                    },
                  ),
                ChoiceChip(
                  label: const Text('عدد مخصص'),
                  selected: _isCustomTarget,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isCustomTarget = true;
                      });
                    }
                  },
                ),
              ],
            ),
            if (_isCustomTarget) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customTargetController,
                keyboardType: TextInputType.number,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'العدد المطلوب',
                  hintText: 'مثال: 50',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (previewText.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outline.withValues(alpha: .5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: colors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اسم العمل: $previewText',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _save,
                child: const Text('إضافة العمل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();
  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final _goalController = TextEditingController();
  String _type = 'ذكر';
  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(
      context,
      DailyTask(
        id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        type: _type,
        goal: int.tryParse(_goalController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'إضافة عمل يومي',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم العمل',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'النوع',
                border: OutlineInputBorder(),
              ),
              items:
                  const [
                        'ذكر',
                        'قرآن',
                        'صلاة على النبي',
                        'استغفار',
                        'دعاء',
                        'عمل مخصص',
                      ]
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الهدف العددي (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _save,
                child: const Text('حفظ العمل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
