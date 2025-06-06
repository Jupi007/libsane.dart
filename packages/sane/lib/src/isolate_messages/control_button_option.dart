import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:sane/src/structures.dart';

class ControlButtonOptionMessage
    implements IsolateMessage<ControlButtonOptionResponse> {
  const ControlButtonOptionMessage(this.handle, this.index);

  final SaneHandle handle;
  final int index;

  @override
  Future<ControlButtonOptionResponse> exec(RawSane sane) async {
    final result = sane.controlButtonOption(
      handle: handle,
      index: index,
    );
    return ControlButtonOptionResponse(result);
  }
}

class ControlButtonOptionResponse implements IsolateResponse {
  ControlButtonOptionResponse(this.result);

  final SaneOptionResult<Null> result;
}
