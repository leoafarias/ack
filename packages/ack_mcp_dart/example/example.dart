import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:ack_mcp_dart/ack_mcp_dart.dart';
import 'package:mcp_dart/mcp_dart.dart';

/// A Station-shaped contract: query plus a bounded, defaulted result limit.
final searchInput = Ack.object({
  'query': Ack.string()
      .minLength(1)
      .describe('Search query')
      .refine(
        (query) => query.trim().isNotEmpty,
        message: 'Query must contain non-whitespace characters.',
      ),
  'limit': Ack.integer().min(1).max(100).optional().withDefault(5),
});

Future<void> main() async {
  final server = McpServer(
    const Implementation(name: 'ack-search-example', version: '1.4.0'),
  );
  server.registerAckTool(
    'search',
    input: searchInput,
    description: 'Search documents with a default limit of five.',
    annotations: const ToolAnnotations(readOnlyHint: true),
    callback: (args, extra) =>
        CallToolResult(content: [TextContent(text: jsonEncode(args))]),
  );
  server.registerAckTool(
    'validate',
    input: Ack.object({}),
    description: 'Check that the server is available.',
    callback: (args, extra) =>
        CallToolResult(content: [TextContent(text: 'valid')]),
  );

  // tools/call search with {"query":"dart"} returns {"query":"dart","limit":5}.
  // {"query":" "} passes the advertised minLength but returns an ACK tool error.
  // {"query":"dart","limit":0} fails MCP validation before the callback.
  // Protocol messages own stdout; SDK diagnostics go to stderr.
  await server.connect(StdioServerTransport());
}
