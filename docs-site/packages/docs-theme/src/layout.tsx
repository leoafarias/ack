import type {
  BaseLayoutProps,
  LinkItemType,
  MainItemType,
} from 'fumadocs-ui/layouts/shared';
import { getDocsPath, getProjects } from './config';
import { createRepositoryUrl } from './repository';
import type { DocsConfig } from './types';

function isExternalUrl(url: string, siteUrl: string): boolean {
  if (url.startsWith('/')) return false;

  try {
    return new URL(url).origin !== new URL(siteUrl).origin;
  } catch {
    return true;
  }
}

function createProjectMenu(config: DocsConfig): LinkItemType | undefined {
  const projects = getProjects(config);
  if (projects.length < 2) return undefined;

  const items: MainItemType[] = projects.map((project) => ({
    type: 'main',
    text: project.name,
    description: project.description,
    url: project.docsUrl,
    active: 'nested-url',
    external: isExternalUrl(project.docsUrl, config.site.url),
  }));

  return {
    type: 'menu',
    text: 'Projects',
    items,
  };
}

export function createBaseLayoutOptions(
  config: DocsConfig,
): BaseLayoutProps {
  const links: LinkItemType[] = [];
  const projectMenu = createProjectMenu(config);

  if (projectMenu) links.push(projectMenu);

  for (const link of config.socialLinks ?? []) {
    links.push({
      type: 'main',
      text: link.label,
      url: link.url,
      on: link.placement ?? 'menu',
      external: isExternalUrl(link.url, config.site.url),
    });
  }

  return {
    nav: {
      title: config.project.name,
      url: getDocsPath(config),
    },
    githubUrl: createRepositoryUrl(config),
    links,
  };
}
