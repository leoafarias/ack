# Ack documentation site

This is the Fumadocs application for Ack. The canonical content is `../docs`.
Builds copy that directory byte-for-byte into ignored `content/docs`; edit only
`../docs`. This PR migrates the existing published documentation. It does not
automatically import package READMEs, the root README, or unrelated folders.

## Development

Use Node.js 24.14 or newer, pnpm 11.5.3, and Python 3 for static preview/checks.

```bash
cd docs-site
npm install --global pnpm@11.5.3
pnpm install --frozen-lockfile
pnpm dev
```

Open `http://localhost:3000`. The development process watches `../docs`.
The source loader, navigation, and pages all use application-root routes, not
an additional `/docs` prefix. Existing page paths remain unchanged.

## Validate and preview

```bash
pnpm test
pnpm typecheck
DOCS_BASE_PATH=/ack NEXT_PUBLIC_SITE_URL=https://concepta.dev/ack pnpm build
DOCS_BASE_PATH=/ack NEXT_PUBLIC_SITE_URL=https://concepta.dev/ack python3 scripts/verify-export.py
DOCS_BASE_PATH=/ack pnpm preview
```

Open `http://127.0.0.1:4173/ack/` for the exported preview. This is a static site;
`next start` is not its serving command. Production builds require a public
`NEXT_PUBLIC_SITE_URL` whose pathname matches `DOCS_BASE_PATH`.

Browser checks:

```bash
pnpm exec playwright install chromium
DOCS_BASE_PATH=/ack pnpm test:browser
```

CI tests both root and `/ack` deployments, desktop and mobile rendering,
keyboard search, Markdown and image endpoints, theme switching, missing pages,
internal links/fragments, sitemap URLs, and the Base UI dependency identity.

## Theme ownership

`packages/docs-theme` is the only local snapshot of `@conceptadev/docs-theme`.
See its `SOURCE.md`. It shares the reviewed public API with the theme repository:
`Status` takes `status`; page metadata takes `imageUrl`; source links use
`createSourceUrl`. The explicit Base UI alias and workspace peer policy prevent
a second Radix implementation. A published package can replace the snapshot
after the same validation passes; registry publishing is a separate decision.

Optional front matter uses one shared `PAGE_STATUSES` enum. `lastReviewed` is
an editorial review date, not a content modification time. `draft` is only a
label; it does not hide pages from search or Markdown exports.

See `DEPLOYMENT.md` for the hosting cutover requirement. This PR does not deploy
or change DNS, but deleting `docs.json` requires a coordinated migration.
