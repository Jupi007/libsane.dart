import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class SetIOModeMessage implements IsolateMessage {
  SetIOModeMessage(this.handle, this.ioMode);

  final SaneHandle handle;
  final SaneIOMode ioMode;

  @override
  Future<SetIOModeResponse> exec(Sane sane) async {
    await sane.setIOMode(handle, ioMode);
    return SetIOModeResponse();
  }
}

class SetIOModeResponse implements IsolateResponse {}
