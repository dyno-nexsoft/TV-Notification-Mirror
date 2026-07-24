// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationItem {
  @JsonKey(readValue: _readId)
  String get id;
  String get packageName;
  String get appName;
  String get title;
  String get text;
  @JsonKey(readValue: _readPostTime)
  int get postTime;
  String? get appIcon;
  String? get overlayPosition;
  int? get overlayDuration;

  /// Create a copy of NotificationItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NotificationItemCopyWith<NotificationItem> get copyWith =>
      _$NotificationItemCopyWithImpl<NotificationItem>(
          this as NotificationItem, _$identity);

  /// Serializes this NotificationItem to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NotificationItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.packageName, packageName) ||
                other.packageName == packageName) &&
            (identical(other.appName, appName) || other.appName == appName) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.postTime, postTime) ||
                other.postTime == postTime) &&
            (identical(other.appIcon, appIcon) || other.appIcon == appIcon) &&
            (identical(other.overlayPosition, overlayPosition) ||
                other.overlayPosition == overlayPosition) &&
            (identical(other.overlayDuration, overlayDuration) ||
                other.overlayDuration == overlayDuration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, packageName, appName, title,
      text, postTime, appIcon, overlayPosition, overlayDuration);

  @override
  String toString() {
    return 'NotificationItem(id: $id, packageName: $packageName, appName: $appName, title: $title, text: $text, postTime: $postTime, appIcon: $appIcon, overlayPosition: $overlayPosition, overlayDuration: $overlayDuration)';
  }
}

/// @nodoc
abstract mixin class $NotificationItemCopyWith<$Res> {
  factory $NotificationItemCopyWith(
          NotificationItem value, $Res Function(NotificationItem) _then) =
      _$NotificationItemCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(readValue: _readId) String id,
      String packageName,
      String appName,
      String title,
      String text,
      @JsonKey(readValue: _readPostTime) int postTime,
      String? appIcon,
      String? overlayPosition,
      int? overlayDuration});
}

