import { addBasePath, createSiteUrl } from '@conceptadev/docs-theme';
import { docsConfig } from '@/docs.config';

/** Only for raw fetches/assets; Next.js Link adds basePath itself. */
export function withBasePath(path: string): string {
  return addBasePath(process.env.NEXT_PUBLIC_DOCS_BASE_PATH ?? '', path);
}
export function absoluteSiteUrl(path: string): string {
  return createSiteUrl(docsConfig.site.url, path);
}
