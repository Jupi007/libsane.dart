import 'package:sane/src/isolate_messages/interface.dart';

class ExceptionResponse implements IsolateResponse {
  ExceptionResponse({
    required this.exception,
    required this.stackTrace,
  });

  final Object exception;
  final StackTrace stackTrace;
}
