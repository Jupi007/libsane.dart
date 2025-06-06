import 'dart:typed_data';

import 'package:sane/src/isolate_messages/interface.dart';
import 'package:sane/src/raw_sane.dart';
import 'package:sane/src/structures.dart';

class ReadMessage implements IsolateMessage<ReadResponse> {
  const ReadMessage(this.handle, this.bufferSize);

  final SaneHandle handle;
  final int bufferSize;

  @override
  Future<ReadResponse> exec(RawSane sane) async {
    final bytes = sane.read(handle, bufferSize);
    return ReadResponse(bytes);
  }
}

class ReadResponse implements IsolateResponse {
  ReadResponse(this.bytes);

  final Uint8List bytes;
}
