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
    switch (value) {
      case final bool value:
        final result = await sane.controlBoolOption(
          handle: handle,
          index: index,
          action: action,
          value: value,
        );
        return ControlValueOptionResponse<bool>(result)
            as ControlValueOptionResponse<T>;

      case final int value:
        final result = await sane.controlIntOption(
          handle: handle,
          index: index,
          action: action,
          value: value,
        );
        return ControlValueOptionResponse<int>(result)
            as ControlValueOptionResponse<T>;

      case final double value:
        final result = await sane.controlFixedOption(
          handle: handle,
          index: index,
          action: action,
          value: value,
        );
        return ControlValueOptionResponse<double>(result)
            as ControlValueOptionResponse<T>;

      case final String value:
        final result = await sane.controlStringOption(
          handle: handle,
          index: index,
          action: action,
          value: value,
        );
        return ControlValueOptionResponse<String>(result)
            as ControlValueOptionResponse<T>;

      default:
        throw Exception('Invalid value type.');
    }
  }
}

class ControlValueOptionResponse<T> implements IsolateResponse {
  ControlValueOptionResponse(this.result);

  final SaneOptionResult<T> result;
}
