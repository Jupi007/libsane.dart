import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:mocktail/mocktail.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/extensions.dart';
import 'package:sane/src/implementations/sync_sane.dart';
import 'package:test/test.dart';

class MockLibSane extends Mock implements LibSane {}

void main() {
  setUpAll(() {
    registerFallbackValue(ffi.Pointer<ffi.Int>.fromAddress(0));
    registerFallbackValue(SANE_Auth_Callback.fromAddress(0));
  });

  test('Test sane init without auth callback', () {
    final libsane = MockLibSane();

    when(() => libsane.sane_init(any(), any())).thenAnswer((invocation) {
      final versionPtr =
          invocation.positionalArguments[0] as ffi.Pointer<SANE_Int>;
      versionPtr.value = 0x01020003;
      return SANE_Status.STATUS_GOOD;
    });

    final sane = SyncSane(libsane);
    final version = sane.init();

    expect(version.toString(), equals('1.2.3'));
  });

  group('Test sane init with auth callback', () {
    void testCase({
      required String username,
      String? expectedUsername,
      required String password,
      String? expectedPassword,
      required String resourceName,
    }) {
      final libsane = MockLibSane();

      when(() => libsane.sane_init(any(), any()))
          .thenReturn(SANE_Status.STATUS_GOOD);

      SaneCredentials authCallback(localResourceName) {
        expect(localResourceName, equals(resourceName));
        return SaneCredentials(
          username: username,
          password: password,
        );
      }

      final sane = SyncSane(libsane);
      sane.init(authCallback: authCallback);

      final capturedArguments =
          verify(() => libsane.sane_init(captureAny(), captureAny())).captured;
      final nativeAuthCallbackPtr = capturedArguments[1]
          as ffi.Pointer<ffi.NativeFunction<SANE_Auth_CallbackFunction>>;

      final nativeAuthFunction = nativeAuthCallbackPtr.asFunction<
          void Function(
            SANE_String_Const resource,
            ffi.Pointer<SANE_Char> username,
            ffi.Pointer<SANE_Char> password,
          )>();

      final usernamePointer = ffi.malloc<ffi.Char>(SANE_MAX_USERNAME_LEN);
      final passwordPointer = ffi.malloc<ffi.Char>(SANE_MAX_PASSWORD_LEN);

      nativeAuthFunction(
        resourceName.toSaneString(),
        usernamePointer,
        passwordPointer,
      );

      expect(
        usernamePointer.toDartString(),
        equals(expectedUsername ?? username),
      );
      expect(
        passwordPointer.toDartString(),
        equals(expectedPassword ?? password),
      );

      ffi.malloc.free(usernamePointer);
      ffi.malloc.free(passwordPointer);
    }

    test(
      'and normal credentials',
      () => testCase(
        username: 'username',
        password: 'password',
        resourceName: 'resourceName',
      ),
    );

    // TODO: check for non LATIN-1 string
    // test(
    //   'and special characters credentials',
    //   () => testCase(
    //     username: '↓ß€¶”æµ€',
    //     password: 'þæßßłø¶ð',
    //     resourceName: '¶€ßø↓¶¢€’æµ€',
    //   ),
    // );

    test(
      'and overflow credentials',
      () => testCase(
        username: 'u' * SANE_MAX_USERNAME_LEN * 5,
        expectedUsername: 'u' * (SANE_MAX_USERNAME_LEN - 1),
        password: 'p' * SANE_MAX_PASSWORD_LEN * 5,
        expectedPassword: 'p' * (SANE_MAX_PASSWORD_LEN - 1),
        resourceName: 'r' * 512,
      ),
    );
  });

  test('Test sane init throw exception with wrong status', () {
    final libsane = MockLibSane();

    when(() => libsane.sane_init(any(), any()))
        .thenReturn(SANE_Status.STATUS_IO_ERROR);

    final sane = SyncSane(libsane);
    expect(sane.init, throwsA(isA<SaneIoException>()));
  });
}
