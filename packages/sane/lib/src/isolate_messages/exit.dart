import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';

class ExitMessage implements IsolateMessage {
  @override
  Future<ExitResponse> handle(Sane sane) async {
    sane.exit();
    return ExitResponse();
  }
}

class ExitResponse implements IsolateResponse {}
