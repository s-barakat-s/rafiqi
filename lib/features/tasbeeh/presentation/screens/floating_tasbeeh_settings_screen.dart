import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_launcher.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_messenger.dart';
import 'package:tasbeh/features/tasbeeh/data/tasbeeh_local_storage.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/auto_hide_selector.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/soft_section_card.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/target_selector.dart';

class FloatingTasbeehSettingsScreen extends StatefulWidget {
  const FloatingTasbeehSettingsScreen({
    required this.initialSettings,
    required this.state,
    super.key,
  });

  final TasbeehSettings initialSettings;
  final TasbeehState state;

  @override
  State<FloatingTasbeehSettingsScreen> createState() =>
      _FloatingTasbeehSettingsScreenState();
}

class _FloatingTasbeehSettingsScreenState
    extends State<FloatingTasbeehSettingsScreen> {
  late TasbeehSettings _settings = widget.initialSettings;

  void _close(TasbeehSettings settings) {
    _settings = settings;
    Navigator.of(context).pop(_settings);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_settings);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_settings),
          ),
        ),
        body: FloatingTasbeehSettingsPanel(
          initialSettings: _settings,
          state: widget.state,
          onSettingsChanged: (settings) => _settings = settings,
          onDone: _close,
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.settings,
    required this.state,
    required this.onChangeTarget,
    required this.onSettingsChanged,
    super.key,
  });

  final TasbeehSettings settings;
  final TasbeehState state;
  final ValueChanged<TasbeehTarget> onChangeTarget;
  final ValueChanged<TasbeehSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return FloatingTasbeehSettingsPanel(
      initialSettings: settings,
      state: state,
      onChangeTarget: onChangeTarget,
      onSettingsChanged: onSettingsChanged,
    );
  }
}

class FloatingTasbeehSettingsPanel extends StatefulWidget {
  const FloatingTasbeehSettingsPanel({
    required this.initialSettings,
    required this.state,
    required this.onSettingsChanged,
    this.onChangeTarget,
    this.onDone,
    super.key,
  });

  final TasbeehSettings initialSettings;
  final TasbeehState state;
  final ValueChanged<TasbeehSettings> onSettingsChanged;
  final ValueChanged<TasbeehTarget>? onChangeTarget;
  final ValueChanged<TasbeehSettings>? onDone;

  @override
  State<FloatingTasbeehSettingsPanel> createState() =>
      _FloatingTasbeehSettingsPanelState();
}

