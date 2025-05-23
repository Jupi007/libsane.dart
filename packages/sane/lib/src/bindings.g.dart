// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

class LibSane {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  LibSane(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  LibSane.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  SANE_Status sane_init(
    ffi.Pointer<SANE_Int> version_code,
    SANE_Auth_Callback authorize,
  ) {
    return SANE_Status.fromValue(_sane_init(
      version_code,
      authorize,
    ));
  }

  late final _sane_initPtr = _lookup<
      ffi.NativeFunction<
          ffi.UnsignedInt Function(
              ffi.Pointer<SANE_Int>, SANE_Auth_Callback)>>('sane_init');
  late final _sane_init = _sane_initPtr
      .asFunction<int Function(ffi.Pointer<SANE_Int>, SANE_Auth_Callback)>();

  void sane_exit() {
    return _sane_exit();
  }

  late final _sane_exitPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('sane_exit');
  late final _sane_exit = _sane_exitPtr.asFunction<void Function()>();

  SANE_Status sane_get_devices(
    ffi.Pointer<ffi.Pointer<ffi.Pointer<SANE_Device>>> device_list,
    DartSANE_Word local_only,
  ) {
    return SANE_Status.fromValue(_sane_get_devices(
      device_list,
      local_only,
    ));
  }

  late final _sane_get_devicesPtr = _lookup<
      ffi.NativeFunction<
          ffi.UnsignedInt Function(
              ffi.Pointer<ffi.Pointer<ffi.Pointer<SANE_Device>>>,
              SANE_Bool)>>('sane_get_devices');
  late final _sane_get_devices = _sane_get_devicesPtr.asFunction<
      int Function(ffi.Pointer<ffi.Pointer<ffi.Pointer<SANE_Device>>>, int)>();

  SANE_Status sane_open(
    SANE_String_Const devicename,
    ffi.Pointer<SANE_Handle> handle,
  ) {
    return SANE_Status.fromValue(_sane_open(
      devicename,
      handle,
    ));
  }

  late final _sane_openPtr = _lookup<
      ffi.NativeFunction<
          ffi.UnsignedInt Function(
              SANE_String_Const, ffi.Pointer<SANE_Handle>)>>('sane_open');
  late final _sane_open = _sane_openPtr
      .asFunction<int Function(SANE_String_Const, ffi.Pointer<SANE_Handle>)>();

  void sane_close(
    SANE_Handle handle,
  ) {
    return _sane_close(
      handle,
    );
  }

  late final _sane_closePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(SANE_Handle)>>('sane_close');
  late final _sane_close =
      _sane_closePtr.asFunction<void Function(SANE_Handle)>();

  ffi.Pointer<SANE_Option_Descriptor> sane_get_option_descriptor(
    SANE_Handle handle,
    int option,
  ) {
    return _sane_get_option_descriptor(
      handle,
      option,
    );
  }

  late final _sane_get_option_descriptorPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<SANE_Option_Descriptor> Function(
              SANE_Handle, SANE_Int)>>('sane_get_option_descriptor');
  late final _sane_get_option_descriptor =
      _sane_get_option_descriptorPtr.asFunction<
          ffi.Pointer<SANE_Option_Descriptor> Function(SANE_Handle, int)>();

  SANE_Status sane_control_option(
    SANE_Handle handle,
    DartSANE_Word option,
    SANE_Action action,
    ffi.Pointer<ffi.Void> value,
    ffi.Pointer<SANE_Int> info,
  ) {
    return SANE_Status.fromValue(_sane_control_option(
      handle,
      option,
      action.value,
      value,
      info,
    ));
  }

  late final _sane_control_optionPtr = _lookup<
      ffi.NativeFunction<
          ffi.UnsignedInt Function(
              SANE_Handle,
              SANE_Int,
              ffi.UnsignedInt,
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<SANE_Int>)>>('sane_control_option');
  late final _sane_control_option = _sane_control_optionPtr.asFunction<
      int Function(SANE_Handle, int, int, ffi.Pointer<ffi.Void>,
          ffi.Pointer<SANE_Int>)>();

  SANE_Status sane_get_parameters(
    SANE_Handle handle,
    ffi.Pointer<SANE_Parameters> params,
  ) {
    return SANE_Status.fromValue(_sane_get_parameters(
      handle,
      params,
    ));
  }

  late final _sane_get_parametersPtr = _lookup<
      ffi.NativeFunction<
          ffi.UnsignedInt Function(SANE_Handle,
              ffi.Pointer<SANE_Parameters>)>>('sane_get_parameters');
  late final _sane_get_parameters = _sane_get_parametersPtr
      .asFunction<int Function(SANE_Handle, ffi.Pointer<SANE_Parameters>)>();

  SANE_Status sane_start(
    SANE_Handle handle,
  ) {
    return SANE_Status.fromValue(_sane_start(
      handle,
    ));
  }

  late final _sane_startPtr =
      _lookup<ffi.NativeFunction<ffi.UnsignedInt Function(SANE_Handle)>>(
          'sane_start');
  late final _sane_start =
      _sane_startPtr.asFunction<int Function(SANE_Handle)>();

  SANE_Status sane_read(
    SANE_Handle handle,
    ffi.Pointer<SANE_Byte> data,
    DartSANE_Word max_length,
    ffi.Pointer<SANE_Int> length,
  ) {
    return SANE_Status.fromValue(_sane_read(
      handle,
      data,
      max_length,
      length,
    ));
  }

  late final _sane_readPtr = _lookup<
      ffi.NativeFunction<
          ffi.UnsignedInt Function(SANE_Handle, ffi.Pointer<SANE_Byte>,
              SANE_Int, ffi.Pointer<SANE_Int>)>>('sane_read');
  late final _sane_read = _sane_readPtr.asFunction<
      int Function(
          SANE_Handle, ffi.Pointer<SANE_Byte>, int, ffi.Pointer<SANE_Int>)>();

  void sane_cancel(
    SANE_Handle handle,
  ) {
    return _sane_cancel(
      handle,
    );
  }

  late final _sane_cancelPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(SANE_Handle)>>(
          'sane_cancel');
  late final _sane_cancel =
      _sane_cancelPtr.asFunction<void Function(SANE_Handle)>();

  SANE_Status sane_set_io_mode(
    SANE_Handle handle,
    DartSANE_Word non_blocking,
  ) {
    return SANE_Status.fromValue(_sane_set_io_mode(
      handle,
      non_blocking,
    ));
  }

  late final _sane_set_io_modePtr = _lookup<
          ffi.NativeFunction<ffi.UnsignedInt Function(SANE_Handle, SANE_Bool)>>(
      'sane_set_io_mode');
  late final _sane_set_io_mode =
      _sane_set_io_modePtr.asFunction<int Function(SANE_Handle, int)>();

  SANE_Status sane_get_select_fd(
    SANE_Handle handle,
    ffi.Pointer<SANE_Int> fd,
  ) {
    return SANE_Status.fromValue(_sane_get_select_fd(
      handle,
      fd,
    ));
  }

  late final _sane_get_select_fdPtr = _lookup<
      ffi.NativeFunction<
          ffi.UnsignedInt Function(
              SANE_Handle, ffi.Pointer<SANE_Int>)>>('sane_get_select_fd');
  late final _sane_get_select_fd = _sane_get_select_fdPtr
      .asFunction<int Function(SANE_Handle, ffi.Pointer<SANE_Int>)>();

  SANE_String_Const sane_strstatus(
    SANE_Status status,
  ) {
    return _sane_strstatus(
      status.value,
    );
  }

  late final _sane_strstatusPtr =
      _lookup<ffi.NativeFunction<SANE_String_Const Function(ffi.UnsignedInt)>>(
          'sane_strstatus');
  late final _sane_strstatus =
      _sane_strstatusPtr.asFunction<SANE_String_Const Function(int)>();

  late final addresses = _SymbolAddresses(this);
}

class _SymbolAddresses {
  final LibSane _library;

