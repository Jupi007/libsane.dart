import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:meta/meta.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/dylib.dart';
import 'package:sane/src/extensions.dart';
import 'package:sane/src/logger.dart';

@internal
class SyncSane implements Sane {
  SyncSane([
    @visibleForTesting LibSane? libSaneOverride,
  ]) : _libSaneOverride = libSaneOverride;

  final LibSane? _libSaneOverride;
  LibSane get _libsane => _libSaneOverride ?? dylib;

  bool _initialized = false;

  final Map<SaneHandle, SANE_Handle> _pointerHandles = {};
  SANE_Handle _getPointerHandle(SaneHandle handle) => _pointerHandles[handle]!;

  ffi.NativeCallable<SANE_Auth_CallbackFunction>? _nativeAuthCallback;

  @override
  SaneVersion init({AuthCallback? authCallback}) {
    if (_initialized) throw SaneAlreadyInitializedError();

    void authCallbackAdapter(
      SANE_String_Const resource,
      ffi.Pointer<SANE_Char> username,
      ffi.Pointer<SANE_Char> password,
    ) {
      final credentials = authCallback!(resource.toDartString());
      for (var i = 0;
          i < credentials.username.length && i < SANE_MAX_USERNAME_LEN;
          i++) {
        username[i] = credentials.username.codeUnitAt(i);
      }
      for (var i = 0;
          i < credentials.password.length && i < SANE_MAX_PASSWORD_LEN;
          i++) {
        password[i] = credentials.password.codeUnitAt(i);
      }
    }

    final versionCodePointer = ffi.calloc<SANE_Int>();
    _nativeAuthCallback = authCallback != null
        ? ffi.NativeCallable<SANE_Auth_CallbackFunction>.isolateLocal(
            authCallbackAdapter,
          )
        : null;
    final callbackPtr = _nativeAuthCallback?.nativeFunction ?? ffi.nullptr;

    try {
      final status = _libsane.sane_init(versionCodePointer, callbackPtr);
      logger.finest('sane_init() -> ${status.name}');
      status.check();

      final versionCode = versionCodePointer.value;
      final version = SaneVersion.fromCode(versionCode);
      logger.finest('SANE version: $version');

      _initialized = true;

      return version;
    } finally {
      ffi.calloc.free(versionCodePointer);
    }
  }

  @override
  void exit() {
    if (!_initialized) return;

    _initialized = false;

    _libsane.sane_exit();
    logger.finest('sane_exit()');

    _nativeAuthCallback?.close();
    _nativeAuthCallback = null;
  }

  @override
  List<SaneDevice> getDevices({bool localOnly = true}) {
    _checkIfInitialized();

    final deviceListPointer =
        ffi.calloc<ffi.Pointer<ffi.Pointer<SANE_Device>>>();

    try {
      final status = _libsane.sane_get_devices(
        deviceListPointer,
        localOnly.toSaneBool(),
      );
      logger.finest('sane_get_devices() -> ${status.name}');
      status.check();

      final devices = <SaneDevice>[];
      for (var i = 0; deviceListPointer.value[i] != ffi.nullptr; i++) {
        final nativeDevice = deviceListPointer.value[i].ref;
        devices.add(nativeDevice.toSaneDevice());
      }

      return List.unmodifiable(devices);
    } finally {
      ffi.calloc.free(deviceListPointer);
    }
  }

  @override
  SaneHandle open(String deviceName) {
    _checkIfInitialized();

    final nativeHandlePointer = ffi.calloc<SANE_Handle>();
    final deviceNamePointer = deviceName.toSaneString();
    late final SaneHandle handle;

    try {
      final status = _libsane.sane_open(deviceNamePointer, nativeHandlePointer);
      logger.finest('sane_open() -> ${status.name}');
      status.check();

      handle = SaneHandle(deviceName: deviceName);
      _pointerHandles.addAll({
        handle: nativeHandlePointer.value,
      });
    } finally {
      ffi.calloc.free(nativeHandlePointer);
      ffi.calloc.free(deviceNamePointer);
    }

    return handle;
  }

