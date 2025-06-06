import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:sane/src/structures.dart';

class GetDevicesMessage implements IsolateMessage<GetDevicesResponse> {
  GetDevicesMessage({required this.localOnly});

  final bool localOnly;

  @override
  Future<GetDevicesResponse> exec(RawSane sane) async {
    final devices = sane.getDevices(localOnly: localOnly);
    return GetDevicesResponse(devices);
  }
}

class GetDevicesResponse implements IsolateResponse {
  GetDevicesResponse(this.devices);

  final List<SaneDevice> devices;
}
