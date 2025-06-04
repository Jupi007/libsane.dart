import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/extensions.dart';

ffi.Pointer<SANE_Device> allocSaneDevice({
  required String name,
  required String vendor,
  required String model,
  required String type,
}) {
  final devicePointer = ffi.calloc<SANE_Device>();
  devicePointer.ref
    ..name = name.toSaneString()
    ..vendor = vendor.toSaneString()
    ..model = model.toSaneString()
    ..type = type.toSaneString();
  return devicePointer;
}

ffi.Pointer<ffi.Pointer<SANE_Device>> allocSaneDevicePointerArray(
  List<ffi.Pointer<SANE_Device>> devices,
) {
  final count = devices.length;
  final arrayPointer = ffi.calloc<ffi.Pointer<SANE_Device>>(count + 1);

  for (var i = 0; i < count; i++) {
    arrayPointer[i] = devices[i];
  }

  arrayPointer[count] = ffi.nullptr;
  return arrayPointer;
}

void freeDevicePtrArray(ffi.Pointer<ffi.Pointer<SANE_Device>> arrayPtr) {
  for (var i = 0;; i++) {
    final devicePtr = arrayPtr[i];
    if (devicePtr == ffi.nullptr) break;

    ffi.calloc.free(devicePtr.ref.name);
    ffi.calloc.free(devicePtr.ref.vendor);
    ffi.calloc.free(devicePtr.ref.model);
    ffi.calloc.free(devicePtr.ref.type);
    ffi.calloc.free(devicePtr);
  }
  ffi.calloc.free(arrayPtr);
}
