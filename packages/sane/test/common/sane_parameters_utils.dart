import 'dart:ffi' as ffi;

import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/extensions.dart';

void assignToSaneParametersPointer({
  required ffi.Pointer<SANE_Parameters> pointer,
  SANE_Frame? format,
  bool? lastFrame,
  int? bytesPerLine,
  int? pixelsPerLine,
  int? lines,
  int? depth,
}) {
  final parameters = pointer.ref;

  parameters.formatAsInt = (format ?? SANE_Frame.FRAME_RGB).value;
  parameters.last_frame = (lastFrame ?? true).toSaneBool();
  parameters.bytes_per_line = bytesPerLine ?? 1416;
  parameters.pixels_per_line = pixelsPerLine ?? 472;
  parameters.lines = lines ?? 590;
  parameters.depth = depth ?? 8;
}
