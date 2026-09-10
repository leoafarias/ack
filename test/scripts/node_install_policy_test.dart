import 'package:test/test.dart';

import 'support/node_install_policy.dart';

void main() {
  test('allows frozen installs and exactly pinned package commands', () {
    for (final command in [
      'npm ci',
      'run: pnpm install --frozen-lockfile',
      'pnpm i --frozen-lockfile --ignore-scripts',
      'npm install --global pnpm@11.5.3',
      r'npx --yes "@docs.page/cli@$DOCS_PAGE_CLI_VERSION" check',
      '# npm install unpinned',
      'echo npm install is only an example',
    ]) {
      expect(isPinnedNodeInstall(command), isTrue, reason: command);
    }
  });

  test('rejects unpinned installs without weakening the workflow guard', () {
    for (final command in [
      'npm install',
      'npm install --global pnpm',
      'npm i first@1.2.3 unpinned',
      'pnpm install',
      'pnpm i --no-frozen-lockfile',
      'pnpm install --frozen-lockfile --no-frozen-lockfile',
      'pnpm install package@1.2.3 --frozen-lockfile',
      'npx --yes some-cli',
      'echo ready && npm install unpinned',
    ]) {
      expect(isPinnedNodeInstall(command), isFalse, reason: command);
    }
  });
}