  @override
  SaneHandle openDevice(SaneDevice device) {
    return open(device.name);
  }

  @override
  void close(SaneHandle handle) {
    _checkIfInitialized();

    _libsane.sane_close(_getPointerHandle(handle));
    _pointerHandles.remove(handle);
    logger.finest('sane_close()');
  }

  @override
  SaneOptionDescriptor getOptionDescriptor(
    SaneHandle handle,
    int index,
  ) {
    _checkIfInitialized();

    final optionDescriptorPointer =
        _libsane.sane_get_option_descriptor(_getPointerHandle(handle), index);

    try {
      return optionDescriptorPointer.ref.toSaneOptionDescriptorWithIndex(index);
    } finally {
      ffi.calloc.free(optionDescriptorPointer);
    }
  }

  @override
  List<SaneOptionDescriptor> getAllOptionDescriptors(
    SaneHandle handle,
  ) {
    _checkIfInitialized();

    final optionDescriptors = <SaneOptionDescriptor>[];

    for (var i = 0; true; i++) {
      final descriptorPointer =
          _libsane.sane_get_option_descriptor(_getPointerHandle(handle), i);
      try {
        if (descriptorPointer == ffi.nullptr) break;
        optionDescriptors.add(
          descriptorPointer.ref.toSaneOptionDescriptorWithIndex(i),
        );
      } finally {
        ffi.calloc.free(descriptorPointer);
      }
    }

    return optionDescriptors;
  }

  SaneOptionResult<T> _controlOption<T>({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    T? value,
  }) {
    _checkIfInitialized();

    final nativeOptionDescriptor = _libsane
        .sane_get_option_descriptor(_getPointerHandle(handle), index)
        .ref;
    final optionDescriptor =
        nativeOptionDescriptor.toSaneOptionDescriptorWithIndex(index);
    final optionType = optionDescriptor.type;
    final optionSize = optionDescriptor.size;

    final infoPointer = ffi.calloc<SANE_Int>();

    ffi.Pointer allocateOptionValue() {
      return switch (optionType) {
        SaneOptionValueType.bool => ffi.calloc<SANE_Bool>(optionSize),
        SaneOptionValueType.int => ffi.calloc<SANE_Int>(optionSize),
        SaneOptionValueType.fixed => ffi.calloc<SANE_Word>(optionSize),
        SaneOptionValueType.string => ffi.calloc<SANE_Char>(optionSize),
        SaneOptionValueType.button => ffi.nullptr,
        SaneOptionValueType.group => throw const SaneInvalidDataException(),
      };
    }

    final valuePointer = allocateOptionValue();

    if (action == SaneAction.setValue) {
      switch (optionType) {
        case SaneOptionValueType.bool when value is bool:
          (valuePointer as ffi.Pointer<SANE_Bool>).value = value.toSaneBool();
          break;

        case SaneOptionValueType.int when value is int:
          (valuePointer as ffi.Pointer<SANE_Int>).value = value;
          break;

        case SaneOptionValueType.fixed when value is double:
          (valuePointer as ffi.Pointer<SANE_Word>).value = value.toSaneFixed();
          break;

        case SaneOptionValueType.string when value is String:
          final utf8Value = value.toNativeUtf8();
          valuePointer.cast<Uint8>().asTypedList(optionSize).setAll(
                0,
                utf8Value.cast<Uint8>().asTypedList(optionSize),
              );
          ffi.calloc.free(utf8Value);
          break;

        case SaneOptionValueType.button:
          break;

        case SaneOptionValueType.group:
        default:
          throw const SaneInvalidDataException();
      }
    }

    final status = _libsane.sane_control_option(
      _getPointerHandle(handle),
      index,
      action.toNativeSaneAction(),
      valuePointer.cast<ffi.Void>(),
      infoPointer,
    );
    logger.finest(
      'sane_control_option($index, $action, $value) -> ${status.name}',
    );

    status.check();

    final infos = infoPointer.value.toSaneOptionInfoList();
    late final dynamic result;
    switch (optionType) {
      case SaneOptionValueType.bool:
        result = (valuePointer as ffi.Pointer<SANE_Bool>).value.toDartBool();

      case SaneOptionValueType.int:
        result = (valuePointer as ffi.Pointer<SANE_Int>).value;

      case SaneOptionValueType.fixed:
        result = (valuePointer as ffi.Pointer<SANE_Word>).value.toDartDouble();

      case SaneOptionValueType.string:
        result = (valuePointer as ffi.Pointer<SANE_Char>).toDartString();

      case SaneOptionValueType.button:
        result = null;

      default:
        throw const SaneInvalidDataException();
    }

    ffi.calloc.free(valuePointer);
    ffi.calloc.free(infoPointer);

    return SaneOptionResult(
      result: result,
      infos: infos,
    );
  }

