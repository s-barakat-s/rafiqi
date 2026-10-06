import 'dart:convert';
import 'dart:io';

final class CorpusMeasurement {
  const CorpusMeasurement({
    required this.fileCount,
    required this.rawBytes,
    required this.minBytes,
    required this.medianBytes,
    required this.p95Bytes,
    required this.maxBytes,
  });

  final int fileCount;
  final int rawBytes;
  final int minBytes;
  final double medianBytes;
  final int p95Bytes;
  final int maxBytes;

  Map<String, Object> toJson() => {
    'file_count': fileCount,
    'raw_bytes': rawBytes,
    'min_bytes': minBytes,
    'median_bytes': medianBytes,
    'p95_bytes': p95Bytes,
    'max_bytes': maxBytes,
  };
}

CorpusMeasurement measureSizes(Iterable<int> input) {
  final sizes = input.toList()..sort();
  if (sizes.isEmpty || sizes.any((size) => size < 0)) {
    throw ArgumentError('At least one non-negative file size is required');
  }
  final middle = sizes.length ~/ 2;
  final median = sizes.length.isOdd
      ? sizes[middle].toDouble()
      : (sizes[middle - 1] + sizes[middle]) / 2;
  final p95Index = ((sizes.length * 0.95).ceil() - 1).clamp(
    0,
    sizes.length - 1,
  );
  return CorpusMeasurement(
    fileCount: sizes.length,
    rawBytes: sizes.fold(0, (sum, size) => sum + size),
    minBytes: sizes.first,
    medianBytes: median,
    p95Bytes: sizes[p95Index],
    maxBytes: sizes.last,
  );
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/quran/benchmark/resource_measurement.dart '
      '<directory> <extension>',
    );
    exitCode = 64;
    return;
  }
  final directory = Directory(arguments[0]);
  final extension = arguments[1].toLowerCase();
  final files = await directory
      .list()
      .where(
        (entity) =>
            entity is File && entity.path.toLowerCase().endsWith(extension),
      )
      .cast<File>()
      .toList();
  final measurement = measureSizes(
    await Future.wait(files.map((file) => file.length())),
  );
  stdout.writeln(jsonEncode(measurement.toJson()));
}
