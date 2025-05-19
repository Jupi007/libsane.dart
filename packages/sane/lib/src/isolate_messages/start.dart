import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class StartMessage implements IsolateMessage {
  StartMessage(this.handle);

  final SaneHandle handle;

  @override
  Future<StartResponse> exec(Sane sane) async {
    await sane.start(handle);
    return StartResponse();
  }
}

class StartResponse implements IsolateResponse {}
