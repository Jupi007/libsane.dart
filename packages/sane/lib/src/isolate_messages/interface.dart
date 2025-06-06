import 'package:sane/src/raw_sane.dart';

abstract interface class IsolateMessage<T extends IsolateResponse> {
  const IsolateMessage();

  Future<T> exec(RawSane sane);
}

abstract interface class IsolateResponse {}
