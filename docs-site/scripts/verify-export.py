"""Validate emitted routes, metadata, assets, and internal link fragments."""
import json
import os
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit
from xml.etree import ElementTree

root = Path(__file__).resolve().parents[1] / 'out'
site = os.environ['NEXT_PUBLIC_SITE_URL'].rstrip('/')
site_parts = urlsplit(site)
base = site_parts.path.rstrip('/')
errors = []

class Document(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.ids, self.links, self.canonicals, self.images = set(), [], [], []
        self.feed(text)

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if attrs.get('id'):
            self.ids.add(attrs['id'])
        if tag == 'a' and attrs.get('href'):
            self.links.append(attrs['href'])
        if tag in ('img', 'script') and attrs.get('src'):
            self.links.append(attrs['src'])
        if tag == 'link' and attrs.get('rel') == 'stylesheet':
            self.links.append(attrs['href'])
        if tag == 'link' and attrs.get('rel') == 'canonical':
            self.canonicals.append(attrs['href'])
        if tag == 'meta' and attrs.get('property') == 'og:image':
            self.images.append(attrs['content'])

def emitted(pathname):
    path = unquote(pathname)
    if base:
        if path != base and not path.startswith(base + '/'):
            return None
        path = path[len(base):]
    candidate = (root / path.lstrip('/')).resolve()
    if not candidate.is_relative_to(root.resolve()):
        return None
    for file in (candidate, candidate / 'index.html', candidate.with_suffix('.html')):
        if file.is_file():
            return file
    return None

documents = {}
for file in root.rglob('*.html'):
    if file.name == '404.html' or '_not-found' in file.parts or '404' in file.parts:
        continue
    relative = file.relative_to(root).as_posix()
    route = '/' + (relative[:-10] if relative.endswith('index.html') else relative[:-5])
    documents[file.resolve()] = (site + route, Document(file.read_text()))

if not documents:
    errors.append('No exported HTML pages found.')
for file, (url, doc) in documents.items():
    for canonical in doc.canonicals:
        if canonical.rstrip('/') != url.rstrip('/'):
            errors.append(f'{file.relative_to(root)}: wrong canonical {canonical}; expected {url}')
    for target in doc.links + doc.images:
        resolved = urlsplit(urljoin(url, target))
        if resolved.scheme not in ('http', 'https') or resolved.netloc != site_parts.netloc:
            continue
        # Absolute links may intentionally leave this subpath (Concepta home).
        if target.startswith(('http://', 'https://', '//')) and base and not (resolved.path == base or resolved.path.startswith(base + '/')):
            continue
        destination = emitted(resolved.path)
        if destination is None:
            errors.append(f'{file.relative_to(root)}: missing local target {target}')
        elif resolved.fragment and destination in documents:
            fragment = unquote(resolved.fragment)
            if not fragment.startswith(':~:text=') and fragment not in documents[destination][1].ids:
                errors.append(f'{file.relative_to(root)}: missing fragment {target}')

for path in ['index.html', 'core-concepts/schemas/index.html', 'llms.txt', 'llms-full.txt', 'llms.mdx/core-concepts/schemas/content.md', 'og/core-concepts/schemas/image.png', 'sitemap.xml', 'robots.txt', 'api/search']:
    file = root / path
    if not file.is_file() or not file.stat().st_size:
        errors.append(f'Missing export: {path}')

if (root / 'sitemap.xml').is_file():
    tree = ElementTree.parse(root / 'sitemap.xml')
    locations = [node.text for node in tree.findall('.//{*}loc')]
    for location in locations:
        if not location.startswith(site + '/') or emitted(urlsplit(location).path) is None:
            errors.append(f'Invalid sitemap location: {location}')
    if len(locations) != len(documents):
        errors.append(f'Sitemap contains {len(locations)} pages; exported HTML has {len(documents)}.')
if (root / 'robots.txt').is_file() and f'Sitemap: {site}/sitemap.xml' not in (root / 'robots.txt').read_text():
    errors.append('Robots sitemap URL does not retain the deployment path.')
if (root / 'api/search').is_file():
    json.loads((root / 'api/search').read_text())
if (root / 'llms.txt').is_file() and f'{site}/core-concepts/schemas' not in (root / 'llms.txt').read_text():
    errors.append('LLM index does not contain the canonical schema page URL.')
if errors:
    raise SystemExit('\n'.join(sorted(set(errors))))
print(f'Validated {len(documents)} documentation pages, links, fragments, metadata, and static endpoints at {site}.')
