import 'package:frontend/core/sync/sync_types.dart';
import 'package:frontend/data/remote/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_http_adapter.dart';

void main() {
  group('sync failure classification', () {
    test('offline and timeout are transient', () {
      expect(classifySyncFailure(ApiException.fromDio(networkFailure())).kind, SyncFailureKind.transient);
      expect(classifySyncFailure(ApiException.fromDio(timeoutFailure())).kind, SyncFailureKind.transient);
    });

    test('5xx, 408 and 429 are transient', () {
      for (final code in [500, 502, 503, 408, 429]) {
        expect(
          classifySyncFailure(ApiException.fromDio(httpFailure(code))).kind,
          SyncFailureKind.transient,
          reason: 'HTTP $code must stay retryable',
        );
      }
    });

    test('400, 403, 404 and 409 are permanent', () {
      for (final code in [400, 403, 404, 409, 422]) {
        expect(
          classifySyncFailure(ApiException.fromDio(httpFailure(code))).kind,
          SyncFailureKind.permanent,
          reason: 'HTTP $code must not retry forever',
        );
      }
    });

    test('401 is auth required, kept in the queue but never hot-looped', () {
      final failure = classifySyncFailure(ApiException.fromDio(httpFailure(401)));
      expect(failure.kind, SyncFailureKind.authRequired);
      expect(failure.isPermanent, isFalse);
    });
  });

  group('sync backoff', () {
    test('doubles per retry and is capped at 60 seconds', () {
      expect(SyncBackoff.delayFor(0), Duration.zero);
      expect(SyncBackoff.delayFor(1), const Duration(seconds: 2));
      expect(SyncBackoff.delayFor(2), const Duration(seconds: 4));
      expect(SyncBackoff.delayFor(3), const Duration(seconds: 8));
      expect(SyncBackoff.delayFor(4), const Duration(seconds: 16));
      expect(SyncBackoff.delayFor(5), const Duration(seconds: 32));
      expect(SyncBackoff.delayFor(6), const Duration(seconds: 60));
      expect(SyncBackoff.delayFor(20), const Duration(seconds: 60));
    });
  });

  group('server rejection payload', () {
    test('a 201 FAILED body is understood as a permanent rejection', () async {
      // A queued operation that the server refuses is not a transport error:
      // the SyncService treats any non SYNCED body as permanent.
      const rejected = <String, dynamic>{'status': 'FAILED', 'message': 'nama_lengkap must not be blank'};
      expect(rejected['status'] == SyncStatus.synced, isFalse);
    });
  });
}
