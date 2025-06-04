import 'dart:ffi' as ffi;

import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/implementations/sync_sane.dart';
import 'package:test/test.dart';

import '../common/mock_libsane.dart';

// TODO
void main() {
  setUpAll(setUpMockLibSane);

  group('SyncSane.read()', () {
    test('throw SaneNotInitializedError when not initialized', () {
      final sane = SyncSane(MockLibSane());
      const handle = SaneHandle(deviceName: 'deviceName');
      expect(
        () => sane.read(handle, 128),
        throwsA(isA<SaneNotInitializedError>()),
      );
    });

    test('throw ArgumentError when bufferSize is <= 0', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);
      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);
      when(
        () => libsane.sane_read(any(), any(), any(), any()),
      ).thenReturn(SANE_Status.STATUS_EOF);

      sane.init();
      final handle = sane.open('deviceName');
      for (final bufferSize in [0, -128]) {
        expect(
          () => sane.read(handle, bufferSize),
          throwsA(isA<ArgumentError>()),
        );
      }
    });

    test('returns empty Uint8List when status is STATUS_EOF', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);
      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);
      when(
        () => libsane.sane_read(any(), any(), any(), any()),
      ).thenReturn(SANE_Status.STATUS_EOF);

      sane.init();
      final handle = sane.open('deviceName');
      final uintlist = sane.read(handle, 128);
      expect(uintlist.isEmpty, isTrue);
    });

    test('returns Uint8List of scan data', () {
      final libsane = MockLibSane();
      final sane = SyncSane(libsane);

      when(
        () => libsane.sane_init(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);
      when(
        () => libsane.sane_open(any(), any()),
      ).thenReturn(SANE_Status.STATUS_GOOD);
      when(
        () => libsane.sane_read(any(), any(), any(), any()),
      ).thenAnswer((invocation) {
        final bufferPointer =
            invocation.positionalArguments[1] as ffi.Pointer<ffi.UnsignedChar>;
        final bufferSize = invocation.positionalArguments[2] as int;
        final lengthPointer =
            invocation.positionalArguments[3] as ffi.Pointer<SANE_Int>;
        for (var i = 0; i < bufferSize; i++) {
          bufferPointer[i] = 255;
        }
        lengthPointer.value = bufferSize;

        return SANE_Status.STATUS_GOOD;
      });

      sane.init();
      final handle = sane.open('deviceName');
      final buffer = sane.read(handle, 128);
      expect(buffer.length, equals(128));
    });
  });
}
