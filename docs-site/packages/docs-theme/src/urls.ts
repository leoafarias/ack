const BAD_PATH = /[\\\u0000-\u0020]/;

export function assertAppPath(value: string): void {
  if (BAD_PATH.test(value) || value.startsWith('//')) {
    throw new Error('Use an application-relative path, not a protocol-relative URL.');
  }
  const pathname = value.split(/[?#]/, 1)[0];
  for (const part of pathname.split('/')) {
    const decoded = decodeURIComponent(part);
    if (decoded === '.' || decoded === '..' || /[\\/\u0000-\u001f]/.test(decoded)) {
      throw new Error('Path must not contain traversal or encoded separators.');
    }
  }
}

export function normalizeBasePath(value = ''): string {
  if (value === '' || value === '/') return '';
  assertAppPath(value);
  if (!value.startsWith('/') || /[?#]/.test(value)) {
    throw new Error('basePath must start with / and contain no query or fragment.');
  }
  return value.replace(/\/+$/, '');
}

/** Prefix a raw fetch/asset URL. Do not use on Next.js Link hrefs. */
export function addBasePath(basePath: string, path: string): string {
  const base = normalizeBasePath(basePath);
  assertAppPath(path);
  return `${base}${path.startsWith('/') ? path : `/${path}`}`;
}

/** Resolve an application-relative path while retaining the site's deployment path. */
export function createSiteUrl(siteUrl: string, path = '/'): string {
  const base = new URL(siteUrl);
  if (!['http:', 'https:'].includes(base.protocol) || base.username || base.password || base.search || base.hash) {
    throw new Error('site.url must be an HTTP(S) URL without credentials, query, or fragment.');
  }
  if (/^https?:\/\//i.test(path)) {
    const absolute = new URL(path);
    if (absolute.username || absolute.password) throw new Error('URL must not contain credentials.');
    return absolute.toString();
  }
  assertAppPath(path);
  base.pathname = `${base.pathname.replace(/\/+$/, '')}/`;
  return new URL(path.replace(/^\/+/, ''), base).toString();
}
