import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.cancel()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final sane = RawSane(MockLibSane());
      const handle = SaneHandle(deviceName: 'deviceName');
      expect(
        () => sane.cancel(handle),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('returns normally', () {
      final libsane = MockLibSane();
      final sane = RawSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      sane.init();
      final handle = sane.open('deviceName');
      expect(() => sane.cancel(handle), returnsNormally);
    });
  });
}