class _FloatingTasbeehSettingsPanelState
    extends State<FloatingTasbeehSettingsPanel> {
  final _storage = TasbeehLocalStorage();
  late TasbeehSettings _settings = widget.initialSettings;

  @override
  void didUpdateWidget(covariant FloatingTasbeehSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSettings != widget.initialSettings) {
      _settings = widget.initialSettings;
    }
  }

  Future<void> _updateSettings(
    TasbeehSettings settings, {
    bool restartOverlay = false,
  }) async {
    final wasOverlayActive = await FlutterOverlayWindow.isActive();
    await _storage.saveSettings(settings);
    if (!mounted) return;

    setState(() => _settings = settings);
    widget.onSettingsChanged(settings);

    if (!wasOverlayActive) {
      return;
    }

    if (restartOverlay) {
      await TasbeehOverlayLauncher.restartOverlay(settings: settings);
    }

    await TasbeehOverlayMessenger.sendSettingsUpdate(
      settings,
      source: TasbeehOverlayMessenger.sourceApp,
    );
    await TasbeehOverlayMessenger.sendStateUpdate(
      widget.state,
      source: TasbeehOverlayMessenger.sourceApp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        children: [
        const Text(
          'الإعدادات',
          style: TextStyle(
            color: Color(0xFF2F6048),
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'تحكم في هدف التسبيح وشكل السبحة العائمة',
          style: TextStyle(
            color: Color(0xFF6F7F73),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 22),
        if (widget.onChangeTarget != null)
          _SettingsSectionCard(
            title: 'إعدادات التسبيح',
            children: [
              TargetSelector(
                selectedTarget: TasbeehTarget.fromMode(
                  widget.state.targetMode,
                ),
                title: 'الهدف الافتراضي',
                onChanged: widget.onChangeTarget!,
              ),
            ],
          ),
        _SettingsSectionCard(
          title: 'إعدادات السبحة العائمة',
          children: [
            _SettingsSlider(
              label: 'حجم السبحة العائمة',
              valueLabel: '${(_settings.sizeScale * 100).round()}%',
              value: _settings.sizeScale,
              min: TasbeehSettings.minSizeScale,
              max: TasbeehSettings.maxSizeScale,
              divisions: 28,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(sizeScale: value);
                });
                widget.onSettingsChanged(_settings);
              },
              onChangeEnd: (value) => _updateSettings(
                _settings.copyWith(sizeScale: value),
                restartOverlay: true,
              ),
            ),
            const SizedBox(height: 18),
            _SettingsChoiceChips(
              label: 'جانب الظهور',
              value: _settings.floatingSide,
              options: const {
                TasbeehSettings.sideRight: 'يمين',
                TasbeehSettings.sideLeft: 'يسار',
              },
              onChanged: (value) => _updateSettings(
                _settings.copyWith(floatingSide: value),
                restartOverlay: value != _settings.floatingSide,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'الشفافية ${(_settings.opacity * 100).round()}%',
              style: _labelStyle,
            ),
            Slider(
              value: _settings.opacity,
              min: 0.4,
              max: 1,
              divisions: 6,
              label: '${(_settings.opacity * 100).round()}%',
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(opacity: value)),
            ),
            const SizedBox(height: 18),
            AutoHideSelector(
              autoCollapseSeconds: _settings.autoCollapseSeconds == 0
                  ? null
                  : _settings.autoCollapseSeconds,
              onChanged: (seconds) => _updateSettings(
                _settings.copyWith(autoCollapseSeconds: seconds ?? 0),
              ),
            ),
          ],
        ),
        _SettingsSectionCard(
          title: 'الألوان والمظهر',
          children: [
            _SettingsChoiceChips(
              label: 'لون التمييز',
              value: _settings.accentColor,
              options: const {
                TasbeehSettings.accentGreen: 'أخضر',
                TasbeehSettings.accentGold: 'ذهبي',
                TasbeehSettings.accentBlue: 'أزرق',
                TasbeehSettings.accentPurple: 'بنفسجي',
                TasbeehSettings.accentRed: 'أحمر',
                TasbeehSettings.accentWhite: 'أبيض',
              },
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(accentColor: value)),
            ),
            const SizedBox(height: 18),
            _SettingsChoiceChips(
              label: 'خلفية العداد',
              value: _settings.backgroundIntensity,
              options: const {
                TasbeehSettings.backgroundVeryDark: 'داكن جدًا',
                TasbeehSettings.backgroundDark: 'داكن',
                TasbeehSettings.backgroundSoftDark: 'ناعم',
              },
              onChanged: (value) => _updateSettings(
                _settings.copyWith(backgroundIntensity: value),
              ),
            ),
            const SizedBox(height: 18),
            _SettingsChoiceChips(
              label: 'الإطار',
              value: _settings.borderStyle,
              options: const {
                TasbeehSettings.borderNone: 'بدون',
                TasbeehSettings.borderSubtle: 'ناعم',
                TasbeehSettings.borderBright: 'لامع',
              },
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(borderStyle: value)),
            ),
          ],
        ),
        _SettingsSectionCard(
          title: 'الحبات والأرقام',
          children: [
            _SettingsSwitch(
              value: _settings.showBeads,
              title: 'إظهار الحبات',
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(showBeads: value)),
            ),
            _SettingsChoiceChips(
              label: 'حجم الحبات',
              value: _settings.beadSize,
              options: const {
                TasbeehSettings.beadSmall: 'صغير',
                TasbeehSettings.beadMedium: 'متوسط',
                TasbeehSettings.beadLarge: 'كبير',
              },
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(beadSize: value)),
            ),
            _SettingsSwitch(
              value: _settings.showTotal,
              title: 'إظهار الإجمالي',
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(showTotal: value)),
            ),
            _SettingsSwitch(
              value: _settings.showDivider && _settings.showTotal,
              title: 'إظهار الفاصل',
              onChanged: _settings.showTotal
                  ? (value) =>
                        _updateSettings(_settings.copyWith(showDivider: value))
                  : null,
            ),
          ],
        ),
        _SettingsSectionCard(
          title: 'مقبض الإخفاء',
          children: [
            _SettingsChoiceChips(
              label: 'لون المقبض',
              value: _settings.handleColorMode,
              options: const {
                TasbeehSettings.handleWhite: 'أبيض',
                TasbeehSettings.handleAccent: 'لون التمييز',
                TasbeehSettings.handleGray: 'رمادي',
              },
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(handleColorMode: value)),
            ),
            const SizedBox(height: 18),
            _SettingsChoiceChips(
              label: 'السماكة',
              value: _settings.handleThickness,
              options: const {
                TasbeehSettings.handleThin: 'رفيع',
                TasbeehSettings.handleMedium: 'متوسط',
                TasbeehSettings.handleThick: 'سميك',
              },
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(handleThickness: value)),
            ),
            const SizedBox(height: 18),
            _SettingsChoiceChips(
              label: 'الارتفاع',
              value: _settings.handleHeight,
              options: const {
                TasbeehSettings.handleShort: 'قصير',
                TasbeehSettings.handleMedium: 'متوسط',
                TasbeehSettings.handleTall: 'طويل',
              },
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(handleHeight: value)),
            ),
          ],
        ),
        _SettingsSectionCard(
          title: 'التفاعل',
          children: [
            _SettingsSwitch(
              value: _settings.hapticFeedbackEnabled,
              title: 'اهتزاز خفيف',
              onChanged: (value) => _updateSettings(
                _settings.copyWith(hapticFeedbackEnabled: value),
              ),
            ),
            _SettingsSwitch(
              value: _settings.tapAnimationEnabled,
              title: 'حركة عند الضغط',
              onChanged: (value) => _updateSettings(
                _settings.copyWith(tapAnimationEnabled: value),
              ),
            ),
          ],
        ),
        _SettingsSectionCard(
          title: 'التطبيق',
          children: const [
            _InfoRow(
              icon: Icons.language_rounded,
              label: 'اللغة',
              value: 'العربية',
            ),
            _InfoRow(
              icon: Icons.palette_rounded,
              label: 'الثيم',
              value: 'هادئ أخضر',
            ),
            _InfoRow(
              icon: Icons.info_rounded,
              label: 'حول التطبيق',
              value: 'سبحة رقمية عائمة',
            ),
          ],
        ),
        if (widget.onDone != null) ...[
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => widget.onDone?.call(_settings),
            child: const Text('تم'),
          ),
        ],
      ],
      ),
    );
  }
}

const _labelStyle = TextStyle(
  color: Color(0xFF2F6048),
  fontWeight: FontWeight.w900,
  fontSize: 16,
);

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SoftSectionCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2F6048),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsChoiceChips extends StatelessWidget {
  const _SettingsChoiceChips({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final selected = entry.key == value;
            return ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              showCheckmark: false,
              selectedColor: const Color(0xFF2F6048),
              labelStyle: TextStyle(
                color: selected
                    ? const Color(0xFFFFFBF0)
                    : const Color(0xFF6F7F73),
                fontWeight: FontWeight.w800,
              ),
              onSelected: (_) => onChanged(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  const _SettingsSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label $valueLabel', style: _labelStyle),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(min * 100).round()}%'),
            Text('${(max * 100).round()}%'),
          ],
        ),
      ],
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.value,
    required this.title,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: const Color(0xFF2F6048),
      value: value,
      title: Text(title, style: _labelStyle),
      onChanged: onChanged,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6EA676)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: _labelStyle)),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF6F7F73),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
