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

  group('SyncSane.getAllOptionDescriptors()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final sane = SyncSane(MockLibSane());
      const handle = SaneHandle(deviceName: 'deviceName');
      expect(
        () => sane.getAllOptionDescriptors(handle),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('returns a list of SaneOptionDescriptor', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      const descriptorLenght = 5;
      var callCount = 0;
      final descriptorPointers = <ffi.Pointer<SANE_Option_Descriptor>>[];
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        if (callCount++ < descriptorLenght) {
          final descriptorPointer = allocSaneOptionDescriptor();
          descriptorPointers.add(descriptorPointer);
          return descriptorPointer;
        }

        return ffi.nullptr;
      });

      sane.init();
      final handle = sane.open('deviceName');
      final optionDescriptors = sane.getAllOptionDescriptors(handle);
      expect(optionDescriptors.length, equals(descriptorLenght));

      for (final pointer in descriptorPointers) {
        ffi.calloc.free(pointer);
      }
    });
  });
}
