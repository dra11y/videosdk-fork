// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:videosdk_otel/api.dart';

abstract class Counter<T extends num> {
  /// Records a value with a set of attributes.
  ///
  /// [value] The increment amount. MUST be non-negative.
  /// [attributes] A set of attributes to associate with the value.
  /// [context] The explicit context to associate with this measurement.
  void add(T value, {List<Attribute>? attributes, Context? context});
}
