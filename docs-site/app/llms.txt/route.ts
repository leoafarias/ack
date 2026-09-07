import { llms } from 'fumadocs-core/source';
import { absoluteSiteUrl } from '@/lib/routes';
import { source } from '@/lib/source';

export const dynamic = 'force-static';
export const revalidate = false;
export function GET() {
  // This rewrites generated URLs only; authored MDX is never rewritten by regex.
  const index = llms(source).index().replace(/\]\((\/[^)]*)\)/g, (_match: string, path: string) => `](${absoluteSiteUrl(path)})`);
  return new Response(index, { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
}
