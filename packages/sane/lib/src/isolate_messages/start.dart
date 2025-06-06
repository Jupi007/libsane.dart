import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:sane/src/structures.dart';

class StartMessage implements IsolateMessage {
  StartMessage(this.handle);

  final SaneHandle handle;

  @override
  Future<StartResponse> exec(RawSane sane) async {
    sane.start(handle);
    return StartResponse();
  }
}

class StartResponse implements IsolateResponse {}
