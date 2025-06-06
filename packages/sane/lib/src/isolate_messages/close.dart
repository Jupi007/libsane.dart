import 'package:sane/sane.dart';
import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/raw_sane.dart';

class CloseMessage implements IsolateMessage {
  const CloseMessage(this.handle);

  final SaneHandle handle;

  @override
  Future<CloseResponse> exec(RawSane sane) async {
    sane.close(handle);
    return CloseResponse();
  }
}

class CloseResponse implements IsolateResponse {}
