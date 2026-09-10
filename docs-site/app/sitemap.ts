import type { MetadataRoute } from 'next';
import { absoluteSiteUrl } from '@/lib/routes';
import { source } from '@/lib/source';

export const dynamic = 'force-static';
export default function sitemap(): MetadataRoute.Sitemap {
  // lastReviewed is an editorial date, not a content modification timestamp.
  return source.getPages().map((page) => ({ url: absoluteSiteUrl(page.url) }));
}