  _SymbolAddresses(this._library);

  ffi.Pointer<ffi.NativeFunction<ffi.Void Function(SANE_Handle)>>
      get sane_close => _library._sane_closePtr;
}

enum SANE_Status {
  STATUS_GOOD(0),
  STATUS_UNSUPPORTED(1),
  STATUS_CANCELLED(2),
  STATUS_DEVICE_BUSY(3),
  STATUS_INVAL(4),
  STATUS_EOF(5),
  STATUS_JAMMED(6),
  STATUS_NO_DOCS(7),
  STATUS_COVER_OPEN(8),
  STATUS_IO_ERROR(9),
  STATUS_NO_MEM(10),
  STATUS_ACCESS_DENIED(11);

  final int value;
  const SANE_Status(this.value);

  static SANE_Status fromValue(int value) => switch (value) {
        0 => STATUS_GOOD,
        1 => STATUS_UNSUPPORTED,
        2 => STATUS_CANCELLED,
        3 => STATUS_DEVICE_BUSY,
        4 => STATUS_INVAL,
        5 => STATUS_EOF,
        6 => STATUS_JAMMED,
        7 => STATUS_NO_DOCS,
        8 => STATUS_COVER_OPEN,
        9 => STATUS_IO_ERROR,
        10 => STATUS_NO_MEM,
        11 => STATUS_ACCESS_DENIED,
        _ => throw ArgumentError("Unknown value for SANE_Status: $value"),
      };
}

enum SANE_Value_Type {
  TYPE_BOOL(0),
  TYPE_INT(1),
  TYPE_FIXED(2),
  TYPE_STRING(3),
  TYPE_BUTTON(4),
  TYPE_GROUP(5);

