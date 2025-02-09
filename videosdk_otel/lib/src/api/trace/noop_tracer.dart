// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:fixnum/fixnum.dart';

import '../../../api.dart' as api;
import '../../../sdk.dart' as sdk;

/// A [api.Tracer] class which yields [api.NonRecordingSpan]s and no-ops for most
/// operations.
class NoopTracer implements api.Tracer {
  @override
  api.Span startSpan(String name,
      {api.Context? context,
      api.SpanKind? kind,
      List<api.Attribute>? attributes,
      List<api.SpanLink>? links,
      Int64? startTime}) {
    final parentContext = (context ?? api.Context.current).spanContext;

    return api.NonRecordingSpan(parentContext ?? sdk.SpanContext.invalid());
  }
}
