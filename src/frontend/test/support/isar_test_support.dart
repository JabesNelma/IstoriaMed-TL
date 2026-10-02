import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';

/// Makes the real Isar native core available to `flutter test`.
///
/// The queue tests must run against a real Isar instance on disk (restart
/// persistence is a hard requirement), so the core library is loaded from the
/// `isar_flutter_libs` artefact when it is already present, and only downloaded
/// as a last resort.
Future<void> initializeIsarForTests() async {
  final cached = _resolveFromPackageConfig();
  if (cached != null) {
    await Isar.initializeIsarCore(libraries: {Abi.current(): cached});
    return;
  }
  await Isar.initializeIsarCore(download: true);
}

String? _resolveFromPackageConfig() {
  final candidates = <String>[
    File('.dart_tool/package_config.json').absolute.path,
    File('../.dart_tool/package_config.json').absolute.path,
  ];
  for (final candidate in candidates) {
    final file = File(candidate);
    if (!file.existsSync()) continue;
    final match = RegExp(
      r'"name"\s*:\s*"isar_flutter_libs"\s*,\s*"rootUri"\s*:\s*"([^"]+)"',
      dotAll: true,
    ).firstMatch(file.readAsStringSync());
    if (match == null) continue;
    final root = Uri.parse(match.group(1)!);
    final base = root.hasScheme ? root : Uri.file('${File(candidate).parent.path}/').resolveUri(root);
    // A directory URI must end with a slash, otherwise resolve() drops its last segment.
    final directory = base.toString().endsWith('/') ? base : Uri.parse('${base.toString()}/');
    final library = File.fromUri(directory.resolve('linux/libisar.so'));
    if (library.existsSync()) return library.path;
  }
  return null;
}
