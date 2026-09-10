import { Status, createPageMetadata, type DocsConfig } from '@conceptadev/docs-theme';
import { getConceptaMDXComponents } from '@conceptadev/docs-theme/mdx';
import type { ComponentProps } from 'react';

export function checkThemeContract(config: DocsConfig) {
  const components = getConceptaMDXComponents();
  const props: ComponentProps<typeof components.Status> = { status: 'stable' };
  const valid = <Status {...props} />;
  // @ts-expect-error Status uses status, not the abandoned value prop.
  const invalid = <Status value="stable" />;
  createPageMetadata(config, { title: 'Guide', path: '/guide', imageUrl: '/og/guide/image.png' });
  // @ts-expect-error Metadata uses imageUrl, not image.
  createPageMetadata(config, { title: 'Guide', path: '/guide', image: '/og/image.png' });
  return { valid, invalid };
}
