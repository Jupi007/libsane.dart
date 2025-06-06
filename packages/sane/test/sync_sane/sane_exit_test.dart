import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.exit()', () {
    group(null, () {
      late final RawSane sane;

      setUpAll(() {
        setUpMockLibSane();

        final libsane = MockLibSane();
        when(() => libsane.sane_init(any(), any()))
            .thenReturn(SANE_Status.STATUS_GOOD);

        sane = RawSane(libsane);

        when(() => libsane.sane_get_devices(any(), any()))
            .thenAnswer((invocation) {
          final emptyDeviceArray = ffi.calloc<ffi.Pointer<SANE_Device>>(1);
          emptyDeviceArray[0] = ffi.nullptr;

          final devicesPointer = invocation.positionalArguments[0]
              as ffi.Pointer<ffi.Pointer<ffi.Pointer<SANE_Device>>>;
          devicesPointer.value = emptyDeviceArray;

          return SANE_Status.STATUS_GOOD;
        });
      });

      test(
        'can\'t exit without initialization',
        () {
          expect(sane.exit, throwsA(isA<SaneNotInitializedError>()));
        },
      );

      test('can exit after initialization', () {
        sane.init();
        expect(sane.exit, returnsNormally);
      });

      test(
        'any other SANE function calls than init throws SaneNotInitializedError',
        () {
          expect(sane.exit, throwsA(isA<SaneNotInitializedError>()));
          expect(sane.getDevices, throwsA(isA<SaneNotInitializedError>()));
        },
      );

      test('can init SANE again', () {
        expect(sane.init, returnsNormally);

        expect(sane.getDevices, returnsNormally);
        expect(sane.exit, returnsNormally);
      });
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
      expect(sane.exit, returnsNormally);

      sane.init();
      expect(() => sane.start(handle), throwsA(isA<SaneHandleClosedError>()));
    });
  });
}
