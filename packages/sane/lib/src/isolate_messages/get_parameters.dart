import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:sane/src/structures.dart';

class GetParametersMessage implements IsolateMessage<GetParametersResponse> {
  const GetParametersMessage(this.handle);

  final SaneHandle handle;

  @override
  Future<GetParametersResponse> exec(RawSane sane) async {
    final parameters = sane.getParameters(handle);
    return GetParametersResponse(parameters);
  }
}

class GetParametersResponse implements IsolateResponse {
  GetParametersResponse(this.parameters);

  final SaneParameters parameters;
}
