import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/raw_sane.dart';

class DisposeMessage implements IsolateMessage {
  @override
  Future<DisposeResponse> exec(RawSane _) async {
    return DisposeResponse();
  }
}

class DisposeResponse implements IsolateResponse {}
