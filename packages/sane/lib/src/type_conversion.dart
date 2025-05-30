import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:meta/meta.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/structures.dart';

@internal
SaneFrameFormat saneFrameFormatFromNative(SANE_Frame frame) {
  return switch (frame) {
    SANE_Frame.FRAME_GRAY => SaneFrameFormat.gray,
    SANE_Frame.FRAME_RGB => SaneFrameFormat.rgb,
    SANE_Frame.FRAME_RED => SaneFrameFormat.red,
    SANE_Frame.FRAME_GREEN => SaneFrameFormat.green,
    SANE_Frame.FRAME_BLUE => SaneFrameFormat.blue,
  };
}

@internal
SaneParameters saneParametersFromNative(SANE_Parameters parameters) {
  return SaneParameters(
    format: saneFrameFormatFromNative(parameters.format),
    lastFrame: dartBoolFromSaneBool(parameters.last_frame),
    bytesPerLine: parameters.bytes_per_line,
    pixelsPerLine: parameters.pixels_per_line,
    lines: parameters.lines,
    depth: parameters.depth,
  );
}

@internal
SaneOptionValueType saneOptionValueTypeFromNative(SANE_Value_Type valueType) {
  return switch (valueType) {
    SANE_Value_Type.TYPE_BOOL => SaneOptionValueType.bool,
    SANE_Value_Type.TYPE_INT => SaneOptionValueType.int,
    SANE_Value_Type.TYPE_FIXED => SaneOptionValueType.fixed,
    SANE_Value_Type.TYPE_STRING => SaneOptionValueType.string,
    SANE_Value_Type.TYPE_BUTTON => SaneOptionValueType.button,
    SANE_Value_Type.TYPE_GROUP => SaneOptionValueType.group,
  };
}

@internal
SaneOptionUnit saneOptionUnitFromNative(SANE_Unit unit) {
  return switch (unit) {
    SANE_Unit.UNIT_NONE => SaneOptionUnit.none,
    SANE_Unit.UNIT_PIXEL => SaneOptionUnit.pixel,
    SANE_Unit.UNIT_BIT => SaneOptionUnit.bit,
    SANE_Unit.UNIT_MM => SaneOptionUnit.mm,
    SANE_Unit.UNIT_DPI => SaneOptionUnit.dpi,
    SANE_Unit.UNIT_PERCENT => SaneOptionUnit.percent,
    SANE_Unit.UNIT_MICROSECOND => SaneOptionUnit.microsecond,
  };
}

@internal
SANE_Action nativeSaneActionFromDart(SaneAction action) {
  return switch (action) {
    SaneAction.getValue => SANE_Action.ACTION_GET_VALUE,
    SaneAction.setValue => SANE_Action.ACTION_SET_VALUE,
    SaneAction.setAuto => SANE_Action.ACTION_SET_AUTO,
  };
}

@internal
List<SaneOptionCapability> saneOptionCapabilityFromBitmap(int bitset) {
  final capabilities = <SaneOptionCapability>[];

  if (bitset & SANE_CAP_SOFT_SELECT != 0) {
    capabilities.add(SaneOptionCapability.softSelect);
  }
  if (bitset & SANE_CAP_HARD_SELECT != 0) {
    capabilities.add(SaneOptionCapability.hardSelect);
  }
  if (bitset & SANE_CAP_SOFT_DETECT != 0) {
    capabilities.add(SaneOptionCapability.softDetect);
  }
  if (bitset & SANE_CAP_EMULATED != 0) {
    capabilities.add(SaneOptionCapability.emulated);
  }
  if (bitset & SANE_CAP_AUTOMATIC != 0) {
    capabilities.add(SaneOptionCapability.automatic);
  }
  if (bitset & SANE_CAP_INACTIVE != 0) {
    capabilities.add(SaneOptionCapability.inactive);
  }
  if (bitset & SANE_CAP_ADVANCED != 0) {
    capabilities.add(SaneOptionCapability.advanced);
  }

  return capabilities;
}

