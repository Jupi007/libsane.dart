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
class RawSane implements IRawSane {
  RawSane([
    @visibleForTesting LibSane? libSaneOverride,
  ]) : _libSaneOverride = libSaneOverride;

  final LibSane? _libSaneOverride;
  LibSane get _libsane => _libSaneOverride ?? dylib;

  bool _initialized = false;

  final Map<SaneHandle, SANE_Handle> _pointerHandles = {};
  SANE_Handle _getPointerHandle(SaneHandle handle) {
    if (!_pointerHandles.containsKey(handle)) {
      throw SaneHandleClosedError(handle.deviceName);
    }

    return _pointerHandles[handle]!;
  }

  ffi.NativeCallable<SANE_Auth_CallbackFunction>? _nativeAuthCallback;

  /// Initializes the SANE library.
  @override
  SaneVersion init({AuthCallback? authCallback}) {
    if (_initialized) throw SaneAlreadyInitializedError();

    void authCallbackAdapter(
      SANE_String_Const resource,
      ffi.Pointer<SANE_Char> usernamePointer,
      ffi.Pointer<SANE_Char> passwordPointer,
    ) {
      final credentials =
          authCallback!(resource.cast<ffi.Utf8>().toDartString());

      usernamePointer.copyStringBytes(
        credentials.username,
        maxLenght: SANE_MAX_USERNAME_LEN,
      );
      passwordPointer.copyStringBytes(
        credentials.password,
        maxLenght: SANE_MAX_PASSWORD_LEN,
      );
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

  /// Disposes the SANE instance.
  ///
  /// Closes all device handles and all future calls are invalid.
  ///
  /// See also:
  ///
  /// - [`sane_exit`](https://sane-project.gitlab.io/standard/api.html#sane-exit)
  @override
  void exit() {
    _checkIfInitialized();

    _initialized = false;

    _libsane.sane_exit();
    _logger.finest('sane_exit()');

    _pointerHandles.clear();

    _nativeAuthCallback?.close();
    _nativeAuthCallback = null;
  }

  /// Queries the list of devices that are available.
  ///
  /// This method can be called repeatedly to detect when new devices become
  /// available. If argument [localOnly] is true, only local devices are
  /// returned (devices directly attached to the machine that SANE is running
  /// on). If it is `false`, the device list includes all remote devices that
  /// are accessible to the SANE library.
  ///
  /// See also:
  ///
  /// - [`sane_get_devices`](https://sane-project.gitlab.io/standard/api.html#sane-get-devices)
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

  /// Disposes the SANE device. Infers [cancel].
  ///
  /// See also:
  ///
  /// - [`sane_close`](https://sane-project.gitlab.io/standard/api.html#sane-close)
  @override
  void close(SaneHandle handle) {
    _checkIfInitialized();

    _libsane.sane_close(_getPointerHandle(handle));
    _logger.finest('sane_close()');

    _pointerHandles.remove(handle);
  }

  @override
  SaneOptionDescriptor? getOptionDescriptor(
    SaneHandle handle,
    int index,
  ) {
    _checkIfInitialized();

    final optionDescriptorPointer =
        _libsane.sane_get_option_descriptor(_getPointerHandle(handle), index);

    if (optionDescriptorPointer == ffi.nullptr) {
      return null;
    }

    return optionDescriptorPointer.ref.toSaneOptionDescriptorWithIndex(index);
  }

  @override
  List<SaneOptionDescriptor> getAllOptionDescriptors(
    SaneHandle handle,
  ) {
    _checkIfInitialized();

    final optionDescriptors = <SaneOptionDescriptor>[];

    for (var i = 0;; i++) {
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
    required SaneControlAction action,
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

    if (action == SaneControlAction.setValue) {
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
          (valuePointer as ffi.Pointer<SANE_Char>)
              .copyStringBytes(value, maxLenght: optionSize);
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
    required SaneControlAction action,
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
    required SaneControlAction action,
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
    required SaneControlAction action,
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
    required SaneControlAction action,
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
      action: SaneControlAction.setValue,
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

  /// Initiates acquisition of an image from the device.
  ///
  /// Exceptions:
  ///
  /// - Throws [SaneCancelledException] if the operation was cancelled through
  ///   a call to [cancel].
  /// - Throws [SaneDeviceBusyException] if the device is busy. The operation
  ///   should be later again.
  /// - Throws [SaneJammedException] if the document feeder is jammed.
  /// - Throws [SaneNoDocumentsException] if the document feeder is out of
  ///   documents.
  /// - Throws [SaneCoverOpenException] if the scanner cover is open.
  /// - Throws [SaneIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SaneNoMemoryException] if no memory is available.
  /// - Throws [SaneInvalidDataException] if the sane cannot be started with the
  ///   current set of options. The frontend should reload the option
  ///   descriptors.
  ///
  /// See also:
  ///
  /// - [`sane_start`](https://sane-project.gitlab.io/standard/api.html#sane-start)
  @override
  void start(SaneHandle handle) {
    _checkIfInitialized();

    final status = _libsane.sane_start(_getPointerHandle(handle));
    _logger.finest('sane_start() -> ${status.name}');

    status.check();
  }

  /// Reads image data from the device.
  ///
  /// The returned [Uint8List] is [bufferSize] bytes long or less. If it is
  /// zero, the end of the frame has been reached.
  ///
  /// Exceptions:
  ///
  /// - Throws [SaneCancelledException] if the operation was cancelled through
  ///   a call to [cancel].
  /// - Throws [SaneJammedException] if the document feeder is jammed.
  /// - Throws [SaneNoDocumentsException] if the document feeder is out of
  ///   documents.
  /// - Throws [SaneCoverOpenException] if the scanner cover is open.
  /// - Throws [SaneIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SaneNoMemoryException] if no memory is available.
  /// - Throws [SaneAccessDeniedException] if access to the device has been
  ///   denied due to insufficient or invalid authentication.
  ///
  /// See also:
  ///
  /// - [`sane_read`](https://sane-project.gitlab.io/standard/api.html#sane-read)
  @override
  Uint8List read(SaneHandle handle, int bufferSize) {
    _checkIfInitialized();

    if (bufferSize <= 0) {
      throw ArgumentError(
        'Invalid bufferSize "$bufferSize" value, should be greater than 0.',
      );
    }

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

  /// Tries to cancel the currently pending operation of the device immediately
  /// or as quickly as possible.
  ///
  /// See also:
  ///
  /// - [`sane_cancel`](https://sane-project.gitlab.io/standard/api.html#sane-cancel)
  @override
  void cancel(SaneHandle handle) {
    _checkIfInitialized();

    _libsane.sane_cancel(_getPointerHandle(handle));
    _logger.finest('sane_cancel()');
  }

  void setIOMode(SaneHandle handle, SaneIOMode mode) {
    _checkIfInitialized();

    final status = _libsane.sane_set_io_mode(
      _getPointerHandle(handle),
      mode.toSaneBool(),
    );
    _logger.finest('sane_set_io_mode() -> ${status.name}');

    status.check();
  }

  @pragma('vm:prefer-inline')
  void _checkIfInitialized() {
    if (!_initialized) throw SaneNotInitializedError();
  }
}
