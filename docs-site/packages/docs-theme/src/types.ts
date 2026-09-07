export type { PageStatus } from './status';
export type LinkPlacement = 'all' | 'menu' | 'nav';

export interface DocsRepository {
  /** Repository root URL, including GitHub Enterprise URLs. */
  url: string;
  branch?: string;
  /** Repository-relative path to the documentation content. */
  contentPath?: string;
}
export interface DocsProject {
  id: string;
  name: string;
  description?: string;
  docsUrl: string;
  repository?: DocsRepository;
}
export interface DocsSocialLink {
  label: string;
  url: string;
  placement?: LinkPlacement;
}
export interface DocsConfig {
  organization: { name: string; homeUrl?: string };
  site: {
    title: string;
    description: string;
    /** Public application URL, including its deployment path, for example /ack. */
    url: string;
    /** Documentation route inside the application, not the deployment path. */
    docsPath?: `/${string}`;
  };
  project: DocsProject;
  projects?: DocsProject[];
  socialLinks?: DocsSocialLink[];
}
