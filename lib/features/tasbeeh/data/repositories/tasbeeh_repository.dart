import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_daily_record.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/manual_tasbeeh_entry.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';

class TasbeehRepository {
  static const _stateV2Key = 'tasbeeh.state.v2';
  static const _stateRevisionKey = 'tasbeeh.stateRevision.v1';
  static const _processedOperationIdsKey = 'tasbeeh.processedOperations.v1';
  static const _dailyRecordsKey = 'tasbeeh.dailyRecords.v1';
  static const _dailyRecordIndexKey = 'tasbeeh.dailyRecords.v2.index';
  static const _dailyRecordPrefix = 'tasbeeh.dailyRecords.v2.';
  static const _customPhrasesKey = 'tasbeeh.customPhrases.v1';
  static const _manualEntriesKey = 'tasbeeh.manualEntries.v1';
  static const _manualCountPrefix = 'tasbeeh.manualCount.v1.';
  static const _currentCountKey = 'tasbeeh.currentCount';
  static const _totalCountKey = 'tasbeeh.totalCount';
  static const _dailyTotalKey = 'tasbeeh.dailyTotal';
  static const _dailyDateKey = 'tasbeeh.dailyDate';
  static const _targetModeKey = 'tasbeeh.targetMode';
  static const _autoCollapseSecondsKey = 'tasbeeh.autoCollapseSeconds';
  static const _opacityKey = 'tasbeeh.opacity';
  static const _sizeScaleKey = 'tasbeeh.sizeScale';
  static const _counterScaleKey = 'tasbeeh.counterScale';
  static const _collapsedHandleScaleKey = 'tasbeeh.collapsedHandleScale';
  static const _collapsedHandleOpacityKey = 'tasbeeh.collapsedHandleOpacity';
  static const _sizePresetKey = 'tasbeeh.sizePreset';
  static const _accentColorKey = 'tasbeeh.accentColor';
  static const _backgroundIntensityKey = 'tasbeeh.backgroundIntensity';
  static const _borderStyleKey = 'tasbeeh.borderStyle';
  static const _showBeadsKey = 'tasbeeh.showBeads';
  static const _beadSizeKey = 'tasbeeh.beadSize';
  static const _showTotalKey = 'tasbeeh.showTotal';
  static const _showDividerKey = 'tasbeeh.showDivider';
  static const _handleColorModeKey = 'tasbeeh.handleColorMode';
  static const _handleThicknessKey = 'tasbeeh.handleThickness';
  static const _handleHeightKey = 'tasbeeh.handleHeight';
  static const _hapticFeedbackEnabledKey = 'tasbeeh.hapticFeedbackEnabled';
  static const _tapAnimationEnabledKey = 'tasbeeh.tapAnimationEnabled';
  static const _floatingSideKey = 'tasbeeh.floatingSide';
  static const _overlayModeKey = 'tasbeeh.overlayMode';

  Future<TasbeehState> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final encodedState = prefs.getString(_stateV2Key);
    if (encodedState != null) {
      return TasbeehState.fromJson(
        jsonDecode(encodedState) as Map<String, dynamic>,
      );
    }

