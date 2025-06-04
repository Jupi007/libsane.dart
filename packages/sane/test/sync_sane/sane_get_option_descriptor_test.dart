import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/implementations/sync_sane.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_option_descriptor_utils.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.getOptionDescriptor()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final sane = SyncSane(MockLibSane());
      const handle = SaneHandle(deviceName: 'deviceName');
      expect(
        () => sane.getOptionDescriptor(handle, 0),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('returns a SaneOptionDescriptor', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      const descriptorIndex = 5;
      late final ffi.Pointer<SANE_Option_Descriptor> descriptorPointer;
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        descriptorPointer = allocSaneOptionDescriptor();
        return descriptorPointer;
      });

      sane.init();
      final handle = sane.open('deviceName');
      final optionDescriptor =
          sane.getOptionDescriptor(handle, descriptorIndex);
      expect(optionDescriptor!.index, equals(descriptorIndex));

      ffi.calloc.free(descriptorPointer);
    });

    test('returns null when libsane returns nullptr', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenReturn(ffi.nullptr);

      sane.init();
      final handle = sane.open('deviceName');
      final optionDescriptor = sane.getOptionDescriptor(handle, 1);
      expect(optionDescriptor, equals(null));
    });
  });
}
