import 'package:sane/sane.dart';
import 'package:sane/src/isolate_messages/interface.dart';

class CloseMessage implements IsolateMessage {
  const CloseMessage(this.handle);

  final SaneHandle handle;

  @override
  Future<CloseResponse> exec(Sane sane) async {
    await sane.close(handle);
    return CloseResponse();
  }
}

class CloseResponse implements IsolateResponse {}
