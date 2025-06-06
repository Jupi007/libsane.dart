import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/raw_sane.dart';

class ExitMessage implements IsolateMessage {
  @override
  Future<ExitResponse> exec(RawSane sane) async {
    sane.exit();
    return ExitResponse();
  }
}

class ExitResponse implements IsolateResponse {}
