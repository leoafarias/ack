import 'dart:io';

/// Prints whether a version is already published, for resumable release jobs.
Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart scripts/pub_release_status.dart <package> <version>',
    );
    exitCode = 64;
    return;
  }
  try {
    stdout.writeln(await isVersionPublished(args[0], args[1]));
  } on Exception catch (error) {
    stderr.writeln('Cannot determine publication status: $error');
    exitCode = 1;
  }
}

/// Checks the exact hosted version; only HTTP 404 means it is unpublished.
///
/// [server] allows testing against a local HTTP server. Network and server
/// failures propagate so a release cannot silently skip or duplicate an upload.
Future<bool> isVersionPublished(
  String package,
  String version, {
  Uri? server,
}) async {
  final uri = (server ?? Uri.parse('https://pub.dev')).resolve(
    '/api/packages/${Uri.encodeComponent(package)}/versions/${Uri.encodeComponent(version)}',
  );
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 15));
    final response = await request.close().timeout(const Duration(seconds: 15));
    await response.drain<void>().timeout(const Duration(seconds: 15));
    return switch (response.statusCode) {
      HttpStatus.ok => true,
      HttpStatus.notFound => false,
      final status => throw HttpException('Unexpected HTTP $status', uri: uri),
    };
  } finally {
    client.close(force: true);
  }
}
