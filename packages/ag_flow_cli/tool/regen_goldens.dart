// Regenerates test/goldens/** from real ModuleGenerator output.
//
// Golden fixtures in this repo are always produced by running the tool,
// never hand-transcribed — hand-editing one can encode a formatting or
// naming mistake as the expected answer and hide a real regression.
//
// Usage: dart run tool/regen_goldens.dart
import 'dart:io';

import 'package:ag_flow_cli/src/generators/init_generator.dart';
import 'package:ag_flow_cli/src/generators/module_generator.dart';
import 'package:ag_flow_cli/src/io/executor.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:ag_flow_cli/src/naming/module_path.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final goldensDir = Directory(
    p.join(Directory.current.path, 'test', 'goldens'),
  );
  final logger = Logger(level: Level.quiet);

  await _regen(
    goldensDir: goldensDir,
    goldenName: 'collection_module',
    modules: [ModulePath.parse('product')],
    logger: logger,
  );
  await _regen(
    goldensDir: goldensDir,
    goldenName: 'detail_module',
    modules: [ModulePath.parse('product'), ModulePath.parse('product/details')],
    keepOnly: (path) => path.contains('details'),
    logger: logger,
  );
  stdout.writeln('Goldens regenerated from real generator output.');
}

Future<void> _regen({
  required Directory goldensDir,
  required String goldenName,
  required List<ModulePath> modules,
  required Logger logger,
  bool Function(String relativePath)? keepOnly,
}) async {
  final appDir = Directory.systemTemp.createTempSync('ag_golden_');
  File(p.join(appDir.path, 'pubspec.yaml'))
    ..createSync(recursive: true)
    ..writeAsStringSync('name: sample_app\n');
  Directory(p.join(appDir.path, 'lib')).createSync(recursive: true);

  final project = Project(appDir);
  // Scaffold core/ exactly as `ag init` does, rather than reproducing its
  // skeletons here — a golden must come from the real tool end to end.
  await Executor(
    dryRun: false,
    logger: logger,
  ).execute(InitGenerator(project: project).plan());
  for (final module in modules) {
    final ops = await ModuleGenerator(project: project).plan(module);
    await Executor(dryRun: false, logger: logger).execute(ops);
  }

  final target = Directory(p.join(goldensDir.path, goldenName, 'lib'));
  if (target.existsSync()) target.deleteSync(recursive: true);

  final libDir = Directory(p.join(appDir.path, 'lib'));
  for (final entity in libDir.listSync(recursive: true).whereType<File>()) {
    final relative = p.relative(entity.path, from: libDir.path);
    if (relative.startsWith('core')) continue;
    if (keepOnly != null && !keepOnly(relative)) continue;
    final destination = File(p.join(target.path, relative))
      ..createSync(recursive: true);
    entity.copySync(destination.path);
  }
  appDir.deleteSync(recursive: true);
}