/// @nodoc
class _$NotificationItemCopyWithImpl<$Res>
    implements $NotificationItemCopyWith<$Res> {
  _$NotificationItemCopyWithImpl(this._self, this._then);

  final NotificationItem _self;
  final $Res Function(NotificationItem) _then;

  /// Create a copy of NotificationItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? packageName = null,
    Object? appName = null,
    Object? title = null,
    Object? text = null,
    Object? postTime = null,
    Object? appIcon = freezed,
    Object? overlayPosition = freezed,
    Object? overlayDuration = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      packageName: null == packageName
          ? _self.packageName
          : packageName // ignore: cast_nullable_to_non_nullable
              as String,
      appName: null == appName
          ? _self.appName
          : appName // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      postTime: null == postTime
          ? _self.postTime
          : postTime // ignore: cast_nullable_to_non_nullable
              as int,
      appIcon: freezed == appIcon
          ? _self.appIcon
          : appIcon // ignore: cast_nullable_to_non_nullable
              as String?,
      overlayPosition: freezed == overlayPosition
          ? _self.overlayPosition
          : overlayPosition // ignore: cast_nullable_to_non_nullable
              as String?,
      overlayDuration: freezed == overlayDuration
          ? _self.overlayDuration
          : overlayDuration // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [NotificationItem].
extension NotificationItemPatterns on NotificationItem {
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
    TResult Function(_NotificationItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NotificationItem() when $default != null:
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
    TResult Function(_NotificationItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationItem():
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
    TResult? Function(_NotificationItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationItem() when $default != null:
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
            @JsonKey(readValue: _readId) String id,
            String packageName,
            String appName,
            String title,
            String text,
            @JsonKey(readValue: _readPostTime) int postTime,
            String? appIcon,
            String? overlayPosition,
            int? overlayDuration)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NotificationItem() when $default != null:
        return $default(
            _that.id,
            _that.packageName,
            _that.appName,
            _that.title,
            _that.text,
            _that.postTime,
            _that.appIcon,
            _that.overlayPosition,
            _that.overlayDuration);
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
            @JsonKey(readValue: _readId) String id,
            String packageName,
            String appName,
            String title,
            String text,
            @JsonKey(readValue: _readPostTime) int postTime,
            String? appIcon,
            String? overlayPosition,
            int? overlayDuration)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationItem():
        return $default(
            _that.id,
            _that.packageName,
            _that.appName,
            _that.title,
            _that.text,
            _that.postTime,
            _that.appIcon,
            _that.overlayPosition,
            _that.overlayDuration);
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
            @JsonKey(readValue: _readId) String id,
            String packageName,
            String appName,
            String title,
            String text,
            @JsonKey(readValue: _readPostTime) int postTime,
            String? appIcon,
            String? overlayPosition,
            int? overlayDuration)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationItem() when $default != null:
        return $default(
            _that.id,
            _that.packageName,
            _that.appName,
            _that.title,
            _that.text,
            _that.postTime,
            _that.appIcon,
            _that.overlayPosition,
            _that.overlayDuration);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _NotificationItem implements NotificationItem {
  const _NotificationItem(
      {@JsonKey(readValue: _readId) required this.id,
      this.packageName = 'unknown',
      this.appName = 'Notification',
      this.title = 'Notification',
      this.text = '',
      @JsonKey(readValue: _readPostTime) required this.postTime,
      this.appIcon,
      this.overlayPosition,
      this.overlayDuration});
  factory _NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);

  @override
  @JsonKey(readValue: _readId)
  final String id;
  @override
  @JsonKey()
  final String packageName;
  @override
  @JsonKey()
  final String appName;
  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey()
  final String text;
  @override
  @JsonKey(readValue: _readPostTime)
  final int postTime;
  @override
  final String? appIcon;
  @override
  final String? overlayPosition;
  @override
  final int? overlayDuration;

  /// Create a copy of NotificationItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NotificationItemCopyWith<_NotificationItem> get copyWith =>
      __$NotificationItemCopyWithImpl<_NotificationItem>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$NotificationItemToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NotificationItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.packageName, packageName) ||
                other.packageName == packageName) &&
            (identical(other.appName, appName) || other.appName == appName) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.postTime, postTime) ||
                other.postTime == postTime) &&
            (identical(other.appIcon, appIcon) || other.appIcon == appIcon) &&
            (identical(other.overlayPosition, overlayPosition) ||
                other.overlayPosition == overlayPosition) &&
            (identical(other.overlayDuration, overlayDuration) ||
                other.overlayDuration == overlayDuration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, packageName, appName, title,
      text, postTime, appIcon, overlayPosition, overlayDuration);

  @override
  String toString() {
    return 'NotificationItem(id: $id, packageName: $packageName, appName: $appName, title: $title, text: $text, postTime: $postTime, appIcon: $appIcon, overlayPosition: $overlayPosition, overlayDuration: $overlayDuration)';
  }
}

/// @nodoc
abstract mixin class _$NotificationItemCopyWith<$Res>
    implements $NotificationItemCopyWith<$Res> {
  factory _$NotificationItemCopyWith(
          _NotificationItem value, $Res Function(_NotificationItem) _then) =
      __$NotificationItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(readValue: _readId) String id,
      String packageName,
      String appName,
      String title,
      String text,
      @JsonKey(readValue: _readPostTime) int postTime,
      String? appIcon,
      String? overlayPosition,
      int? overlayDuration});
}

/// @nodoc
class __$NotificationItemCopyWithImpl<$Res>
    implements _$NotificationItemCopyWith<$Res> {
  __$NotificationItemCopyWithImpl(this._self, this._then);

  final _NotificationItem _self;
  final $Res Function(_NotificationItem) _then;

  /// Create a copy of NotificationItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? packageName = null,
    Object? appName = null,
    Object? title = null,
    Object? text = null,
    Object? postTime = null,
    Object? appIcon = freezed,
    Object? overlayPosition = freezed,
    Object? overlayDuration = freezed,
  }) {
    return _then(_NotificationItem(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      packageName: null == packageName
          ? _self.packageName
          : packageName // ignore: cast_nullable_to_non_nullable
              as String,
      appName: null == appName
          ? _self.appName
          : appName // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      postTime: null == postTime
          ? _self.postTime
          : postTime // ignore: cast_nullable_to_non_nullable
              as int,
      appIcon: freezed == appIcon
          ? _self.appIcon
          : appIcon // ignore: cast_nullable_to_non_nullable
              as String?,
      overlayPosition: freezed == overlayPosition
          ? _self.overlayPosition
          : overlayPosition // ignore: cast_nullable_to_non_nullable
              as String?,
      overlayDuration: freezed == overlayDuration
          ? _self.overlayDuration
          : overlayDuration // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
