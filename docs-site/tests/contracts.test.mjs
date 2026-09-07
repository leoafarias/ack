import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFileSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { addBasePath, createSiteUrl, normalizeBasePath } from '../packages/docs-theme/src/urls.ts';

for (const [site, prefix] of [['https://concepta.dev', ''], ['https://concepta.dev/ack', '/ack'], ['https://concepta.dev/ack/', '/ack']]) {
  test(`URL contract for ${site}`, () => {
    for (const path of ['/', '/core-concepts/schemas', '/api/search', '/sitemap.xml', '/llms.txt', '/og/image.png', '/llms.mdx/content.md']) {
      assert.equal(createSiteUrl(site, path), `https://concepta.dev${prefix}${path}`);
      assert.equal(addBasePath(prefix, path), `${prefix}${path}`);
    }
  });
}
test('reject unsafe and ambiguous paths', () => {
  for (const path of ['//evil.example', '/../other', '/%2e%2e/other', '/a%2fb', '/a\\b']) assert.throws(() => createSiteUrl('https://concepta.dev/ack', path));
  for (const path of ['ack', '/ack?x=1', '//ack']) assert.throws(() => normalizeBasePath(path));
});
test('app and local theme resolve the same Base UI and React', () => {
  const app = createRequire(new URL('../package.json', import.meta.url));
  const theme = createRequire(app.resolve('@conceptadev/docs-theme/package.json'));
  for (const req of [app, theme]) {
    const pkg = JSON.parse(readFileSync(req.resolve('fumadocs-ui/package.json'), 'utf8'));
    assert.equal(pkg.name, '@fumadocs/base-ui');
    assert.equal(pkg.version, '16.15.8');
  }
  assert.equal(app.resolve('react'), theme.resolve('react'));
});
test('only one site implementation and one content pipeline exist', () => {
  for (const path of ['app/page.tsx', 'app/docs', 'theme', 'scripts/sync-content.mjs']) assert.equal(existsSync(new URL(`../${path}`, import.meta.url)), false, path);
  const manifest = JSON.parse(readFileSync(new URL('../package.json', import.meta.url), 'utf8'));
  assert.equal(manifest.scripts['docs:sync'], 'node scripts/sync-docs.mjs');
  assert.equal(manifest.scripts.start, undefined, 'next start cannot serve a static export');
});
