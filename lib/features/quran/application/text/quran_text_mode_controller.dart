import 'package:flutter/foundation.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';
import 'package:tasbeh/features/quran/domain/repositories/quran_repository.dart';

final class QuranTextModeController extends ChangeNotifier {
  QuranTextModeController(this._repository);

  final QuranRepository _repository;
  QuranSurah? _surah;
  List<QuranAyah> _ayahs = const [];
  AyahKey? _selectedAyah;
  AyahKey? _scrollTarget;
  bool _isLoading = false;
  bool _disposed = false;
  Object? _error;

  QuranSurah? get surah => _surah;
  List<QuranAyah> get ayahs => _ayahs;
  AyahKey? get selectedAyah => _selectedAyah;
  AyahKey? get scrollTarget => _scrollTarget;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  int? get scrollTargetIndex {
    final target = _scrollTarget;
    if (target == null) return null;
    final index = _ayahs.indexWhere((ayah) => ayah.key == target);
    return index < 0 ? null : index;
  }

  Future<void> loadSurah(int surahNumber, {AyahKey? target}) async {
    if (surahNumber < 1 || surahNumber > 114) {
      throw ArgumentError.value(surahNumber, 'surahNumber');
    }
    if (target != null && target.surahNumber != surahNumber) {
      throw ArgumentError.value(target, 'target', 'belongs to another Surah');
    }
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final results = await Future.wait<Object?>([
        _repository.getSurah(surahNumber),
        _repository.getSurahAyahs(surahNumber),
      ]);
      final surah = results[0] as QuranSurah?;
      final ayahs = results[1]! as List<QuranAyah>;
      if (surah == null || ayahs.isEmpty) {
        throw StateError('Surah data is unavailable');
      }
      if (target != null && !ayahs.any((ayah) => ayah.key == target)) {
        throw StateError('Target Ayah is unavailable in this Surah');
      }
      _surah = surah;
      _ayahs = List.unmodifiable(ayahs);
      _scrollTarget = target ?? ayahs.first.key;
      _selectedAyah = target;
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void selectAyah(AyahKey key) {
    if (!_ayahs.any((ayah) => ayah.key == key)) {
      throw ArgumentError.value(key, 'key', 'is not loaded');
    }
    _selectedAyah = _selectedAyah == key ? null : key;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
