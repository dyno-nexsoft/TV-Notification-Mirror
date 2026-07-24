// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_preset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppPreset {
  String get pkg;
  String get name;
  @JsonKey(includeFromJson: false, includeToJson: false)
  IconData get icon;

  /// Create a copy of AppPreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AppPresetCopyWith<AppPreset> get copyWith =>
      _$AppPresetCopyWithImpl<AppPreset>(this as AppPreset, _$identity);

  /// Serializes this AppPreset to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppPreset &&
            (identical(other.pkg, pkg) || other.pkg == pkg) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pkg, name, icon);

  @override
  String toString() {
    return 'AppPreset(pkg: $pkg, name: $name, icon: $icon)';
  }
}

/// @nodoc
abstract mixin class $AppPresetCopyWith<$Res> {
  factory $AppPresetCopyWith(AppPreset value, $Res Function(AppPreset) _then) =
      _$AppPresetCopyWithImpl;
  @useResult
  $Res call(
      {String pkg,
      String name,
      @JsonKey(includeFromJson: false, includeToJson: false) IconData icon});
}

/// @nodoc
class _$AppPresetCopyWithImpl<$Res> implements $AppPresetCopyWith<$Res> {
  _$AppPresetCopyWithImpl(this._self, this._then);

  final AppPreset _self;
  final $Res Function(AppPreset) _then;

  /// Create a copy of AppPreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pkg = null,
    Object? name = null,
    Object? icon = null,
  }) {
    return _then(_self.copyWith(
      pkg: null == pkg
          ? _self.pkg
          : pkg // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as IconData,
    ));
  }
}

/// Adds pattern-matching-related methods to [AppPreset].
extension AppPresetPatterns on AppPreset {
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
    TResult Function(_AppPreset value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AppPreset() when $default != null:
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
    TResult Function(_AppPreset value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppPreset():
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
    TResult? Function(_AppPreset value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppPreset() when $default != null:
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
            String pkg,
            String name,
            @JsonKey(includeFromJson: false, includeToJson: false)
            IconData icon)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AppPreset() when $default != null:
        return $default(_that.pkg, _that.name, _that.icon);
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
            String pkg,
            String name,
            @JsonKey(includeFromJson: false, includeToJson: false)
            IconData icon)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppPreset():
        return $default(_that.pkg, _that.name, _that.icon);
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
            String pkg,
            String name,
            @JsonKey(includeFromJson: false, includeToJson: false)
            IconData icon)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppPreset() when $default != null:
        return $default(_that.pkg, _that.name, _that.icon);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AppPreset implements AppPreset {
  const _AppPreset(
      {required this.pkg,
      required this.name,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.icon = YaruIcons.notification});
  factory _AppPreset.fromJson(Map<String, dynamic> json) =>
      _$AppPresetFromJson(json);

  @override
  final String pkg;
  @override
  final String name;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final IconData icon;

  /// Create a copy of AppPreset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AppPresetCopyWith<_AppPreset> get copyWith =>
      __$AppPresetCopyWithImpl<_AppPreset>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AppPresetToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AppPreset &&
            (identical(other.pkg, pkg) || other.pkg == pkg) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pkg, name, icon);

  @override
  String toString() {
    return 'AppPreset(pkg: $pkg, name: $name, icon: $icon)';
  }
}

/// @nodoc
abstract mixin class _$AppPresetCopyWith<$Res>
    implements $AppPresetCopyWith<$Res> {
  factory _$AppPresetCopyWith(
          _AppPreset value, $Res Function(_AppPreset) _then) =
      __$AppPresetCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String pkg,
      String name,
      @JsonKey(includeFromJson: false, includeToJson: false) IconData icon});
}

/// @nodoc
class __$AppPresetCopyWithImpl<$Res> implements _$AppPresetCopyWith<$Res> {
  __$AppPresetCopyWithImpl(this._self, this._then);

  final _AppPreset _self;
  final $Res Function(_AppPreset) _then;

  /// Create a copy of AppPreset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pkg = null,
    Object? name = null,
    Object? icon = null,
  }) {
    return _then(_AppPreset(
      pkg: null == pkg
          ? _self.pkg
          : pkg // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as IconData,
    ));
  }
}

// dart format on
