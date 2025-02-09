// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import '../../../../api.dart' as api;
import '../../../../sdk.dart' as sdk;

class AlwaysOnSampler implements sdk.Sampler {
  @override
  String get description => 'AlwaysOnSampler';

  @override
  sdk.SamplingResult shouldSample(
      api.Context context,
      api.TraceId traceId,
      String? spanName,
      api.SpanKind? spanKind,
      List<api.Attribute> spanAttributes,
      List<api.SpanLink>? spanLinks) {
    return sdk.SamplingResult(sdk.Decision.recordAndSample, spanAttributes,
        context.spanContext?.traceState ?? sdk.TraceState.empty());
  }
}