  final int value;
  const SANE_Value_Type(this.value);

  static SANE_Value_Type fromValue(int value) => switch (value) {
        0 => TYPE_BOOL,
        1 => TYPE_INT,
        2 => TYPE_FIXED,
        3 => TYPE_STRING,
        4 => TYPE_BUTTON,
        5 => TYPE_GROUP,
        _ => throw ArgumentError("Unknown value for SANE_Value_Type: $value"),
      };
}

enum SANE_Unit {
  UNIT_NONE(0),
  UNIT_PIXEL(1),
  UNIT_BIT(2),
  UNIT_MM(3),
  UNIT_DPI(4),
  UNIT_PERCENT(5),
  UNIT_MICROSECOND(6);

  final int value;
  const SANE_Unit(this.value);

  static SANE_Unit fromValue(int value) => switch (value) {
        0 => UNIT_NONE,
        1 => UNIT_PIXEL,
        2 => UNIT_BIT,
        3 => UNIT_MM,
        4 => UNIT_DPI,
        5 => UNIT_PERCENT,
        6 => UNIT_MICROSECOND,
        _ => throw ArgumentError("Unknown value for SANE_Unit: $value"),
      };
}

final class SANE_Device extends ffi.Struct {
  external SANE_String_Const name;

  external SANE_String_Const vendor;

  external SANE_String_Const model;

  external SANE_String_Const type;
}

typedef SANE_String_Const = ffi.Pointer<SANE_Char>;
typedef SANE_Char = ffi.Char;
typedef DartSANE_Char = int;

enum SANE_Constraint_Type {
  CONSTRAINT_NONE(0),
  CONSTRAINT_RANGE(1),
  CONSTRAINT_WORD_LIST(2),
  CONSTRAINT_STRING_LIST(3);

  final int value;
  const SANE_Constraint_Type(this.value);

  static SANE_Constraint_Type fromValue(int value) => switch (value) {
        0 => CONSTRAINT_NONE,
        1 => CONSTRAINT_RANGE,
        2 => CONSTRAINT_WORD_LIST,
        3 => CONSTRAINT_STRING_LIST,
        _ =>
          throw ArgumentError("Unknown value for SANE_Constraint_Type: $value"),
      };
}

final class SANE_Range extends ffi.Struct {
  @SANE_Word()
  external int min;

  @SANE_Word()
  external int max;

  @SANE_Word()
  external int quant;
}

typedef SANE_Word = ffi.Int;
typedef DartSANE_Word = int;

final class SANE_Option_Descriptor extends ffi.Struct {
  external SANE_String_Const name;

  external SANE_String_Const title;

  external SANE_String_Const desc;

  @ffi.UnsignedInt()
  external int typeAsInt;

