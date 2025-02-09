// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

/// A representation of a single piece of metadata attached to trace span.
class Attribute {
  final String key;
  final Object value;

  /// Create an Attribute from a String value.
  Attribute.fromString(this.key, String this.value) {
    _assertKey(key);
  }

  /// Create an Attribute from a boolean value.
  // ignore: avoid_positional_boolean_parameters
  Attribute.fromBoolean(this.key, bool this.value) {
    _assertKey(key);
  }

  /// Create an Attribute from a double-precision floating-point value.
  Attribute.fromDouble(this.key, double this.value) {
    _assertKey(key);
  }

  /// Create an Attribute from an integer value.
  Attribute.fromInt(this.key, int this.value) {
    _assertKey(key);
  }

  /// Create an Attribute from a list of String values.
  Attribute.fromStringList(this.key, List<String> this.value) {
    _assertKey(key);
  }

  /// Create an Attribute from a list of boolean values.
  Attribute.fromBooleanList(this.key, List<bool> this.value) {
    _assertKey(key);
  }

  /// Create an Attribute from a list of double-precision floating-point values.
  Attribute.fromDoubleList(this.key, List<double> this.value) {
    _assertKey(key);
  }

  /// Create an Attribute from a list of integer values.
  Attribute.fromIntList(this.key, List<int> this.value) {
    _assertKey(key);
  }

  void _assertKey(String key) {
    assert(key.isNotEmpty, '''Attribute key can't be empty.''');
  }
}
