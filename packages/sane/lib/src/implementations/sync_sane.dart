import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:sane/sane.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/dylib.dart';
import 'package:sane/src/extensions.dart';

final _logger = Logger('sane');

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
      ffi.Pointer<SANE_Char> usernamePointer,
      ffi.Pointer<SANE_Char> passwordPointer,
    ) {
      void copyToPointer(ffi.Pointer<SANE_Char> pointer, String string) {
        final utf8String = string.toSaneString();
        final stringBytes = utf8String.cast<ffi.Uint8>();

        for (var i = 0; true; i++) {
          if (i < SANE_MAX_USERNAME_LEN - 1 && stringBytes[i] != 0) {
            pointer[i] = stringBytes[i];
            continue;
          }

          pointer[i] = 0;
          break;
        }

        ffi.calloc.free(utf8String);
      }

      final credentials =
          authCallback!(resource.cast<ffi.Utf8>().toDartString());

      copyToPointer(usernamePointer, credentials.username);
      copyToPointer(passwordPointer, credentials.password);
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
      _logger.finest('sane_init() -> ${status.name}');

      status.check();

      final versionCode = versionCodePointer.value;
      final version = SaneVersion.fromCode(versionCode);
      _logger.finest('SANE version: $version');

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
    _logger.finest('sane_exit()');

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
      _logger.finest('sane_get_devices() -> ${status.name}');

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
      _logger.finest('sane_open() -> ${status.name}');

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
    _logger.finest('sane_close()');
  }

  @override
  SaneOptionDescriptor getOptionDescriptor(
    SaneHandle handle,
    int index,
  ) {
    _checkIfInitialized();

    final optionDescriptorPointer =
        _libsane.sane_get_option_descriptor(_getPointerHandle(handle), index);

    return optionDescriptorPointer.ref.toSaneOptionDescriptorWithIndex(index);
  }

  @override
  List<SaneOptionDescriptor> getAllOptionDescriptors(
    SaneHandle handle,
  ) {
    _checkIfInitialized();

    final optionDescriptors = <SaneOptionDescriptor>[];

    for (var i = 0; true; i++) {
      final optionDescriptorPointer =
          _libsane.sane_get_option_descriptor(_getPointerHandle(handle), i);

      if (optionDescriptorPointer == ffi.nullptr) break;
      optionDescriptors.add(
        optionDescriptorPointer.ref.toSaneOptionDescriptorWithIndex(i),
      );
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

    final optionDescriptor = _libsane
        .sane_get_option_descriptor(_getPointerHandle(handle), index)
        .ref
        .toSaneOptionDescriptorWithIndex(index);
    final optionType = optionDescriptor.type;
    final optionSize = optionDescriptor.size;

    final infoPointer = ffi.calloc<SANE_Int>();

    final valuePointer = () {
      return switch (optionType) {
        SaneOptionValueType.bool => ffi.calloc<SANE_Bool>(optionSize),
        SaneOptionValueType.int => ffi.calloc<SANE_Int>(optionSize),
        SaneOptionValueType.fixed => ffi.calloc<SANE_Word>(optionSize),
        SaneOptionValueType.string => ffi.calloc<SANE_Char>(optionSize),
        SaneOptionValueType.button => ffi.nullptr,
        SaneOptionValueType.group => throw const SaneInvalidDataException(),
      };
    }();

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
          valuePointer.cast<ffi.Uint8>().asTypedList(optionSize).setAll(
                0,
                utf8Value.cast<ffi.Uint8>().asTypedList(optionSize),
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
    _logger.finest(
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
      _logger.finest('sane_get_parameters() -> ${status.name}');

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
    _logger.finest('sane_start() -> ${status.name}');

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
      _logger.finest('sane_read() -> ${status.name}');

      try {
        status.check();
      } on SaneEofException catch (_) {
        return Uint8List.fromList([]);
      }

      final length = lengthPointer.value;
      return Uint8List.fromList(
        bufferPointer.cast<ffi.Uint8>().asTypedList(length),
      );
    } finally {
      ffi.calloc.free(lengthPointer);
      ffi.calloc.free(bufferPointer);
    }
  }

  @override
  void cancel(SaneHandle handle) {
    _checkIfInitialized();

    _libsane.sane_cancel(_getPointerHandle(handle));
    _logger.finest('sane_cancel()');
  }

  @override
  void setIOMode(SaneHandle handle, SaneIOMode mode) {
    _checkIfInitialized();

    final status = _libsane.sane_set_io_mode(
      _getPointerHandle(handle),
      mode.toNativeSaneBool(),
    );
    _logger.finest('sane_set_io_mode() -> ${status.name}');

    status.check();
  }

  @pragma('vm:prefer-inline')
  void _checkIfInitialized() {
    if (!_initialized) throw SaneNotInitializedError();
  }
}
