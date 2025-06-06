import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';
import '../common/sane_option_descriptor_utils.dart';

void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.controlOption()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final sane = RawSane(MockLibSane());
      const handle = SaneHandle(deviceName: 'deviceName');
      expect(
        () => sane.controlBoolOption(
          handle: handle,
          index: 0,
          action: SaneControlAction.setAuto,
        ),
        throwsA(isA<SaneNotInitializedError>()),
      );
      expect(
        () => sane.controlIntOption(
          handle: handle,
          index: 0,
          action: SaneControlAction.setAuto,
        ),
        throwsA(isA<SaneNotInitializedError>()),
      );
      expect(
        () => sane.controlFixedOption(
          handle: handle,
          index: 0,
          action: SaneControlAction.setAuto,
        ),
        throwsA(isA<SaneNotInitializedError>()),
      );
      expect(
        () => sane.controlStringOption(
          handle: handle,
          index: 0,
          action: SaneControlAction.setAuto,
        ),
        throwsA(isA<SaneNotInitializedError>()),
      );
      expect(
        () => sane.controlButtonOption(
          handle: handle,
          index: 0,
        ),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('set an option', () {
      final libsane = MockLibSane();
      final sane = RawSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);

      const optionIndex = 5;
      late final ffi.Pointer<SANE_Option_Descriptor> descriptorPointer;
      when(
        () => libsane.sane_get_option_descriptor(any(), any()),
      ).thenAnswer((invocation) {
        final index = invocation.positionalArguments[1] as int;
        expect(index, equals(optionIndex));
        descriptorPointer = allocSaneOptionDescriptor(
          type: SANE_Value_Type.TYPE_STRING,
        );
        return descriptorPointer;
      });

      when(
        () => libsane.sane_control_option(any(), any(), any(), any(), any()),
      ).thenAnswer((invocation) {
        final index = invocation.positionalArguments[1] as int;
        expect(index, equals(optionIndex));

        return SANE_Status.STATUS_GOOD;
      });

      sane.init();
      final handle = sane.open('deviceName');
      final optionResult = sane.controlStringOption(
        handle: handle,
        index: optionIndex,
        action: SaneControlAction.setValue,
        value: 'test',
      );

      expect(optionResult.result, equals('test'));
      ffi.calloc.free(descriptorPointer);
    });

    // TODO: test get/set, with all value types, with overflow, etc.
  });
}
