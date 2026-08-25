import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_launcher.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_messenger.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/auto_hide_selector.dart';

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
  final _repository = TasbeehRepository();
  late TasbeehSettings _settings = widget.initialSettings;

  Future<void> _updateSettings(
    TasbeehSettings settings, {
    bool restartOverlay = false,
  }) async {
    final wasOverlayActive = await FlutterOverlayWindow.isActive();
    await _repository.saveSettings(settings);
    if (!mounted) return;

    setState(() => _settings = settings);
    if (!wasOverlayActive) return;

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

  void _previewSize(double value) {
    setState(() => _settings = _settings.copyWith(sizeScale: value));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_settings);
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_settings),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'إعدادات السبحة العائمة',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    color: colors.textPrimary,
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'اضبط طريقة ظهور العداد فوق التطبيقات',
                  style: TextStyle(color: colors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 28),
                _SettingsSection(
                  title: 'الظهور',
                  children: [
                    _SettingLabel(
                      label: 'حجم السبحة العائمة',
                      value: _sizeLabel(_settings.sizeScale),
                    ),
                    Slider(
                      value: _settings.sizeScale,
                      min: TasbeehSettings.minSizeScale,
                      max: TasbeehSettings.maxSizeScale,
                      divisions: 14,
                      label: _sizeLabel(_settings.sizeScale),
                      onChanged: _previewSize,
                      onChangeEnd: (value) => _updateSettings(
                        _settings.copyWith(sizeScale: value),
                        restartOverlay: true,
                      ),
                    ),
                    const _SettingDivider(),
                    const _SettingLabel(label: 'جانب الظهور'),
                    const SizedBox(height: 10),
                    _SideSelector(
                      value: _settings.floatingSide,
                      onChanged: (value) => _updateSettings(
                        _settings.copyWith(floatingSide: value),
                        restartOverlay: value != _settings.floatingSide,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _SettingLabel(
                      label: 'الشفافية',
                      value: _opacityLabel(_settings.opacity),
                    ),
                    Slider(
                      value: _settings.opacity,
                      min: .4,
                      max: 1,
                      divisions: 6,
                      label: _opacityLabel(_settings.opacity),
                      onChanged: (value) =>
                          _updateSettings(_settings.copyWith(opacity: value)),
                    ),
                    const _SettingDivider(),
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
                const SizedBox(height: 26),
                _SettingsSection(
                  title: 'التفاعل',
                  children: [
                    _SettingsSwitch(
                      value: _settings.hapticFeedbackEnabled,
                      title: 'اهتزاز خفيف',
                      onChanged: (value) => _updateSettings(
                        _settings.copyWith(hapticFeedbackEnabled: value),
                      ),
                    ),
                    const _SettingDivider(indent: 0),
                    _SettingsSwitch(
                      value: _settings.tapAnimationEnabled,
                      title: 'حركة خفيفة عند الضغط',
                      onChanged: (value) => _updateSettings(
                        _settings.copyWith(tapAnimationEnabled: value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sizeLabel(double value) {
    if (value < 1) return 'صغير';
    if (value < 1.55) return 'متوسط';
    return 'كبير';
  }

  String _opacityLabel(double value) {
    if (value < .62) return 'خفيفة';
    if (value < .88) return 'متوسطة';
    return 'واضحة';
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outline.withValues(alpha: .7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingLabel extends StatelessWidget {
  const _SettingLabel({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (value != null)
          Text(
            value!,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
      ],
    );
  }
}

class _SideSelector extends StatelessWidget {
  const _SideSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: TasbeehSettings.sideRight, label: Text('يمين')),
        ButtonSegment(value: TasbeehSettings.sideLeft, label: Text('يسار')),
      ],
      selected: {value},
      showSelectedIcon: false,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.textPrimary
              : colors.textSecondary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.selected
              : Colors.transparent,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: colors.outline)),
      ),
      onSelectionChanged: (selection) => onChanged(selection.first),
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
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(title),
      onChanged: onChanged,
    );
  }
}

class _SettingDivider extends StatelessWidget {
  const _SettingDivider({this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 26,
      indent: indent,
      color: context.appColors.outline.withValues(alpha: .6),
    );
  }
}