    // Legacy anonymous counters are retained in their old keys, but are not
    // assigned to a dhikr or fabricated into phrase statistics.
    return TasbeehState.fromJson({
      'currentCount': prefs.getInt(_currentCountKey),
      'totalCount': prefs.getInt(_totalCountKey),
      'dailyTotal': prefs.getInt(_dailyTotalKey),
      'dailyDateKey': prefs.getString(_dailyDateKey),
      'targetMode': prefs.getString(_targetModeKey),
    });
  }

  Future<int> loadRevision() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getInt(_stateRevisionKey) ?? 0;
  }

  Future<void> save(TasbeehState state, {int? revision}) async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.setString(_stateV2Key, jsonEncode(state.toJson())),
      prefs.setInt(_currentCountKey, state.currentCount),
      prefs.setInt(_totalCountKey, state.totalCount),
      prefs.setInt(_dailyTotalKey, state.dailyTotal),
      prefs.setString(_dailyDateKey, state.dailyDateKey),
      prefs.setString(_targetModeKey, state.targetMode),
      if (revision != null) prefs.setInt(_stateRevisionKey, revision),
    ]);
  }

  Future<bool> hasProcessedOperation(String operationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return (prefs.getStringList(_processedOperationIdsKey) ?? const <String>[])
        .contains(operationId);
  }

  Future<void> markOperationProcessed(String operationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final ids = prefs.getStringList(_processedOperationIdsKey) ?? <String>[];
    if (ids.contains(operationId)) return;
    const retainedOperationCount = 256;
    final next = [...ids, operationId];
    final trimmed = next.length <= retainedOperationCount
        ? next
        : next.sublist(next.length - retainedOperationCount);
    await prefs.setStringList(_processedOperationIdsKey, trimmed);
  }

  Future<List<TasbeehPhrase>> loadPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = (prefs.getStringList(_customPhrasesKey) ?? const [])
        .map(
          (value) =>
              TasbeehPhrase.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
    return [...TasbeehPhrase.defaultPhrases, ...custom];
  }

  Future<TasbeehPhrase> addCustomPhrase(String text) async {
    final phrase = TasbeehPhrase(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      text: text.trim(),
      isBuiltIn: false,
    );
    await ensureCustomPhrase(phrase);
    return phrase;
  }

  Future<void> ensureCustomPhrase(TasbeehPhrase phrase) async {
    if (phrase.isBuiltIn) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final current = prefs.getStringList(_customPhrasesKey) ?? <String>[];
    final exists = current.any((value) {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return json['id'] == phrase.id;
    });
    if (exists) return;
    await prefs.setStringList(_customPhrasesKey, [
      ...current,
      jsonEncode(phrase.toJson()),
    ]);
  }

  Future<List<TasbeehDailyRecord>> loadDailyRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final keys = await _ensureDailyRecordIndex(prefs);
    return keys
        .map((key) => prefs.getString('$_dailyRecordPrefix$key'))
        .whereType<String>()
        .map(
          (value) => TasbeehDailyRecord.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<TasbeehDailyRecord> recordIncrement({
    required String dhikrId,
    required String dhikrText,
    required TasbeehActivitySource source,
    DateTime? at,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final dayKey = LocalDay.key(at ?? DateTime.now());
    final recordKey = _dailyRecordKey(dayKey, dhikrId);
    final keys = await _ensureDailyRecordIndex(prefs);
    final encoded = prefs.getString('$_dailyRecordPrefix$recordKey');
    final current = encoded == null
        ? null
        : TasbeehDailyRecord.fromJson(
            jsonDecode(encoded) as Map<String, dynamic>,
          );
    final updated = current == null
        ? TasbeehDailyRecord(
            dayKey: dayKey,
            dhikrId: dhikrId,
            dhikrTextSnapshot: dhikrText,
            appCount: source == TasbeehActivitySource.app ? 1 : 0,
            overlayCount: source == TasbeehActivitySource.overlay ? 1 : 0,
          )
        : current.copyWith(
            appCount:
                current.appCount +
                (source == TasbeehActivitySource.app ? 1 : 0),
            overlayCount:
                current.overlayCount +
                (source == TasbeehActivitySource.overlay ? 1 : 0),
          );
    await Future.wait([
      prefs.setString(
        '$_dailyRecordPrefix$recordKey',
        jsonEncode(updated.toJson()),
      ),
      if (!keys.contains(recordKey))
        prefs.setStringList(_dailyRecordIndexKey, [...keys, recordKey]),
    ]);
    return updated;
  }

  Future<TasbeehDailyRecord?> removeRecordedIncrement({
    required String dhikrId,
    required TasbeehActivitySource source,
    DateTime? at,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final dayKey = LocalDay.key(at ?? DateTime.now());
    final recordKey = _dailyRecordKey(dayKey, dhikrId);
    await _ensureDailyRecordIndex(prefs);
    final encoded = prefs.getString('$_dailyRecordPrefix$recordKey');
    if (encoded == null) return null;
    final current = TasbeehDailyRecord.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    final canReverse = switch (source) {
      TasbeehActivitySource.app => current.appCount > 0,
      TasbeehActivitySource.overlay => current.overlayCount > 0,
      _ => false,
    };
    if (!canReverse) return null;

    final updated = current.copyWith(
      appCount: source == TasbeehActivitySource.app
          ? current.appCount - 1
          : current.appCount,
      overlayCount: source == TasbeehActivitySource.overlay
          ? current.overlayCount - 1
          : current.overlayCount,
    );
    await prefs.setString(
      '$_dailyRecordPrefix$recordKey',
      jsonEncode(updated.toJson()),
    );
    return updated;
  }

  Future<List<String>> _ensureDailyRecordIndex(SharedPreferences prefs) async {
    final existing = prefs.getStringList(_dailyRecordIndexKey);
    if (existing != null) return existing;
    final legacy = (prefs.getStringList(_dailyRecordsKey) ?? const <String>[])
        .map(
          (value) => TasbeehDailyRecord.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
    final keys = legacy
        .map((record) => _dailyRecordKey(record.dayKey, record.dhikrId))
        .toList();
    await Future.wait([
      for (var index = 0; index < legacy.length; index++)
        prefs.setString(
          '$_dailyRecordPrefix${keys[index]}',
          jsonEncode(legacy[index].toJson()),
        ),
      prefs.setStringList(_dailyRecordIndexKey, keys),
    ]);
    return keys;
  }

  String _dailyRecordKey(String dayKey, String dhikrId) =>
      '$dayKey.${Uri.encodeComponent(dhikrId)}';

  Future<int> inAppCountForDay(String dayKey, String dhikrId) async {
    final records = await loadDailyRecords();
    return records
            .where(
              (record) => record.dayKey == dayKey && record.dhikrId == dhikrId,
            )
            .firstOrNull
            ?.inAppCount ??
        0;
  }

  Future<List<ManualTasbeehEntry>> loadManualEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return (prefs.getStringList(_manualEntriesKey) ?? const [])
        .map(
          (value) => ManualTasbeehEntry.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<ManualTasbeehEntry> addManualEntry({
    required String dhikrId,
    required String dhikrText,
    required int count,
    DateTime? timestamp,
  }) async {
    final at = timestamp ?? DateTime.now();
    final entry = ManualTasbeehEntry(
      id: 'physical_${at.microsecondsSinceEpoch}',
      dayKey: LocalDay.key(at),
      timestamp: at,
      dhikrId: dhikrId,
      dhikrTextSnapshot: dhikrText,
      count: count,
    );
    final entries = await loadManualEntries();
    entries.add(entry);
    await _saveManualEntries(entries);
    await _writeManualAggregate(entries, entry.dayKey, entry.dhikrId);
    return entry;
  }

  Future<void> updateManualEntry(ManualTasbeehEntry updated) async {
    final entries = await loadManualEntries();
    final index = entries.indexWhere((entry) => entry.id == updated.id);
    if (index < 0) return;
    final previous = entries[index];
    entries[index] = updated;
    await _saveManualEntries(entries);
    await _writeManualAggregate(entries, previous.dayKey, previous.dhikrId);
    if (previous.dayKey != updated.dayKey ||
        previous.dhikrId != updated.dhikrId) {
      await _writeManualAggregate(entries, updated.dayKey, updated.dhikrId);
    }
  }

  Future<void> deleteManualEntry(String id) async {
    final entries = await loadManualEntries();
    final removed = entries.where((entry) => entry.id == id).firstOrNull;
    entries.removeWhere((entry) => entry.id == id);
    await _saveManualEntries(entries);
    if (removed != null) {
      await _writeManualAggregate(entries, removed.dayKey, removed.dhikrId);
    }
  }

  Future<int> manualCountForDay(String dayKey, String dhikrId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final aggregateKey = _manualAggregateKey(dayKey, dhikrId);
    final cached = prefs.getInt(aggregateKey);
    if (cached != null) return cached;
    final entries = await loadManualEntries();
    final total = entries
        .where((entry) => entry.dayKey == dayKey && entry.dhikrId == dhikrId)
        .fold<int>(0, (total, entry) => total + entry.count);
    await prefs.setInt(aggregateKey, total);
    return total;
  }

  Future<int> eligibleCountForDay(String dayKey, String dhikrId) async {
    final counts = await Future.wait<int>([
      inAppCountForDay(dayKey, dhikrId),
      manualCountForDay(dayKey, dhikrId),
    ]);
    return counts[0] + counts[1];
  }

  Future<void> _saveManualEntries(List<ManualTasbeehEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _manualEntriesKey,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> _writeManualAggregate(
    List<ManualTasbeehEntry> entries,
    String dayKey,
    String dhikrId,
  ) async {
    final total = entries
        .where((entry) => entry.dayKey == dayKey && entry.dhikrId == dhikrId)
        .fold<int>(0, (sum, entry) => sum + entry.count);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_manualAggregateKey(dayKey, dhikrId), total);
  }

  String _manualAggregateKey(String dayKey, String dhikrId) =>
      '$_manualCountPrefix$dayKey.${Uri.encodeComponent(dhikrId)}';

  Future<TasbeehSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    if (!prefs.containsKey(_autoCollapseSecondsKey) &&
        !prefs.containsKey(_sizeScaleKey) &&
        !prefs.containsKey(_sizePresetKey)) {
      return TasbeehSettings.initial();
    }

    return TasbeehSettings.fromJson({
      'opacity': prefs.getDouble(_opacityKey),
      'sizeScale': prefs.getDouble(_sizeScaleKey),
      'counterScale': prefs.getDouble(_counterScaleKey),
      'collapsedHandleScale': prefs.getDouble(_collapsedHandleScaleKey),
      'collapsedHandleOpacity': prefs.getDouble(_collapsedHandleOpacityKey),
      'sizePreset': prefs.getString(_sizePresetKey),
      'accentColor': prefs.getString(_accentColorKey),
      'backgroundIntensity': prefs.getString(_backgroundIntensityKey),
      'borderStyle': prefs.getString(_borderStyleKey),
      'showBeads': prefs.getBool(_showBeadsKey),
      'beadSize': prefs.getString(_beadSizeKey),
      'showTotal': prefs.getBool(_showTotalKey),
      'showDivider': prefs.getBool(_showDividerKey),
      'autoCollapseSeconds': prefs.getInt(_autoCollapseSecondsKey),
      'handleColorMode': prefs.getString(_handleColorModeKey),
      'handleThickness': prefs.getString(_handleThicknessKey),
      'handleHeight': prefs.getString(_handleHeightKey),
      'hapticFeedbackEnabled': prefs.getBool(_hapticFeedbackEnabledKey),
      'tapAnimationEnabled': prefs.getBool(_tapAnimationEnabledKey),
      'floatingSide': prefs.getString(_floatingSideKey),
      'overlayMode': prefs.getString(_overlayModeKey),
    });
  }

  Future<void> saveSettings(TasbeehSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble(_opacityKey, settings.opacity),
      prefs.setDouble(_sizeScaleKey, settings.sizeScale),
      prefs.setDouble(_counterScaleKey, settings.counterScale),
      prefs.setDouble(_collapsedHandleScaleKey, settings.collapsedHandleScale),
      prefs.setDouble(
        _collapsedHandleOpacityKey,
        settings.collapsedHandleOpacity,
      ),
      prefs.setString(_accentColorKey, settings.accentColor),
      prefs.setString(_backgroundIntensityKey, settings.backgroundIntensity),
      prefs.setString(_borderStyleKey, settings.borderStyle),
      prefs.setBool(_showBeadsKey, settings.showBeads),
      prefs.setString(_beadSizeKey, settings.beadSize),
      prefs.setBool(_showTotalKey, settings.showTotal),
      prefs.setBool(_showDividerKey, settings.showDivider),
      prefs.setInt(_autoCollapseSecondsKey, settings.autoCollapseSeconds),
      prefs.setString(_handleColorModeKey, settings.handleColorMode),
      prefs.setString(_handleThicknessKey, settings.handleThickness),
      prefs.setString(_handleHeightKey, settings.handleHeight),
      prefs.setBool(_hapticFeedbackEnabledKey, settings.hapticFeedbackEnabled),
      prefs.setBool(_tapAnimationEnabledKey, settings.tapAnimationEnabled),
      prefs.setString(_floatingSideKey, settings.floatingSide),
      prefs.setString(_overlayModeKey, settings.overlayMode),
    ]);
  }
}