  @override
  SaneOptionResult<bool> controlBoolOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    bool? value,
  }) {
    return _controlOption<bool>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  @override
  SaneOptionResult<int> controlIntOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    int? value,
  }) {
    return _controlOption<int>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  @override
  SaneOptionResult<double> controlFixedOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    double? value,
  }) {
    return _controlOption<double>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  @override
  SaneOptionResult<String> controlStringOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    String? value,
  }) {
    return _controlOption<String>(
      handle: handle,
      index: index,
      action: action,
      value: value,
    );
  }

  @override
  SaneOptionResult<Null> controlButtonOption({
    required SaneHandle handle,
    required int index,
  }) {
    return _controlOption<Null>(
      handle: handle,
      index: index,
      action: SaneAction.setValue,
      value: null,
    );
  }

  @override
  SaneParameters getParameters(SaneHandle handle) {
    _checkIfInitialized();

    final nativeParametersPointer = ffi.calloc<SANE_Parameters>();

    try {
      final status = _libsane.sane_get_parameters(
        _getPointerHandle(handle),
        nativeParametersPointer,
      );
      logger.finest('sane_get_parameters() -> ${status.name}');

      status.check();

      return nativeParametersPointer.ref.toSaneParameters();
    } finally {
      ffi.calloc.free(nativeParametersPointer);
    }
  }

  @override
  void start(SaneHandle handle) {
    _checkIfInitialized();

    final status = _libsane.sane_start(_getPointerHandle(handle));
    logger.finest('sane_start() -> ${status.name}');

    status.check();
  }

  @override
  Uint8List read(SaneHandle handle, int bufferSize) {
    _checkIfInitialized();

    final lengthPointer = ffi.calloc<SANE_Int>();
    final bufferPointer = ffi.calloc<SANE_Byte>(bufferSize);

    try {
      final status = _libsane.sane_read(
        _getPointerHandle(handle),
        bufferPointer,
        bufferSize,
        lengthPointer,
      );
      status.check();

      logger.finest('sane_read() -> ${status.name}');

      final length = lengthPointer.value;
      final buffer = bufferPointer.cast<Uint8>().asTypedList(length);

      return buffer;
    } finally {
      ffi.calloc.free(lengthPointer);
      ffi.calloc.free(bufferPointer);
    }
  }

  @override
  void cancel(SaneHandle handle) {
    _checkIfInitialized();

    _libsane.sane_cancel(_getPointerHandle(handle));
    logger.finest('sane_cancel()');
  }

  @override
  void setIOMode(SaneHandle handle, SaneIOMode mode) {
    _checkIfInitialized();

    final status = _libsane.sane_set_io_mode(
      _getPointerHandle(handle),
      mode.toNativeSaneBool(),
    );
    logger.finest('sane_set_io_mode() -> ${status.name}');

    status.check();
  }

  @pragma('vm:prefer-inline')
  void _checkIfInitialized() {
    if (!_initialized) throw SaneExitedError();
  }
}
