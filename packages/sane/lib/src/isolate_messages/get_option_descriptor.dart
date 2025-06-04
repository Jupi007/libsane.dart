import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class GetOptionDescriptorMessage
    implements IsolateMessage<GetOptionDescriptorResponse> {
  GetOptionDescriptorMessage({
    required this.handle,
    required this.index,
  });

  final SaneHandle handle;
  final int index;

  @override
  Future<GetOptionDescriptorResponse> exec(Sane sane) async {
    final optionDescriptor = await sane.getOptionDescriptor(handle, index);
    return GetOptionDescriptorResponse(optionDescriptor);
  }
}

class GetOptionDescriptorResponse implements IsolateResponse {
  GetOptionDescriptorResponse(this.optionDescriptor);

  final SaneOptionDescriptor? optionDescriptor;
}
