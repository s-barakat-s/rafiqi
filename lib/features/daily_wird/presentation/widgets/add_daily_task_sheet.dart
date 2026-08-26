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
                    'أحب الأعمال إلى الله أدومها وإن قل، اختر أعمالًا يسهل عليك المداومة عليها، ولا تكثر على نفسك حتى لا تنقطع.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            onTap: () =>
                Navigator.pop(context, _DailyTaskAddChoice.custom),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.outline),
            ),
            leading: const Icon(Icons.edit_note_rounded),
            title: const Text('إضافة مهمة من عندك'),
          ),
          const SizedBox(height: 10),
          ListTile(
            onTap: () =>
                Navigator.pop(context, _DailyTaskAddChoice.readyMade),
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
  State<_ReadyTaskPickerSheet> createState() =>
      _ReadyTaskPickerSheetState();
}

class _ReadyTaskPickerSheetState extends State<_ReadyTaskPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      heightFactor: .82,
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
                hintText: 'بحث...',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (builtIn.isNotEmpty) ...[
                    _PickerSectionTitle('الأذكار', color: colors.textSecondary),
                    for (final category in builtIn)
                      _ReadyCollectionTile(category: category),
                  ],
                  if (custom.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _PickerSectionTitle(
                      'أذكاري الخاصة',
                      color: colors.textSecondary,
                    ),
                    for (final category in custom)
                      _ReadyCollectionTile(category: category),
                  ],
                  if (matches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 36),
                      child: Center(child: Text('لا توجد نتائج')),
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
  const _ReadyCollectionTile({required this.category});

  final AdhkarCategory category;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: () => Navigator.pop(context, category),
    leading: Icon(
      category.kind == AdhkarCategoryKind.custom
          ? Icons.auto_awesome_motion_outlined
          : Icons.auto_stories_outlined,
    ),
    title: Text(category.title),
    subtitle: Text(
      '${ArabicNumerals.integer(category.items.length)} أذكار',
    ),
    trailing: const Icon(Icons.add_rounded),
  );
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
