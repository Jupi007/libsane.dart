import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/implementations/sync_sane.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.start()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final sane = SyncSane(MockLibSane());
      const handle = SaneHandle(deviceName: 'deviceName');
      expect(
        () => sane.start(handle),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('throws SaneStatusException when status is not STATUS_GOOD', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);
      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);
      when(
        () => libsane.sane_start(any()),
      ).thenReturn(SANE_Status.STATUS_IO_ERROR);

      sane.init();
      final handle = sane.open('deviceName');
      expect(() => sane.start(handle), throwsA(isA<SaneIoException>()));
    });

    test('returns normally', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

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
    });
  });
}
