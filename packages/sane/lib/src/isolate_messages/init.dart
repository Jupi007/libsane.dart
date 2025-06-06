import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:sane/src/raw_sane_interface.dart';
import 'package:sane/src/structures.dart';

class InitMessage implements IsolateMessage<InitResponse> {
  InitMessage(this.authCallback);

  final AuthCallback? authCallback;
  @override
  Future<InitResponse> exec(RawSane sane) async {
    final version = sane.init(authCallback: authCallback);
    return InitResponse(version);
  }
}

class InitResponse implements IsolateResponse {
  InitResponse(this.version);

  final SaneVersion version;
}
