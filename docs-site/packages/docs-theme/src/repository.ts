import type { DocsConfig } from './types';

function encodePath(...parts: Array<string | undefined>): string {
  return parts.filter((part): part is string => Boolean(part))
    .flatMap((part) => part.split('/')).filter(Boolean)
    .map((part) => {
      if (part === '.' || part === '..' || /[\\\u0000-\u001f]/.test(part)) throw new Error('Repository paths must not contain traversal.');
      return encodeURIComponent(part);
    }).join('/');
}
export function createRepositoryUrl(config: DocsConfig): string | undefined {
  return config.project.repository?.url.replace(/\/+$/, '');
}
function fileUrl(config: DocsConfig, pagePath: string, action: 'blob' | 'edit'): string | undefined {
  const repository = config.project.repository;
  if (!repository) return undefined;
  const branch = encodeURIComponent(repository.branch ?? 'main');
  return `${createRepositoryUrl(config)}/${action}/${branch}/${encodePath(repository.contentPath, pagePath)}`;
}
export function createSourceUrl(config: DocsConfig, pagePath: string): string | undefined {
  return fileUrl(config, pagePath, 'blob');
}
export function createEditUrl(config: DocsConfig, pagePath: string): string | undefined {
  return fileUrl(config, pagePath, 'edit');
}
