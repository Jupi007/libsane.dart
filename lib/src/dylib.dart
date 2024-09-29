import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';

LibSane? _dylib;
LibSane get dylib {
  return _dylib ??= LibSane(ffi.DynamicLibrary.open("libsane.so"));
}
