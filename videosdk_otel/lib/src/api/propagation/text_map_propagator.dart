// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import '../../../api.dart' as api;

/// A class responsible for performing the injection and extraction of a
/// cross-cutting concern value as string key/values pairs into carriers that
/// travel across process boundaries.
///
/// See https://github.com/open-telemetry/videosdk_otel-specification/blob/main/specification/context/api-propagators.md#textmap-propagator
/// for full specification.
abstract class TextMapPropagator<C> {
  void inject(api.Context context, C carrier, api.TextMapSetter<C> setter);

  api.Context extract(
      api.Context context, C carrier, api.TextMapGetter<C> getter);
}
