import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class OpenMessage implements IsolateMessage<OpenResponse> {
  OpenMessage(this.deviceName);

  final String deviceName;

  @override
  Future<OpenResponse> exec(Sane sane) async {
    final handle = await sane.open(deviceName);
    return OpenResponse(handle);
  }
}

class OpenResponse implements IsolateResponse {
  OpenResponse(this.handle);

  final SaneHandle handle;
}