@internal
SaneOptionConstraint? saneConstraintFromNative(
  UnnamedUnion1 constraint,
  SANE_Constraint_Type constraintType,
  SaneOptionValueType valueType,
) {
  switch (constraintType) {
    case SANE_Constraint_Type.CONSTRAINT_NONE:
      return null;

    case SANE_Constraint_Type.CONSTRAINT_RANGE:
      if (valueType == SaneOptionValueType.int) {
        return SaneOptionConstraintRange<int>(
          min: constraint.range.ref.min,
          max: constraint.range.ref.max,
          quant: constraint.range.ref.quant,
        );
      }
      if (valueType == SaneOptionValueType.fixed) {
        return SaneOptionConstraintRange<double>(
          min: saneFixedToDouble(constraint.range.ref.min),
          max: saneFixedToDouble(constraint.range.ref.max),
          quant: saneFixedToDouble(constraint.range.ref.quant),
        );
      }
      throw Exception('Invalid option value type');

    case SANE_Constraint_Type.CONSTRAINT_WORD_LIST:
      if (valueType == SaneOptionValueType.int) {
        final wordList = <int>[];
        final itemsCount = constraint.word_list[0] + 1;
        for (var i = 1; i < itemsCount; i++) {
          final word = constraint.word_list[i];
          wordList.add(word);
        }
        return SaneOptionConstraintWordList<int>(wordList: wordList);
      }
      if (valueType == SaneOptionValueType.fixed) {
        final wordList = <double>[];
        final itemsCount = constraint.word_list[0] + 1;
        for (var i = 1; i < itemsCount; i++) {
          final word = saneFixedToDouble(constraint.word_list[i]);
          wordList.add(word);
        }
        return SaneOptionConstraintWordList<double>(wordList: wordList);
      }
      throw Exception('Invalid option value type');

    case SANE_Constraint_Type.CONSTRAINT_STRING_LIST:
      final stringList = <String>[];
      for (var i = 0; constraint.string_list[i] != ffi.nullptr; i++) {
        final string = constraint.string_list[i].toDartString();
        stringList.add(string);
      }
      return SaneOptionConstraintStringList(stringList: stringList);
  }
}

@internal
SaneOptionDescriptor saneOptionDescriptorFromNative(
  SANE_Option_Descriptor optionDescriptor,
  int index,
) {
  return SaneOptionDescriptor(
    index: index,
    name: optionDescriptor.name.toDartString(),
    title: optionDescriptor.title.toDartString(),
    desc: optionDescriptor.desc.toDartString(),
    type: saneOptionValueTypeFromNative(optionDescriptor.type),
    unit: saneOptionUnitFromNative(optionDescriptor.unit),
    size: optionDescriptor.size,
    capabilities: saneOptionCapabilityFromBitmap(optionDescriptor.cap),
    constraint: saneConstraintFromNative(
      optionDescriptor.constraint,
      optionDescriptor.constraint_type,
      saneOptionValueTypeFromNative(optionDescriptor.type),
    ),
  );
}

@internal
List<SaneOptionInfo> saneOptionInfoFromNative(int bitset) {
  final infos = <SaneOptionInfo>[];
  if (bitset & SANE_INFO_INEXACT != 0) {
    infos.add(SaneOptionInfo.inexact);
  }
  if (bitset & SANE_INFO_RELOAD_OPTIONS != 0) {
    infos.add(SaneOptionInfo.reloadOptions);
  }
  if (bitset & SANE_INFO_RELOAD_PARAMS != 0) {
    infos.add(SaneOptionInfo.reloadParams);
  }
  return infos;
}

@internal
bool dartBoolFromSaneBool(int bool) {
  switch (bool) {
    case 0:
      return false;
    case 1:
      return true;
    default:
      throw Exception();
  }
}

@internal
extension SaneStringExtensions on SANE_String_Const {
  String toDartString() => cast<ffi.Utf8>().toDartString();
}

@internal
extension StringExtensions on String {
  SANE_String_Const toSaneString() => toNativeUtf8().cast<SANE_Char>();
}

@internal
extension BoolExtensions on bool {
  DartSANE_Word get asSaneBool => this ? SANE_TRUE : SANE_FALSE;
}

const int _saneFixedScaleFactor = 1 << SANE_FIXED_SCALE_SHIFT;

@internal
double saneFixedToDouble(int saneFixed) {
  return saneFixed / _saneFixedScaleFactor;
}

@internal
int doubleToSaneFixed(double double) {
  return (double * _saneFixedScaleFactor).toInt();
}
