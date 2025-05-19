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
import 'package:sane/src/isolate_messages/open.dart';
import 'package:sane/src/isolate_messages/read.dart';
import 'package:sane/src/isolate_messages/set_io_mode.dart';
import 'package:sane/src/isolate_messages/start.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

@internal
class IsolatedSane implements Sane {
  IsolatedSane(Sane backingSane) : _backingSane = backingSane;

  final Sane _backingSane;

  bool _exited = false;
  SaneIsolate? _isolate;

  Future<SaneIsolate> _getIsolate() async {
    if (_exited) throw SaneExitedError();
    return _isolate ??= await SaneIsolate.spawn(_backingSane);
  }

  @override
  Future<SaneVersion> init({AuthCallback? authCallback}) async {
    final isolate = await _getIsolate();
    final response = await isolate.sendMessage(
      InitMessage(authCallback),
    );
    return response.version;
  }

  @override
  Future<void> exit() async {
    final isolate = _isolate;

    if (_exited) return;

    _exited = true;

    if (isolate == null) return;

    await isolate.sendMessage(ExitMessage());

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

  @override
  Future<SaneHandle> open(String name) async {
    final isolate = await _getIsolate();
    final message = OpenMessage(name);
    final response = await isolate.sendMessage(message);
    return response.handle;
  }

  @override
  Future<SaneHandle> openDevice(SaneDevice device) {
    return open(device.name);
  }

  @override
  Future<void> close(SaneHandle handle) async {
    final isolate = await _getIsolate();
    final message = CloseMessage(handle);
    await isolate.sendMessage(message);
  }

  @override
  Future<SaneOptionDescriptor> getOptionDescriptor(
    SaneHandle handle,
    int index,
  ) async {
    final isolate = await _getIsolate();
    final message = GetOptionDescriptorMessage(handle: handle, index: index);
    final response = await isolate.sendMessage(message);
    return response.optionDescriptor;
  }

  @override
  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(
    SaneHandle handle,
  ) async {
    final isolate = await _getIsolate();
    final message = GetAllOptionDescriptorsMessage(handle: handle);
    final response = await isolate.sendMessage(message);
    return response.optionDescriptors;
  }

  @override
  Future<SaneOptionResult<bool>> controlBoolOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    bool? value,
  }) async {
    final isolate = await _getIsolate();
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await isolate.sendMessage(message);
    return response.result;
  }

  @override
  Future<SaneOptionResult<int>> controlIntOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    int? value,
  }) async {
    final isolate = await _getIsolate();
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await isolate.sendMessage(message);
    return response.result;
  }

  @override
  Future<SaneOptionResult<double>> controlFixedOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    double? value,
  }) async {
    final isolate = await _getIsolate();
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await isolate.sendMessage(message);
    return response.result;
  }

  @override
  Future<SaneOptionResult<String>> controlStringOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    String? value,
  }) async {
    final isolate = await _getIsolate();
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await isolate.sendMessage(message);
    return response.result;
  }

  @override
  Future<SaneOptionResult<Null>> controlButtonOption({
    required SaneHandle handle,
    required int index,
  }) async {
    final isolate = await _getIsolate();
    final message = ControlButtonOptionMessage(handle, index);
    final response = await isolate.sendMessage(message);
    return response.result;
  }

  @override
  Future<SaneParameters> getParameters(SaneHandle handle) async {
    final isolate = await _getIsolate();
    final message = GetParametersMessage(handle);
    final response = await isolate.sendMessage(message);
    return response.parameters;
  }

  @override
  Future<void> start(SaneHandle handle) async {
    final isolate = await _getIsolate();
    final message = StartMessage(handle);
    await isolate.sendMessage(message);
  }

  @override
  Future<Uint8List> read(SaneHandle handle, int bufferSize) async {
    final isolate = await _getIsolate();
    final message = ReadMessage(handle, bufferSize);
    final response = await isolate.sendMessage(message);
    return response.bytes;
  }

  @override
  Future<void> cancel(SaneHandle handle) async {
    final isolate = await _getIsolate();
    final message = CancelMessage(handle);
    await isolate.sendMessage(message);
  }

  @override
  Future<void> setIOMode(SaneHandle handle, SaneIOMode mode) async {
    final isolate = await _getIsolate();
    final message = SetIOModeMessage(handle, mode);
    await isolate.sendMessage(message);
  }
}
