import type { Metadata } from 'next';
import type { DocsConfig } from './types';
import { createSiteUrl } from './urls';

export interface PageMetadataInput {
  title: string;
  description?: string;
  /** Application-relative page URL, including docsPath once. */
  path: string;
  imageUrl?: string;
}
export function createSiteMetadata(config: DocsConfig): Metadata {
  const siteUrl = new URL(createSiteUrl(config.site.url));
  return {
    metadataBase: siteUrl,
    title: { default: config.site.title, template: `%s | ${config.site.title}` },
    description: config.site.description,
    applicationName: config.site.title,
    alternates: { canonical: siteUrl },
    openGraph: { type: 'website', siteName: config.site.title, title: config.site.title, description: config.site.description, url: siteUrl },
    twitter: { card: 'summary_large_image', title: config.site.title, description: config.site.description },
  };
}
export function createPageMetadata(config: DocsConfig, input: PageMetadataInput): Metadata {
  const pageUrl = createSiteUrl(config.site.url, input.path);
  const images = input.imageUrl ? [createSiteUrl(config.site.url, input.imageUrl)] : undefined;
  const description = input.description ?? config.site.description;
  return {
    title: input.title,
    description,
    alternates: { canonical: pageUrl },
    openGraph: { type: 'article', siteName: config.site.title, title: input.title, description, url: pageUrl, images },
    twitter: { card: 'summary_large_image', title: input.title, description, images },
  };
}
