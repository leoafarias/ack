import { createBaseLayoutOptions } from '@conceptadev/docs-theme';
import { docsConfig } from '@/docs.config';

export function baseOptions() {
  return createBaseLayoutOptions(docsConfig);
}
