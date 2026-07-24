// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mirror_device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MirrorDevice {
  @JsonKey(name: 'deviceName', readValue: _readDeviceName)
  String get name;
  String get ip;
  int get port;
  String? get token;

  /// Create a copy of MirrorDevice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MirrorDeviceCopyWith<MirrorDevice> get copyWith =>
      _$MirrorDeviceCopyWithImpl<MirrorDevice>(
          this as MirrorDevice, _$identity);

  /// Serializes this MirrorDevice to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MirrorDevice &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ip, ip) || other.ip == ip) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.token, token) || other.token == token));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, ip, port, token);

  @override
  String toString() {
    return 'MirrorDevice(name: $name, ip: $ip, port: $port, token: $token)';
  }
}

/// @nodoc
abstract mixin class $MirrorDeviceCopyWith<$Res> {
  factory $MirrorDeviceCopyWith(
          MirrorDevice value, $Res Function(MirrorDevice) _then) =
      _$MirrorDeviceCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'deviceName', readValue: _readDeviceName) String name,
      String ip,
      int port,
      String? token});
}

/// @nodoc
class _$MirrorDeviceCopyWithImpl<$Res> implements $MirrorDeviceCopyWith<$Res> {
  _$MirrorDeviceCopyWithImpl(this._self, this._then);

  final MirrorDevice _self;
  final $Res Function(MirrorDevice) _then;

  /// Create a copy of MirrorDevice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? ip = null,
    Object? port = null,
    Object? token = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      ip: null == ip
          ? _self.ip
          : ip // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _self.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      token: freezed == token
          ? _self.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [MirrorDevice].
extension MirrorDevicePatterns on MirrorDevice {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_MirrorDevice value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MirrorDevice() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_MirrorDevice value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MirrorDevice():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_MirrorDevice value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MirrorDevice() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            @JsonKey(name: 'deviceName', readValue: _readDeviceName)
            String name,
            String ip,
            int port,
            String? token)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MirrorDevice() when $default != null:
        return $default(_that.name, _that.ip, _that.port, _that.token);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            @JsonKey(name: 'deviceName', readValue: _readDeviceName)
            String name,
            String ip,
            int port,
            String? token)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MirrorDevice():
        return $default(_that.name, _that.ip, _that.port, _that.token);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            @JsonKey(name: 'deviceName', readValue: _readDeviceName)
            String name,
            String ip,
            int port,
            String? token)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MirrorDevice() when $default != null:
        return $default(_that.name, _that.ip, _that.port, _that.token);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MirrorDevice implements MirrorDevice {
  const _MirrorDevice(
      {@JsonKey(name: 'deviceName', readValue: _readDeviceName)
      required this.name,
      this.ip = '',
      this.port = 8080,
      this.token});
  factory _MirrorDevice.fromJson(Map<String, dynamic> json) =>
      _$MirrorDeviceFromJson(json);

  @override
  @JsonKey(name: 'deviceName', readValue: _readDeviceName)
  final String name;
  @override
  @JsonKey()
  final String ip;
  @override
  @JsonKey()
  final int port;
  @override
  final String? token;

  /// Create a copy of MirrorDevice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MirrorDeviceCopyWith<_MirrorDevice> get copyWith =>
      __$MirrorDeviceCopyWithImpl<_MirrorDevice>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MirrorDeviceToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MirrorDevice &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ip, ip) || other.ip == ip) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.token, token) || other.token == token));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, ip, port, token);

  @override
  String toString() {
    return 'MirrorDevice(name: $name, ip: $ip, port: $port, token: $token)';
  }
}

/// @nodoc
abstract mixin class _$MirrorDeviceCopyWith<$Res>
    implements $MirrorDeviceCopyWith<$Res> {
  factory _$MirrorDeviceCopyWith(
          _MirrorDevice value, $Res Function(_MirrorDevice) _then) =
      __$MirrorDeviceCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'deviceName', readValue: _readDeviceName) String name,
      String ip,
      int port,
      String? token});
}

/// @nodoc
class __$MirrorDeviceCopyWithImpl<$Res>
    implements _$MirrorDeviceCopyWith<$Res> {
  __$MirrorDeviceCopyWithImpl(this._self, this._then);

  final _MirrorDevice _self;
  final $Res Function(_MirrorDevice) _then;

  /// Create a copy of MirrorDevice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? ip = null,
    Object? port = null,
    Object? token = freezed,
  }) {
    return _then(_MirrorDevice(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      ip: null == ip
          ? _self.ip
          : ip // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _self.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      token: freezed == token
          ? _self.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
