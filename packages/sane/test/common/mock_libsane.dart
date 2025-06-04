import 'dart:ffi' as ffi;

import 'package:mocktail/mocktail.dart';
import 'package:sane/src/bindings.g.dart';

class MockLibSane extends Mock implements LibSane {}

void setUpMockLibSane() {
  registerFallbackValue(ffi.Pointer<ffi.Int>.fromAddress(0));
  registerFallbackValue(SANE_Auth_Callback.fromAddress(0));
  registerFallbackValue(SANE_Action.fromValue(0));
}
