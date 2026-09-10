# Contributing to Ack

Thanks for helping improve Ack. Keep changes focused, tested, and easy to
review. By participating, you agree to follow the
[Code of Conduct](./CODE_OF_CONDUCT.md).

## Development setup

```bash
dart pub get
dart run melos bootstrap
```

Ack uses a Melos workspace. Run commands from the repository root unless a
package README says otherwise.

## Documentation changes

The canonical documentation source is in `docs/`. Do not edit
`docs-site/content`; the Fumadocs application generates that mirror for local
and production builds.

Set up and run the documentation site with:

```bash
cd docs-site
npm install --global pnpm@11.5.3
pnpm install --frozen-lockfile
pnpm dev
```

The development server watches `docs/` and refreshes the content mirror. Open
`http://localhost:3000`.

Before submitting documentation changes, run:

```bash
cd docs-site
pnpm typecheck
DOCS_BASE_PATH=/ack \
NEXT_PUBLIC_SITE_URL=https://concepta.dev/ack \
pnpm build
```

## Before opening a PR

1. Keep the change scoped to one problem.
2. Add or update tests for behavior changes.
3. Update docs or README snippets when public APIs, examples, or setup steps
   change.
4. Run the relevant checks:

```bash
dart run melos run analyze
dart run melos run test
```

For code generation changes, also run:

```bash
dart run melos run test:gen
```

For JSON Schema export changes, also run:

```bash
dart run melos run validate-jsonschema
```

## Commit style

Use Conventional Commits, for example:

```text
feat(ack): add schema helper
fix(generator): preserve nullable list getters
docs: clarify codec examples
```

Use `!` or a `BREAKING CHANGE:` footer for breaking API changes.

## Release notes

User-facing changes should update the relevant package `CHANGELOG.md`. Release
publishing is handled by maintainers through `PUBLISHING.md`.

## Getting help and reporting security issues

Use [SUPPORT.md](./SUPPORT.md) for questions and public bug reports. Follow
[SECURITY.md](./SECURITY.md) for vulnerabilities; do not disclose suspected
security issues in a public issue.
