/// Checks simple install commands in reviewed workflow run statements.
/// This is a policy check, not a general-purpose shell parser.
bool isPinnedNodeInstall(String statement) {
  if (statement.trimLeft().startsWith('#')) return true;
  final command = RegExp(r'^(?:-?\s*run:\s*)?(npm|pnpm|npx)\s+(.+)$');
  final pinned = RegExp(
    r'^(@[^/\s]+/)?[^@\s]+@(\d+\.\d+\.\d+(-[\w.-]+)?|\$[A-Z_][A-Z_0-9]*)$',
  );
  for (final part in statement.split(RegExp(r'&&|\|\||;|\|'))) {
    final match = command.firstMatch(part.trim());
    if (match == null) continue;
    final manager = match.group(1)!;
    final tokens = <String>[
      for (final token in match.group(2)!.split(RegExp(r'\s+')))
        token.replaceAll(RegExp(r'''^["']|["']$'''), ''),
    ];
    final verb = tokens.first;
    final arguments = tokens.skip(1).toList();
    if (manager == 'npm' && verb == 'ci') continue;
    if (manager == 'npx') {
      final packages = tokens.where((token) => !token.startsWith('-'));
      if (packages.isEmpty || !pinned.hasMatch(packages.first)) return false;
      continue;
    }
    if (!['install', 'i', 'add', 'dlx'].contains(verb)) continue;
    final packages = arguments.where((token) => !token.startsWith('-'));
    if (manager == 'pnpm' && ['install', 'i'].contains(verb)) {
      if (packages.isNotEmpty ||
          !arguments.contains('--frozen-lockfile') ||
          arguments.contains('--no-frozen-lockfile')) {
        return false;
      }
      continue;
    }
    if (packages.isEmpty || packages.any((token) => !pinned.hasMatch(token))) {
      return false;
    }
  }
  return true;
}
