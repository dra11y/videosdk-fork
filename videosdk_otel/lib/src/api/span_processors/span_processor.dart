// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import '../../../api.dart' as api;

abstract class SpanProcessor {
  void onStart(api.Span span, api.Context parentContext);

  void onEnd(api.Span span);

  void shutdown();

  void forceFlush();
}
