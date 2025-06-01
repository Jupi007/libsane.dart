import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:logging/logging.dart';
import 'package:sane/src/bindings.g.dart';
import 'package:sane/src/exceptions.dart';
import 'package:sane/src/structures.dart';

extension LoggerExtension on Logger {
  void redirect(LogRecord record) {
    log(
      record.level,
      record.message,
      record.error,
      record.stackTrace,
      record.zone,
    );
  }
}

extension CheckNativeSaneStatusExtension on SANE_Status {
  /// Throws [SaneException] if the status is not [SANE_Status.STATUS_GOOD].
  void check() {
    if (this != SANE_Status.STATUS_GOOD) {
      throw SaneException(this);
    }
  }
}

extension NativeSaneDeviceExtension on SANE_Device {
  /// Convert native [SANE_Device] to [SaneDevice].
  SaneDevice toSaneDevice() {
    return SaneDevice(
      name: name.toDartString(),
      vendor: vendor.toDartString(),
      model: model.toDartString(),
      type: type.toDartString(),
    );
  }
}

extension NativeSaneFrameFormatExtension on SANE_Frame {
  /// Convert native [SANE_Frame] to [SaneFrameFormat].
  SaneFrameFormat toSaneFrameFormat() {
    return switch (this) {
      SANE_Frame.FRAME_GRAY => SaneFrameFormat.gray,
      SANE_Frame.FRAME_RGB => SaneFrameFormat.rgb,
      SANE_Frame.FRAME_RED => SaneFrameFormat.red,
      SANE_Frame.FRAME_GREEN => SaneFrameFormat.green,
      SANE_Frame.FRAME_BLUE => SaneFrameFormat.blue,
    };
  }
}

extension NativeSaneParametersExtension on SANE_Parameters {
  /// Convert native [SANE_Parameters] to [SaneParameters].
  SaneParameters toSaneParameters() {
    return SaneParameters(
      format: format.toSaneFrameFormat(),
      lastFrame: last_frame.toDartBool(),
      bytesPerLine: bytes_per_line,
      pixelsPerLine: pixels_per_line,
      lines: lines,
      depth: depth,
    );
  }
}

extension NativeSaneOptionValueTypeExtension on SANE_Value_Type {
  /// Convert native [SANE_Value_Type] to [SaneOptionValueType].
  SaneOptionValueType toSaneOptionValueType() {
    return switch (this) {
      SANE_Value_Type.TYPE_BOOL => SaneOptionValueType.bool,
      SANE_Value_Type.TYPE_INT => SaneOptionValueType.int,
      SANE_Value_Type.TYPE_FIXED => SaneOptionValueType.fixed,
      SANE_Value_Type.TYPE_STRING => SaneOptionValueType.string,
      SANE_Value_Type.TYPE_BUTTON => SaneOptionValueType.button,
      SANE_Value_Type.TYPE_GROUP => SaneOptionValueType.group,
    };
  }
}

extension NativeSaneOptionUnitExtension on SANE_Unit {
  /// Convert native [SANE_Unit] to [SaneOptionUnit].
  SaneOptionUnit toSaneOptionUnit() {
    return switch (this) {
      SANE_Unit.UNIT_NONE => SaneOptionUnit.none,
      SANE_Unit.UNIT_PIXEL => SaneOptionUnit.pixel,
      SANE_Unit.UNIT_BIT => SaneOptionUnit.bit,
      SANE_Unit.UNIT_MM => SaneOptionUnit.mm,
      SANE_Unit.UNIT_DPI => SaneOptionUnit.dpi,
      SANE_Unit.UNIT_PERCENT => SaneOptionUnit.percent,
      SANE_Unit.UNIT_MICROSECOND => SaneOptionUnit.microsecond,
    };
  }
}

extension SaneActionExtension on SaneAction {
  /// Convert [SaneAction] to native [SANE_Action].
  SANE_Action toNativeSaneAction() {
    return switch (this) {
      SaneAction.getValue => SANE_Action.ACTION_GET_VALUE,
      SaneAction.setValue => SANE_Action.ACTION_SET_VALUE,
      SaneAction.setAuto => SANE_Action.ACTION_SET_AUTO,
    };
  }
}

List<SaneOptionCapability> _saneOptionCapabilityFromBitmap(int bitset) {
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

SaneOptionConstraint? _saneConstraintFromNative(
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
          min: constraint.range.ref.min.toDartDouble(),
          max: constraint.range.ref.max.toDartDouble(),
          quant: constraint.range.ref.quant.toDartDouble(),
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
          final word = constraint.word_list[i].toDartDouble();
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

extension SaneOptionDescriptorExtension on SANE_Option_Descriptor {
  /// Convert native [SANE_Option_Descriptor] to [SaneOptionDescriptor].
  SaneOptionDescriptor toSaneOptionDescriptorWithIndex(int index) {
    return SaneOptionDescriptor(
      index: index,
      name: name.toDartString(),
      title: title.toDartString(),
      desc: desc.toDartString(),
      type: type.toSaneOptionValueType(),
      unit: unit.toSaneOptionUnit(),
      size: size,
      capabilities: _saneOptionCapabilityFromBitmap(cap),
      constraint: _saneConstraintFromNative(
        constraint,
        constraint_type,
        type.toSaneOptionValueType(),
      ),
    );
  }
}

extension SaneOptionInfoBitsetExtension on int {
  /// Convert native Sane option info bitset to [SaneOptionInfo] list.
  List<SaneOptionInfo> toSaneOptionInfoList() {
    final infos = <SaneOptionInfo>[];
    if (this & SANE_INFO_INEXACT != 0) {
      infos.add(SaneOptionInfo.inexact);
    }
    if (this & SANE_INFO_RELOAD_OPTIONS != 0) {
      infos.add(SaneOptionInfo.reloadOptions);
    }
    if (this & SANE_INFO_RELOAD_PARAMS != 0) {
      infos.add(SaneOptionInfo.reloadParams);
    }
    return infos;
  }
}

extension SaneBoolExtension on int {
  /// Convert native [SANE_Bool] to dart [bool].
  bool toDartBool() {
    switch (this) {
      case 0:
        return false;
      case 1:
        return true;
      default:
        throw Exception();
    }
  }
}

extension BoolExtensions on bool {
  DartSANE_Word toSaneBool() => this ? SANE_TRUE : SANE_FALSE;
}

const int _saneFixedScaleFactor = 1 << SANE_FIXED_SCALE_SHIFT;

extension SaneFixedExtension on int {
  double toDartDouble() => this / _saneFixedScaleFactor;
}

extension DoubleExtension on double {
  int toSaneFixed() {
    return (this * _saneFixedScaleFactor).toInt();
  }
}

extension SaneStringExtension on SANE_String_Const {
  String toDartString() =>
      this == ffi.nullptr ? '' : cast<ffi.Utf8>().toDartString();
}

extension StringExtension on String {
  SANE_String_Const toSaneString() => toNativeUtf8().cast<SANE_Char>();
}

extension SaneIOModeExtension on SaneIOMode {
  DartSANE_Word toSaneBool() {
    return switch (this) {
      SaneIOMode.blocking => SANE_FALSE,
      SaneIOMode.nonBlocking => SANE_TRUE,
    };
  }
}
