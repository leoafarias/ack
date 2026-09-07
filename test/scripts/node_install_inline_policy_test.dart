import 'package:test/test.dart';

import 'support/node_install_policy.dart';

void main() {
  test('checks inline YAML steps as well as named run statements', () {
    expect(isPinnedNodeInstall('- run: npm install unpinned'), isFalse);
    expect(isPinnedNodeInstall('- run: pnpm install'), isFalse);
    expect(isPinnedNodeInstall('- run: pnpm i --frozen-lockfile'), isTrue);
    expect(isPinnedNodeInstall('- run: npm install tool@1.2.3'), isTrue);
  });
}