  SANE_Value_Type get type => SANE_Value_Type.fromValue(typeAsInt);

  @ffi.UnsignedInt()
  external int unitAsInt;

  SANE_Unit get unit => SANE_Unit.fromValue(unitAsInt);

  @SANE_Int()
  external int size;

  @SANE_Int()
  external int cap;

  @ffi.UnsignedInt()
  external int constraint_typeAsInt;

  SANE_Constraint_Type get constraint_type =>
      SANE_Constraint_Type.fromValue(constraint_typeAsInt);

  external UnnamedUnion1 constraint;
}

typedef SANE_Int = SANE_Word;

final class UnnamedUnion1 extends ffi.Union {
  external ffi.Pointer<SANE_String_Const> string_list;

  external ffi.Pointer<SANE_Word> word_list;

  external ffi.Pointer<SANE_Range> range;
}

enum SANE_Action {
  ACTION_GET_VALUE(0),
  ACTION_SET_VALUE(1),
  ACTION_SET_AUTO(2);

  final int value;
  const SANE_Action(this.value);

  static SANE_Action fromValue(int value) => switch (value) {
        0 => ACTION_GET_VALUE,
        1 => ACTION_SET_VALUE,
        2 => ACTION_SET_AUTO,
        _ => throw ArgumentError("Unknown value for SANE_Action: $value"),
      };
}

enum SANE_Frame {
  FRAME_GRAY(0),
  FRAME_RGB(1),
  FRAME_RED(2),
  FRAME_GREEN(3),
  FRAME_BLUE(4);

  final int value;
  const SANE_Frame(this.value);

  static SANE_Frame fromValue(int value) => switch (value) {
        0 => FRAME_GRAY,
        1 => FRAME_RGB,
        2 => FRAME_RED,
        3 => FRAME_GREEN,
        4 => FRAME_BLUE,
        _ => throw ArgumentError("Unknown value for SANE_Frame: $value"),
      };
}

final class SANE_Parameters extends ffi.Struct {
  @ffi.UnsignedInt()
  external int formatAsInt;

  SANE_Frame get format => SANE_Frame.fromValue(formatAsInt);

  @SANE_Bool()
  external int last_frame;

  @SANE_Int()
  external int bytes_per_line;

  @SANE_Int()
  external int pixels_per_line;

  @SANE_Int()
  external int lines;

  @SANE_Int()
  external int depth;
}

typedef SANE_Bool = SANE_Word;

final class SANE_Auth_Data extends ffi.Opaque {}

typedef SANE_Auth_Callback
    = ffi.Pointer<ffi.NativeFunction<SANE_Auth_CallbackFunction>>;
typedef SANE_Auth_CallbackFunction = ffi.Void Function(
    SANE_String_Const resource,
    ffi.Pointer<SANE_Char> username,
    ffi.Pointer<SANE_Char> password);
typedef DartSANE_Auth_CallbackFunction = void Function(
    SANE_String_Const resource,
    ffi.Pointer<SANE_Char> username,
    ffi.Pointer<SANE_Char> password);
typedef SANE_Handle = ffi.Pointer<ffi.Void>;
typedef SANE_Byte = ffi.UnsignedChar;
typedef DartSANE_Byte = int;

const int SANE_CURRENT_MAJOR = 1;

const int SANE_CURRENT_MINOR = 0;

const int SANE_FALSE = 0;

const int SANE_TRUE = 1;

const int SANE_FIXED_SCALE_SHIFT = 16;

const int SANE_CAP_SOFT_SELECT = 1;

const int SANE_CAP_HARD_SELECT = 2;

const int SANE_CAP_SOFT_DETECT = 4;

const int SANE_CAP_EMULATED = 8;

const int SANE_CAP_AUTOMATIC = 16;

const int SANE_CAP_INACTIVE = 32;

const int SANE_CAP_ADVANCED = 64;

const int SANE_INFO_INEXACT = 1;

const int SANE_INFO_RELOAD_OPTIONS = 2;

const int SANE_INFO_RELOAD_PARAMS = 4;

const int SANE_MAX_USERNAME_LEN = 128;

const int SANE_MAX_PASSWORD_LEN = 128;
