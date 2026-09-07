import { createMDX } from 'fumadocs-mdx/next';

const configured = process.env.DOCS_BASE_PATH ?? '';
const basePath = configured === '/' ? '' : configured.replace(/\/+$/, '');
if (basePath && (!/^\/(?!\/)[a-zA-Z0-9/_-]+$/.test(basePath) || basePath.includes('//'))) {
  throw new Error('DOCS_BASE_PATH must be a path such as /ack.');
}
const siteUrl = process.env.NEXT_PUBLIC_SITE_URL;
if (process.env.NODE_ENV === 'production' && !siteUrl) throw new Error('Set NEXT_PUBLIC_SITE_URL for production builds.');
if (siteUrl && new URL(siteUrl).pathname.replace(/\/+$/, '') !== basePath) {
  throw new Error('NEXT_PUBLIC_SITE_URL pathname must match DOCS_BASE_PATH.');
}
/** @type {import('next').NextConfig} */
const config = {
  output: 'export',
  trailingSlash: true,
  reactStrictMode: true,
  basePath: basePath || undefined,
  images: { unoptimized: true },
  transpilePackages: ['@conceptadev/docs-theme'],
  env: { NEXT_PUBLIC_DOCS_BASE_PATH: basePath },
};
export default createMDX()(config);
