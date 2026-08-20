import 'dart:io';

import 'package:ag_flow_cli/src/analyze/analyze_issue.dart';
import 'package:ag_flow_cli/src/io/project.dart';
import 'package:path/path.dart' as p;

const _architecturalLayers = {
  'bindings',
  'controllers',
  'pages',
  'repos',
  'services',
};

/// Every root-level module folder under `lib/` (excluding `core/`) must be
/// flat by architectural layer: `<layer>/<file>.dart` for the five layers
/// (no subfolders), and `components/<namespace>/<file>.dart` for
/// components (exactly one namespace level, no further nesting) —
/// requirments/ag_framework.md §6/§7/§37.
List<AnalyzeIssue> checkStructure(Project project) {
  final issues = <AnalyzeIssue>[];
  if (!project.libDir.existsSync()) return issues;

  for (final entity in project.libDir.listSync()) {
    if (entity is! Directory) continue;
    final rootSegment = p.basename(entity.path);
    if (rootSegment == 'core') continue;

    for (final child in entity.listSync(recursive: true)) {
      if (child is Directory) continue;
      final relativeToModule = p
          .relative(child.path, from: entity.path)
          .split(p.separator);

      if (_architecturalLayers.contains(relativeToModule.first)) {
        if (relativeToModule.length > 2) {
          issues.add(
            AnalyzeIssue(
              category: AnalyzeCategory.nestedFolder,
              message:
                  'Architectural layer folders must be flat — found a '
                  'nested subfolder under "${relativeToModule.first}/".',
              file: p.relative(child.path, from: project.root.path),
            ),
          );
        }
        continue;
      }

      if (relativeToModule.first == 'components' &&
          relativeToModule.length > 3) {
        issues.add(
          AnalyzeIssue(
            category: AnalyzeCategory.nestedFolder,
            message:
                'A component namespace must be flat — found a nested '
                'subfolder under "components/${relativeToModule[1]}/".',
            file: p.relative(child.path, from: project.root.path),
          ),
        );
      }
    }
  }

  return issues;
}
