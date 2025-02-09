// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:videosdk_otel/src/api/metrics/noop/noop_counter.dart';
import 'package:videosdk_otel/src/experimental_api.dart';

/// A no-op instance of a [Meter]
class NoopMeter implements Meter {
  @override
  Counter<T> createCounter<T extends num>(String name,
      {String? description, String? unit}) {
    return NoopCounter<T>();
  }
}
