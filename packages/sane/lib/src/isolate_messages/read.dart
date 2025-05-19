import 'dart:typed_data';

import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/sane.dart';
import 'package:sane/src/structures.dart';

class ReadMessage implements IsolateMessage<ReadResponse> {
  const ReadMessage(this.handle, this.bufferSize);

  final SaneHandle handle;
  final int bufferSize;

  @override
  Future<ReadResponse> exec(Sane sane) async {
    final bytes = await sane.read(handle, bufferSize);
    return ReadResponse(bytes);
  }
}

class ReadResponse implements IsolateResponse {
  ReadResponse(this.bytes);

  final Uint8List bytes;
}
