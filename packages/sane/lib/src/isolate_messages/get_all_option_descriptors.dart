import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class GetAllOptionDescriptorsMessage
    implements IsolateMessage<GetAllOptionDescriptorsResponse> {
  GetAllOptionDescriptorsMessage({required this.handle});

  final SaneHandle handle;

  @override
  Future<GetAllOptionDescriptorsResponse> exec(Sane sane) async {
    final optionDescriptors = await sane.getAllOptionDescriptors(handle);
    return GetAllOptionDescriptorsResponse(optionDescriptors);
  }
}

class GetAllOptionDescriptorsResponse implements IsolateResponse {
  GetAllOptionDescriptorsResponse(this.optionDescriptors);

  final List<SaneOptionDescriptor> optionDescriptors;
}
