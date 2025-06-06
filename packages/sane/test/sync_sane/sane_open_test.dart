import 'dart:ffi' as ffi;

import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/extensions.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.open()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final sane = RawSane(MockLibSane());
      expect(sane.open('deviceName'), throwsA(isA<SaneNotInitializedError>()));
    });

    test('throws SaneStatusException when status is not STATUS_GOOD', () {
      final libsane = MockLibSane();
      final sane = RawSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_IO_ERROR);

      sane.init();

      expect(() => sane.open('deviceName'), throwsA(isA<SaneIoException>()));
    });

    test('with device name string', () {
      final libsane = MockLibSane();
      final sane = RawSane(libsane);

      const deviceName = 'deviceName';

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_open(any(), any()),
      ).thenAnswer((invocation) {
        final deviceNamePointer =
            invocation.positionalArguments[0] as ffi.Pointer<SANE_Char>;
        expect(deviceNamePointer.toDartString(), equals(deviceName));

        final handlePointer =
            invocation.positionalArguments[1] as ffi.Pointer<SANE_Handle>;
        handlePointer.value = SANE_Handle.fromAddress(0x1234);

        return SANE_Status.STATUS_GOOD;
      });

      sane.init();

      final handle = sane.open(deviceName);
      expect(handle.deviceName, equals(deviceName));
    });

    test('with with sane device class', () {
      final libsane = MockLibSane();
      final sane = RawSane(libsane);

      const deviceName = 'deviceName';
      const device = SaneDevice(
        name: deviceName,
        vendor: 'vendor',
        model: 'model',
        type: 'type',
      );

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_open(any(), any()),
      ).thenAnswer((invocation) {
        final deviceNamePointer =
            invocation.positionalArguments[0] as ffi.Pointer<SANE_Char>;
        expect(deviceNamePointer.toDartString(), equals(deviceName));

        return SANE_Status.STATUS_GOOD;
      });

      sane.init();
      sane.openDevice(device);
    });
  });
}
