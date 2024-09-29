import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';

// TODO: use dylib.dart

LibSane? _dylib;
LibSane get dylib {
  return _dylib ??=
      LibSane(ffi.DynamicLibrary.open("/usr/lib/x86_64-linux-gnu/libsane.so"));
}
