import Link from 'fumadocs-core/link';
import type { ComponentProps, ReactNode } from 'react';
import type { DocsProject } from '../types';

export interface ProjectLinksProps extends Omit<ComponentProps<'section'>, 'title'> {
  projects: DocsProject[];
  title?: ReactNode;
}
export function ProjectLinks({ projects, title = 'Related projects', className, ...props }: ProjectLinksProps) {
  if (projects.length === 0) return null;
  return (
    <section {...props} className={['not-prose my-6', className].filter(Boolean).join(' ')}>
      <h2 className="mb-3 text-lg font-semibold">{title}</h2>
      <ul className="grid gap-3 sm:grid-cols-2">
        {projects.map((project) => (
          <li key={project.id}>
            <Link className="block h-full rounded-xl border border-fd-border bg-fd-card p-4 transition-colors hover:bg-fd-accent focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-fd-primary" href={project.docsUrl}>
              <span className="font-medium text-fd-foreground">{project.name}</span>
              {project.description ? <span className="mt-1 block text-sm text-fd-muted-foreground">{project.description}</span> : null}
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}
