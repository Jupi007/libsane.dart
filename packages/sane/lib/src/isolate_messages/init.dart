import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

// TODO: auth callback
class InitMessage implements IsolateMessage<InitResponse> {
  @override
  Future<InitResponse> exec(Sane sane) async {
    final version = await sane.init();
    return InitResponse(version);
  }
}

class InitResponse implements IsolateResponse {
  InitResponse(this.version);

  final SaneVersion version;
}
