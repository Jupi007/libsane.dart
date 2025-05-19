import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class GetParametersMessage implements IsolateMessage<GetParametersResponse> {
  const GetParametersMessage(this.handle);

  final SaneHandle handle;

  @override
  Future<GetParametersResponse> exec(Sane sane) async {
    final parameters = await sane.getParameters(handle);
    return GetParametersResponse(parameters);
  }
}

class GetParametersResponse implements IsolateResponse {
  GetParametersResponse(this.parameters);

  final SaneParameters parameters;
}
