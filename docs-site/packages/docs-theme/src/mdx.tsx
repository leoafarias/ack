import { Accordion, Accordions } from 'fumadocs-ui/components/accordion';
import { File, Files, Folder } from 'fumadocs-ui/components/files';
import { Step, Steps } from 'fumadocs-ui/components/steps';
import { Tab, Tabs } from 'fumadocs-ui/components/tabs';
import defaultMdxComponents from 'fumadocs-ui/mdx';
import type { MDXComponents } from 'mdx/types';
import { ConceptSummary } from './components/concept-summary';
import { ProjectLinks } from './components/project-links';
import { Status } from './components/status';

export function getConceptaMDXComponents(components?: MDXComponents) {
  return {
    ...defaultMdxComponents,
    Accordion, Accordions, File, Files, Folder, Step, Steps, Tab, Tabs,
    ConceptSummary, ProjectLinks, Status,
    ...components,
  } satisfies MDXComponents;
}
export const useMDXComponents = getConceptaMDXComponents;
