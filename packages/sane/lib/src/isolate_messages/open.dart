import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:sane/src/structures.dart';

class OpenMessage implements IsolateMessage<OpenResponse> {
  OpenMessage(this.deviceName);

  final String deviceName;

  @override
  Future<OpenResponse> exec(RawSane sane) async {
    final handle = sane.open(deviceName);
    return OpenResponse(handle);
  }
}

class OpenResponse implements IsolateResponse {
  OpenResponse(this.handle);

  final SaneHandle handle;
}
