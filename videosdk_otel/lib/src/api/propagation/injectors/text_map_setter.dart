// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import '../../../../api.dart' as api;

/// Class that allows a [api.TextMapPropagator] to set propagated fields into a carrier.
abstract class TextMapSetter<C> {
  /// Sets [value] for [key] on [carrier].
  void set(C carrier, String key, String value);
}
