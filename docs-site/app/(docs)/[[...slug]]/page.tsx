import { createPageMetadata, createSourceUrl, Status } from '@conceptadev/docs-theme';
import { createRelativeLink } from 'fumadocs-ui/mdx';
import { DocsBody, DocsDescription, DocsPage, DocsTitle, MarkdownCopyButton, ViewOptionsPopover } from 'fumadocs-ui/layouts/docs/page';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getMDXComponents } from '@/components/mdx';
import { docsConfig } from '@/docs.config';
import { getPageImageUrl, getPageMarkdownUrl, source } from '@/lib/source';
import { withBasePath } from '@/lib/routes';

interface PageProps { params: Promise<{ slug?: string[] }> }
export const dynamicParams = false;

export default async function Page({ params }: PageProps) {
  const { slug } = await params;
  const page = source.getPage(slug);
  if (!page) notFound();
  const MDX = page.data.body;
  const markdownUrl = withBasePath(getPageMarkdownUrl(page).url);
  return (
    <DocsPage toc={page.data.toc} full={page.data.full}>
      <DocsTitle>{page.data.title}</DocsTitle>
      {page.data.status ? <Status status={page.data.status} /> : null}
      <DocsDescription className="mb-0">{page.data.description}</DocsDescription>
      <div className="flex flex-wrap items-center gap-2 border-b pb-6">
        <MarkdownCopyButton markdownUrl={markdownUrl} />
        <ViewOptionsPopover markdownUrl={markdownUrl} githubUrl={createSourceUrl(docsConfig, page.path)} />
      </div>
      <DocsBody><MDX components={getMDXComponents({ a: createRelativeLink(source, page) })} /></DocsBody>
      {page.data.lastReviewed ? <p className="mt-6 text-sm text-fd-muted-foreground">Last reviewed: <time dateTime={page.data.lastReviewed.toISOString().slice(0, 10)}>{page.data.lastReviewed.toISOString().slice(0, 10)}</time></p> : null}
    </DocsPage>
  );
}
export function generateStaticParams() { return source.generateParams(); }
export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const page = source.getPage(slug);
  if (!page) notFound();
  return createPageMetadata(docsConfig, { title: page.data.title, description: page.data.description, path: page.url, imageUrl: getPageImageUrl(page).url });
}
