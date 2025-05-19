import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sane/src/exceptions.dart';
import 'package:sane/src/isolate.dart';
import 'package:sane/src/isolate_messages/cancel.dart';
import 'package:sane/src/isolate_messages/close.dart';
import 'package:sane/src/isolate_messages/control_button_option.dart';
import 'package:sane/src/isolate_messages/control_option.dart';
import 'package:sane/src/isolate_messages/exit.dart';
import 'package:sane/src/isolate_messages/get_all_option_descriptors.dart';
import 'package:sane/src/isolate_messages/get_devices.dart';
import 'package:sane/src/isolate_messages/get_option_descriptor.dart';
import 'package:sane/src/isolate_messages/get_parameters.dart';
import 'package:sane/src/isolate_messages/init.dart';
import 'package:sane/src/isolate_messages/read.dart';
import 'package:sane/src/isolate_messages/start.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

@internal
class IsolatedSane implements Sane {
  IsolatedSane(Sane backingSane) : _backingSane = backingSane;

  final Sane _backingSane;

  bool _disposed = false;
  SaneIsolate? _isolate;

  Future<SaneIsolate> _getIsolate() async {
    if (_disposed) throw SaneDisposedError();
    return _isolate ??= await SaneIsolate.spawn(_backingSane);
  }

  @override
  Future<SaneVersion> init([AuthCallback? authCallback]) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(InitMessage());
    return response.version;
  }

  @override
  Future<void> exit({bool force = false}) async {
    final isolate = _isolate;

    if (_disposed) return;

    _disposed = true;

    if (isolate == null) return;

    if (force) {
      isolate.kill();
    } else {
      await isolate.sendMessage(ExitMessage());
    }

    _isolate = null;
  }

  @override
  Future<List<SaneDevice>> getDevices({
    required bool localOnly,
  }) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      GetDevicesMessage(localOnly: localOnly),
    );

    return response.devices;
  }
}

class NativeSaneDevice implements SaneDevice {
  NativeSaneDevice({
    required IsolatedSane sane,
    required this.name,
    required this.type,
    required this.vendor,
    required this.model,
  }) : _sane = sane;

  final IsolatedSane _sane;

  bool _closed = false;

  @override
  final String name;

  @override
  final String type;

  @override
  final String? vendor;

  @override
  final String model;

  @override
  Future<void> cancel() async {
    if (_closed) return;

    final isolate = _sane._isolate;

    if (isolate == null) return;

    final message = CancelMessage(name);
    await isolate.sendMessage(message);
  }

  @override
  Future<void> close() async {
    if (_closed) return;

    _closed = true;

    final isolate = _sane._isolate;

    if (isolate == null) return;

    final message = CloseMessage(name);
    await isolate.sendMessage(message);
  }

  @override
  Future<Uint8List> read({required int bufferSize}) async {
    final isolate = await _sane._getIsolate();
    final message = ReadMessage(bufferSize: bufferSize, deviceName: name);
    final response = await isolate.sendMessage(message);

    return response.bytes;
  }

  @override
  Future<void> start() async {
    final isolate = await _sane._getIsolate();
    final message = StartMessage(name);
    await isolate.sendMessage(message);
  }

  @override
  Future<SaneOptionDescriptor> getOptionDescriptor(int index) async {
    final isolate = await _sane._getIsolate();
    final message = GetOptionDescriptorMessage(deviceName: name, index: index);

    final GetOptionDescriptorResponse(:optionDescriptor) =
        await isolate.sendMessage(message);

    return optionDescriptor;
  }

  @override
  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors() async {
    final isolate = await _sane._getIsolate();
    final message = GetAllOptionDescriptorsMessage(name);

    final GetAllOptionDescriptorsResponse(:optionDescriptors) =
        await isolate.sendMessage(message);

    return optionDescriptors;
  }

  @override
  Future<SaneOptionResult<bool>> controlBoolOption(
    int index,
    SaneAction action,
    bool? value,
  ) async {
    final isolate = await _sane._getIsolate();
    final message = ControlValueOptionMessage(
      deviceName: name,
      index: index,
      action: action,
      value: value,
    );
    final response = await isolate.sendMessage(message);

    return response.result;
  }

  @override
  Future<SaneOptionResult<int>> controlIntOption(
    int index,
    SaneAction action,
    int? value,
  ) async {
    final isolate = await _sane._getIsolate();
    final message = ControlValueOptionMessage<int>(
      deviceName: name,
      index: index,
      action: action,
      value: value,
    );
    final response = await isolate.sendMessage(message);

    return response.result;
  }

  @override
  Future<SaneOptionResult<double>> controlFixedOption(
    int index,
    SaneAction action,
    double? value,
  ) async {
    final isolate = await _sane._getIsolate();
    final message = ControlValueOptionMessage<double>(
      deviceName: name,
      index: index,
      action: action,
      value: value,
    );
    final response = await isolate.sendMessage(message);

    return response.result;
  }

  @override
  Future<SaneOptionResult<String>> controlStringOption(
    int index,
    SaneAction action,
    String? value,
  ) async {
    final isolate = await _sane._getIsolate();
    final message = ControlValueOptionMessage<String>(
      deviceName: name,
      index: index,
      action: action,
      value: value,
    );
    final response = await isolate.sendMessage(message);

    return response.result;
  }

  @override
  Future<SaneOptionResult<Null>> controlButtonOption(int index) async {
    final isolate = await _sane._getIsolate();
    final message = ControlButtonOptionMessage(
      deviceName: name,
      index: index,
    );
    final response = await isolate.sendMessage(message);

    return response.result;
  }

  @override
  Future<SaneParameters> getParameters() async {
    final isolate = await _sane._getIsolate();
    final message = GetParametersMessage(name);
    final response = await isolate.sendMessage(message);
    return response.parameters;
  }
}
