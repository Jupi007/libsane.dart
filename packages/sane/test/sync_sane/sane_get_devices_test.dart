import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/implementations/sync_sane.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_device_utils.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.getDevices()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final sane = SyncSane(MockLibSane());
      expect(sane.getDevices, throwsA(isA<SaneNotInitializedError>()));
    });

    test('throws SaneStatusException when status is not STATUS_GOOD', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);
      when(
        () => libsane.sane_get_devices(any(), any()),
      ).thenReturn(SANE_Status.STATUS_NO_MEM);

      sane.init();
      expect(sane.getDevices, throwsA(isA<SaneNoMemoryException>()));
    });

    test('with empty device list', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      late ffi.Pointer<ffi.Pointer<SANE_Device>> emptyDeviceArray;
      when(
        () => libsane.sane_get_devices(any(), any()),
      ).thenAnswer((invocation) {
        emptyDeviceArray = ffi.calloc<ffi.Pointer<SANE_Device>>(1);
        emptyDeviceArray[0] = ffi.nullptr;

        final devicesPointer = invocation.positionalArguments[0]
            as ffi.Pointer<ffi.Pointer<ffi.Pointer<SANE_Device>>>;
        devicesPointer.value = emptyDeviceArray;

        return SANE_Status.STATUS_GOOD;
      });

      sane.init();
      final devices = sane.getDevices();
      expect(devices.length, equals(0));

      ffi.calloc.free(emptyDeviceArray);
    });

    test('with non-empty device list', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      late ffi.Pointer<ffi.Pointer<SANE_Device>> deviceArray;
      when(
        () => libsane.sane_get_devices(any(), any()),
      ).thenAnswer((invocation) {
        final device1 = allocSaneDevice(
          name: 'test:0',
          vendor: 'Foo',
          model: 'Bar 2400',
          type: 'flatbed',
        );
        final device2 = allocSaneDevice(
          name: 'test:1',
          vendor: 'BazCorp',
          model: 'ScanPro',
          type: 'sheetfed',
        );

        deviceArray = allocSaneDevicePointerArray([device1, device2]);
        final devicesPointer = invocation.positionalArguments[0]
            as ffi.Pointer<ffi.Pointer<ffi.Pointer<SANE_Device>>>;
        devicesPointer.value = deviceArray;

        return SANE_Status.STATUS_GOOD;
      });

      sane.init();
      final devices = sane.getDevices();
      expect(devices.length, equals(2));

      freeDevicePtrArray(deviceArray);
    });
  });
}
