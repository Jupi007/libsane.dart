import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class CancelMessage implements IsolateMessage {
  CancelMessage(this.handle);

  final SaneHandle handle;

  @override
  Future<CancelResponse> exec(Sane sane) async {
    await sane.cancel(handle);
    return CancelResponse();
  }
}

class CancelResponse implements IsolateResponse {}
