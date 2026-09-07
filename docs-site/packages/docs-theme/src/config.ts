import type { DocsConfig, DocsProject } from './types';
import { assertAppPath, createSiteUrl, normalizeBasePath } from './urls';

const PROJECT_ID_PATTERN = /^[a-z0-9][a-z0-9-]*$/;

function assertHttpUrl(value: string, name: string): void {
  const url = new URL(value);
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) {
    throw new Error(`${name} must be an HTTP(S) URL without credentials.`);
  }
}
function assertLink(value: string, name: string): void {
  if (value.startsWith('/')) assertAppPath(value);
  else assertHttpUrl(value, name);
}
function assertProject(project: DocsProject, name: string): void {
  if (!PROJECT_ID_PATTERN.test(project.id)) throw new Error(`${name}.id must contain lowercase letters, numbers, and hyphens.`);
  if (!project.name.trim()) throw new Error(`${name}.name must not be empty.`);
  assertLink(project.docsUrl, `${name}.docsUrl`);
  if (project.repository) {
    createSiteUrl(project.repository.url);
    if (project.repository.branch !== undefined && !project.repository.branch.trim()) throw new Error(`${name}.repository.branch must not be empty.`);
    if (project.repository.contentPath) assertAppPath(project.repository.contentPath);
  }
}

/** Validate the small data-only layer; Fumadocs still owns routing and MDX. */
export function defineDocsConfig<const T extends DocsConfig>(config: T): T {
  if (!config.organization.name.trim()) throw new Error('organization.name must not be empty.');
  if (!config.site.title.trim() || !config.site.description.trim()) throw new Error('site.title and site.description must not be empty.');
  createSiteUrl(config.site.url);
  if (config.organization.homeUrl) assertHttpUrl(config.organization.homeUrl, 'organization.homeUrl');
  if (config.site.docsPath !== undefined) normalizeBasePath(config.site.docsPath);
  assertProject(config.project, 'project');
  const seen = new Set<string>();
  for (const [index, project] of (config.projects ?? []).entries()) {
    assertProject(project, `projects[${index}]`);
    if (seen.has(project.id)) throw new Error(`projects contains the duplicate id "${project.id}".`);
    seen.add(project.id);
  }
  for (const [index, link] of (config.socialLinks ?? []).entries()) {
    if (!link.label.trim()) throw new Error(`socialLinks[${index}].label must not be empty.`);
    assertLink(link.url, `socialLinks[${index}].url`);
  }
  return config;
}
export function getDocsPath(config: DocsConfig): `/${string}` {
  return config.site.docsPath ?? '/docs';
}
export function getProjects(config: DocsConfig): DocsProject[] {
  const projects = config.projects ?? [];
  return projects.some((project) => project.id === config.project.id) ? projects : [config.project, ...projects];
}
