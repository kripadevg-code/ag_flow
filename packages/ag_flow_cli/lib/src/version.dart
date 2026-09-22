// Kept in sync with `version:` in pubspec.yaml.
//
// Hard-coded rather than read from the pubspec at runtime: a compiled or
// globally-activated CLI has no reliable path back to its own pubspec,
// and `ag --version` has to work in both.
const agCliVersion = '0.2.0';
