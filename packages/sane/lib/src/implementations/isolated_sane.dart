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
import 'package:sane/src/isolate_messages/interface.dart';
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

  SaneIsolate? _isolate;

  Future<T> _sendMessage<T extends IsolateResponse>(
    IsolateMessage<T> message,
  ) async {
    if (_isolate == null) throw SaneNotInitializedError();
    return _isolate!.sendMessage(message);
  }

  @override
  Future<SaneVersion> init({AuthCallback? authCallback}) async {
    if (_isolate != null) throw SaneAlreadyInitializedError();
    _isolate = await SaneIsolate.spawn(_backingSane);
    final response = await _isolate!.sendMessage(
      InitMessage(authCallback),
    );
    return response.version;
  }

  @override
  Future<void> exit() async {
    await _sendMessage(ExitMessage());
    _isolate = null;
  }

  @override
  Future<List<SaneDevice>> getDevices({bool localOnly = true}) async {
    final response = await _sendMessage(
      GetDevicesMessage(localOnly: localOnly),
    );

    return response.devices;
  }

  @override
  Future<SaneHandle> open(String name) async {
    final message = OpenMessage(name);
    final response = await _sendMessage(message);
    return response.handle;
  }

  @override
  Future<SaneHandle> openDevice(SaneDevice device) {
    return open(device.name);
  }

  @override
  Future<void> close(SaneHandle handle) async {
    final message = CloseMessage(handle);
    await _sendMessage(message);
  }

  @override
  Future<SaneOptionDescriptor> getOptionDescriptor(
    SaneHandle handle,
    int index,
  ) async {
    final message = GetOptionDescriptorMessage(handle: handle, index: index);
    final response = await _sendMessage(message);
    return response.optionDescriptor;
  }

  @override
  Future<List<SaneOptionDescriptor>> getAllOptionDescriptors(
    SaneHandle handle,
  ) async {
    final message = GetAllOptionDescriptorsMessage(handle: handle);
    final response = await _sendMessage(message);
    return response.optionDescriptors;
  }

  @override
  Future<SaneOptionResult<bool>> controlBoolOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    bool? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _sendMessage(message);
    return response.result;
  }

  @override
  Future<SaneOptionResult<int>> controlIntOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    int? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _sendMessage(message);
    return response.result;
  }

  @override
  Future<SaneOptionResult<double>> controlFixedOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    double? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _sendMessage(message);
    return response.result;
  }

  @override
  Future<SaneOptionResult<String>> controlStringOption({
    required SaneHandle handle,
    required int index,
    required SaneAction action,
    String? value,
  }) async {
    final message = ControlValueOptionMessage(handle, index, action, value);
    final response = await _sendMessage(message);
    return response.result;
  }

  @override
  Future<SaneOptionResult<Null>> controlButtonOption({
    required SaneHandle handle,
    required int index,
  }) async {
    final message = ControlButtonOptionMessage(handle, index);
    final response = await _sendMessage(message);
    return response.result;
  }

  @override
  Future<SaneParameters> getParameters(SaneHandle handle) async {
    final message = GetParametersMessage(handle);
    final response = await _sendMessage(message);
    return response.parameters;
  }

  @override
  Future<void> start(SaneHandle handle) async {
    final message = StartMessage(handle);
    await _sendMessage(message);
  }

  @override
  Future<Uint8List> read(SaneHandle handle, int bufferSize) async {
    final message = ReadMessage(handle, bufferSize);
    final response = await _sendMessage(message);
    return response.bytes;
  }

  @override
  Future<void> cancel(SaneHandle handle) async {
    final message = CancelMessage(handle);
    await _sendMessage(message);
  }

  @override
  Future<void> setIOMode(SaneHandle handle, SaneIOMode mode) async {
    final message = SetIOModeMessage(handle, mode);
    await _sendMessage(message);
  }
}
