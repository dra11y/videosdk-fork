// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:fixnum/fixnum.dart';

import '../../../api.dart' as api;

/// An interface for creating [api.Span]s and propagating context in-process.
///
/// Users may choose to use manual or automatic Context propagation. Because of
/// that, this class offers APIs to facilitate both usages.
abstract class Tracer {
  /// Starts a new [api.Span] without setting it as the current span in this
  /// tracer's context.
  api.Span startSpan(String name,
      {api.Context? context,
      api.SpanKind? kind,
      List<api.Attribute> attributes = const [],
      List<api.SpanLink>? links,
      Int64? startTime});
}
