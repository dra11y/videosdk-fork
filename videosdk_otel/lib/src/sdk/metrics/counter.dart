// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:videosdk_otel/api.dart' as api;
import 'package:videosdk_otel/src/experimental_api.dart' as api;

class Counter<T extends num> implements api.Counter<T> {
  @override
  void add(T value, {List<api.Attribute>? attributes, api.Context? context}) {
    // ignore: todo
    // TODO: implement add https://github.com/videosdk/videosdk_otel-dart/issues/75
  }
}
