import { defineDocsConfig } from '@conceptadev/docs-theme';

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000';

export const docsConfig = defineDocsConfig({
  organization: {
    name: 'Concepta',
    homeUrl: 'https://concepta.dev',
  },
  site: {
    title: 'Ack Documentation',
    description:
      'Schema validation, codecs, and type-safe model generation for Dart and Flutter.',
    url: siteUrl,
    docsPath: '/',
  },
  project: {
    id: 'ack',
    name: 'Ack',
    description:
      'Schema validation for Dart and Flutter with actionable errors and optional code generation.',
    docsUrl: '/',
    repository: {
      url: 'https://github.com/conceptadev/ack',
      branch: 'main',
      contentPath: 'docs',
    },
  },
  projects: [
    {
      id: 'ack',
      name: 'Ack',
      description: 'Schema validation for Dart and Flutter.',
      docsUrl: '/',
    },
    {
      id: 'mix',
      name: 'Mix',
      description: 'A composable styling system for Flutter.',
      docsUrl: 'https://www.fluttermix.com',
    },
  ],
  socialLinks: [
    {
      label: 'pub.dev',
      url: 'https://pub.dev/packages/ack',
      placement: 'nav',
    },
    {
      label: 'Concepta',
      url: 'https://concepta.dev',
      placement: 'menu',
    },
  ],
});
