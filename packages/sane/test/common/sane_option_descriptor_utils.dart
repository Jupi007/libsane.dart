import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/extensions.dart';

ffi.Pointer<SANE_Option_Descriptor> allocSaneOptionDescriptor({
  String? name,
  String? title,
  String? description,
  SANE_Value_Type? type,
  SANE_Unit? unit,
  int? size,
  int? capabilitiesBitset,
  SANE_Constraint_Type? constaint,
}) {
  final descriptorPointer = ffi.calloc<SANE_Option_Descriptor>();
  final descriptor = descriptorPointer.ref;

  descriptor.name = (name ?? 'option-name').toSaneString();
  descriptor.title = (title ?? 'Option Title').toSaneString();
  descriptor.desc = (description ?? 'Description of the option').toSaneString();
  descriptor.typeAsInt = (type ?? SANE_Value_Type.TYPE_STRING).value;
  descriptor.unitAsInt = (unit ?? SANE_Unit.UNIT_NONE).value;
  descriptor.size = size ?? 128;
  descriptor.cap = capabilitiesBitset ?? SANE_CAP_SOFT_SELECT;
  descriptor.constraint_typeAsInt =
      (constaint ?? SANE_Constraint_Type.CONSTRAINT_NONE).value;

  return descriptorPointer;
}
