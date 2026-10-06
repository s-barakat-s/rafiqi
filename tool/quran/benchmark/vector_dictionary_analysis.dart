import 'dart:convert';
import 'dart:io';

final _initialMove = RegExp(
  r'^M\s*(-?(?:\d+(?:\.\d*)?|\.\d+))\s*,\s*'
  r'(-?(?:\d+(?:\.\d*)?|\.\d+))(.*)$',
  dotAll: true,
);
final _absoluteCommand = RegExp(r'[MLHVCSQTA]');

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/quran/benchmark/vector_dictionary_analysis.dart '
      '<compiled-directory>',
    );
    exitCode = 64;
    return;
  }
  final directory = Directory(arguments.single);
  final exact = <String, int>{};
  final translated = <String, int>{};
  var pathCount = 0;
  var pathUtf8Bytes = 0;
  var safeTranslationCount = 0;
  var safeTranslationUtf8Bytes = 0;
  var unsafeUtf8Bytes = 0;
  for (var page = 1; page <= 604; page++) {
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      '${page.toString().padLeft(3, '0')}.mvec.gz',
    );
    final root =
        jsonDecode(utf8.decode(gzip.decode(await file.readAsBytes())))
            as Map<String, dynamic>;
    for (final value in root['paths'] as List<dynamic>) {
      final path = (value as Map<String, dynamic>)['d'] as String;
      final bytes = utf8.encode(path).length;
      pathCount++;
      pathUtf8Bytes += bytes;
      exact.update(path, (count) => count + 1, ifAbsent: () => 1);
      final match = _initialMove.firstMatch(path);
      final suffix = match?.group(3);
      if (suffix != null && !_absoluteCommand.hasMatch(suffix)) {
        safeTranslationCount++;
        safeTranslationUtf8Bytes += bytes;
        translated.update(suffix, (count) => count + 1, ifAbsent: () => 1);
      } else {
        unsafeUtf8Bytes += bytes;
      }
    }
  }
  int uniqueBytes(Map<String, int> values) =>
      values.keys.fold(0, (sum, value) => sum + utf8.encode(value).length);
  final exactUniqueBytes = uniqueBytes(exact);
  final translatedUniqueBytes = uniqueBytes(translated);
  final report = {
    'path_count': pathCount,
    'path_utf8_bytes': pathUtf8Bytes,
    'exact_unique_count': exact.length,
    'exact_reused_path_count': pathCount - exact.length,
    'exact_unique_utf8_bytes': exactUniqueBytes,
    'translation_safe_path_count': safeTranslationCount,
    'translation_safe_utf8_bytes': safeTranslationUtf8Bytes,
    'translation_normalized_unique_count': translated.length,
    'translation_normalized_reused_path_count':
        safeTranslationCount - translated.length,
    'translation_normalized_unique_suffix_utf8_bytes': translatedUniqueBytes,
    'unsafe_path_utf8_bytes': unsafeUtf8Bytes,
    'theoretical_dictionary_geometry_bytes_before_container_compression':
        translatedUniqueBytes + unsafeUtf8Bytes + (safeTranslationCount * 12),
  };
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}
