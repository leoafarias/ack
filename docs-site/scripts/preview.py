"""Preview the static export locally, optionally mounted at /ack."""
import argparse
import os
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--port', type=int, default=4173)
parser.add_argument('--base-path', default=os.environ.get('DOCS_BASE_PATH', ''))
args = parser.parse_args()
base = args.base_path.rstrip('/')
if base and (not base.startswith('/') or '..' in base or base.startswith('//')):
    parser.error('base-path must be a path such as /ack')
root = Path(__file__).resolve().parents[1] / 'out'
if not root.is_dir():
    parser.error('Build the documentation before starting the preview.')

class Handler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        pathname = urlsplit(path).path
        if base:
            if pathname != base and not pathname.startswith(base + '/'):
                return str(root / '__outside_docs_mount__')
            pathname = pathname[len(base):] or '/'
        return super().translate_path(pathname)

    def guess_type(self, path):
        if path.endswith('/api/search'):
            return 'application/json'
        if path.endswith('.md'):
            return 'text/markdown'
        return super().guess_type(path)

server = ThreadingHTTPServer(('127.0.0.1', args.port), partial(Handler, directory=str(root)))
print(f'Preview: http://127.0.0.1:{args.port}{base}/', flush=True)
try:
    server.serve_forever()
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
