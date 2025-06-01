import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class ControlValueOptionMessage<T>
    implements IsolateMessage<ControlValueOptionResponse<T>> {
  const ControlValueOptionMessage(
    this.handle,
    this.index,
    this.action,
    this.value,
  );

  final SaneHandle handle;
  final int index;
  final SaneAction action;
  final T? value;

  @override
  Future<ControlValueOptionResponse<T>> exec(Sane sane) async {
    if (T == bool) {
      final result = await sane.controlBoolOption(
        handle: handle,
        index: index,
        action: action,
        value: value as bool?,
      );

      return ControlValueOptionResponse<bool>(result)
          as ControlValueOptionResponse<T>;
    } else if (T == int) {
      final result = await sane.controlIntOption(
        handle: handle,
        index: index,
        action: action,
        value: value as int?,
      );

      return ControlValueOptionResponse<int>(result)
          as ControlValueOptionResponse<T>;
    } else if (T == double) {
      final result = await sane.controlFixedOption(
        handle: handle,
        index: index,
        action: action,
        value: value as double?,
      );

      return ControlValueOptionResponse<double>(result)
          as ControlValueOptionResponse<T>;
    } else if (T == String) {
      final result = await sane.controlStringOption(
        handle: handle,
        index: index,
        action: action,
        value: value as String?,
      );

      return ControlValueOptionResponse<String>(result)
          as ControlValueOptionResponse<T>;
    }

    throw ArgumentError('Invalid value type "$T".');
  }
}

class ControlValueOptionResponse<T> implements IsolateResponse {
  ControlValueOptionResponse(this.result);

  final SaneOptionResult<T> result;
}
