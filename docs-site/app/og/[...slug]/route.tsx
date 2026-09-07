import { generate as DefaultImage } from 'fumadocs-ui/og';
import { notFound } from 'next/navigation';
import { ImageResponse } from 'next/og';
import { getPageImageUrl, source } from '@/lib/source';

export const dynamic = 'force-static';
export const dynamicParams = false;
export const revalidate = false;
export async function GET(_request: Request, { params }: { params: Promise<{ slug: string[] }> }) {
  const { slug } = await params;
  if (slug.at(-1) !== 'image.png') notFound();
  const page = source.getPage(slug.slice(0, -1));
  if (!page) notFound();
  return new ImageResponse(<DefaultImage title={page.data.title} description={page.data.description} site="Ack" />, { width: 1200, height: 630 });
}
export function generateStaticParams() {
  return source.getPages().map((page) => ({ slug: getPageImageUrl(page).segments }));
}
