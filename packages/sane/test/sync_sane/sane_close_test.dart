import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.close()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final sane = RawSane(MockLibSane());
      const handle = SaneHandle(deviceName: 'deviceName');
      expect(() => sane.close(handle), throwsA(isA<SaneNotInitializedError>()));
    });

    test('handle can\'t be used after being closed', () {
      final libsane = MockLibSane();
      final sane = RawSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_start(any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      sane.init();
      final handle = sane.open('deviceName');
      expect(() => sane.start(handle), returnsNormally);
      expect(() => sane.close(handle), returnsNormally);
      expect(() => sane.start(handle), throwsA(isA<SaneHandleClosedError>()));
      expect(() => sane.close(handle), throwsA(isA<SaneHandleClosedError>()));
    });
  });
}
