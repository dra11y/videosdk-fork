// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:videosdk_otel/api.dart';
import 'package:videosdk_otel/src/experimental_api.dart';

/// A no-op instance of a [Counter]
class NoopCounter<T extends num> extends Counter<T> {
  @override
  void add(T value, {List<Attribute>? attributes, Context? context}) {}
}
