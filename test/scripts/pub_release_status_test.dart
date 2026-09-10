import 'dart:io';

import 'package:test/test.dart';

import '../../scripts/pub_release_status.dart';

void main() {
  for (final (status, published) in [(200, true), (404, false)]) {
    test('HTTP $status identifies whether the exact version exists', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <String>[];
      server.listen((request) {
        requests.add(request.uri.path);
        request.response.statusCode = status;
        request.response.close();
      });
      expect(
        await isVersionPublished(
          'ack_mcp_dart',
          '1.3.0',
          server: Uri.parse('http://127.0.0.1:${server.port}'),
        ),
        published,
      );
      expect(requests, ['/api/packages/ack_mcp_dart/versions/1.3.0']);
    });
  }
  test(
    'server errors stop publication instead of pretending version is absent',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) {
        request.response.statusCode = 503;
        request.response.close();
      });
      await expectLater(
        isVersionPublished(
          'ack',
          '1.3.0',
          server: Uri.parse('http://127.0.0.1:${server.port}'),
        ),
        throwsA(isA<HttpException>()),
      );
    },
  );
}
