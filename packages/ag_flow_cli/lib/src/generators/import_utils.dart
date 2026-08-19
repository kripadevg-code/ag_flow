import 'package:ag_flow_cli/src/generators/patch.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Whether [unit] already has an import directive for exactly [uri].
bool hasImport(CompilationUnit unit, String uri) {
  return unit.directives.whereType<ImportDirective>().any(
    (d) => d.uri.stringValue == uri,
  );
}

/// A patch inserting `import '$uri';` if [unit] doesn't already import it,
/// or null if it already does (the idempotency check for imports).
Patch? insertImportPatch(CompilationUnit unit, String uri) {
  if (hasImport(unit, uri)) return null;

  final imports = unit.directives.whereType<ImportDirective>().toList();
  if (imports.isNotEmpty) {
    return Patch.insertion(imports.last.end, "\nimport '$uri';");
  }

  // No existing imports — insert after any leading library/part-of
  // directive, or at the very top of the file otherwise.
  if (unit.directives.isNotEmpty) {
    return Patch.insertion(unit.directives.last.end, "\nimport '$uri';");
  }
  return Patch.insertion(0, "import '$uri';\n\n");
}

/// Sorts a source file's `import '...';` lines into the conventional
/// `dart:` / `package:` / relative groups (each alphabetical within its
/// group, one blank line between non-empty groups).
///
/// Needed after inserting a new import at a fixed position (after the
/// last existing import) — that position isn't necessarily where the new
/// import belongs, and a plain flat alphabetical sort would itself
/// interleave groups incorrectly (a relative import like `app_routes
/// .dart` sorts before any `package:` import purely on the letter `a` vs.
/// `p`). `dart_style`'s formatter never reorders directives (only the
/// separate `directives_ordering` lint's `dart fix` does), so this is
/// done by hand.
String sortImports(String source) {
  final lines = source.split('\n');
  final importLineIndices = [
    for (var i = 0; i < lines.length; i++)
      if (lines[i].startsWith('import ')) i,
  ];
  if (importLineIndices.isEmpty) return source;

  final sortedImportLines = [for (final i in importLineIndices) lines[i]]
    ..sort(_compareImports);

  final rebuiltImportBlock = <String>[];
  String? previousGroup;
  for (final line in sortedImportLines) {
    final group = _importGroup(line);
    if (previousGroup != null && previousGroup != group) {
      rebuiltImportBlock.add('');
    }
    rebuiltImportBlock.add(line);
    previousGroup = group;
  }

  final before = lines.sublist(0, importLineIndices.first);
  final after = lines.sublist(importLineIndices.last + 1);
  return [...before, ...rebuiltImportBlock, ...after].join('\n');
}

int _compareImports(String a, String b) {
  final groupComparison = _importGroup(a).compareTo(_importGroup(b));
  return groupComparison != 0 ? groupComparison : a.compareTo(b);
}

/// `dart:` imports first, then `package:`, then relative — matching the
/// order the `directives_ordering` lint and `dart fix` would produce.
String _importGroup(String importLine) {
  if (importLine.contains("'dart:")) return '0';
  if (importLine.contains("'package:")) return '1';
  return '2';
}
