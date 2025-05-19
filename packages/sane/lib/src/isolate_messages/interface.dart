import 'package:sane/sane.dart';

abstract interface class IsolateMessage<T extends IsolateResponse> {
  const IsolateMessage();

  Future<T> exec(Sane sane);
}

abstract interface class IsolateResponse {}
