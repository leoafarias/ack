# Documentation deployment

The app exports static files to `docs-site/out`. It has one route contract:
application-relative `/core-concepts/schemas` is published at
`https://concepta.dev/ack/core-concepts/schemas`.

## Build

```bash
cd docs-site
npm install --global pnpm@11.5.3
pnpm install --frozen-lockfile
DOCS_BASE_PATH=/ack NEXT_PUBLIC_SITE_URL=https://concepta.dev/ack pnpm build
DOCS_BASE_PATH=/ack NEXT_PUBLIC_SITE_URL=https://concepta.dev/ack python3 scripts/verify-export.py
DOCS_BASE_PATH=/ack pnpm test:browser
```

Install the Playwright Chromium runtime before running browser tests. Publish
`out` at the `/ack` mount, not at `/ack/docs`. The host must serve directory
indexes and raw files, including `/ack/api/search`, `/ack/llms.txt`, Markdown
files, and PNG images. Do not use a homepage fallback for missing files.

Next.js adds basePath to its links. Raw fetches use `addBasePath`; canonical,
sitemap, image metadata, and LLM URLs use `createSiteUrl`. Do not prefix a URL
twice. `site.url` includes the deployment path, while `site.docsPath` is `/`.

## Crawler ownership

The exported `/ack/robots.txt` is not a domain-wide crawler policy. Crawlers
read the origin's `/robots.txt`. Coordinate the Concepta root site's robots
configuration and add the sitemap `https://concepta.dev/ack/sitemap.xml` there.
Do not overwrite the root site's existing crawler rules. Review dates are not
used as sitemap modification dates.

## Cutover gate

This PR removes docs.page's `docs.json`. Do not merge until the new host can
serve the complete static export and the production route has been reviewed.
No deployment, DNS change, registry publication, or merge is automated here.

Keep the previous deployment available for rollback. Verify existing public
links, search, Markdown copy, source links, images, navigation, and 404s at the
real host before completing cutover. Older `/documentation/ack` URLs require
explicit redirects at that host; this static app does not own that prefix.

## Shared package follow-up

After a reviewed theme release is published, replace the `workspace:*`
dependency, remove `packages/docs-theme`, regenerate the lockfile, and rerun the
same root/subpath checks. Do not retain two packages with the same name.
