// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;

import '../../../../api.dart' as api;
import '../../../../sdk.dart' as sdk;
import '../../proto/videosdk_otel/proto/collector/trace/v1/trace_service.pb.dart'
    as pb_trace_service;
import '../../proto/videosdk_otel/proto/common/v1/common.pb.dart' as pb_common;
import '../../proto/videosdk_otel/proto/resource/v1/resource.pb.dart'
    as pb_resource;
import '../../proto/videosdk_otel/proto/trace/v1/trace.pb.dart' as pb_trace;

class CollectorExporter implements api.SpanExporter {
  Uri uri;
  late final http.Client client;
  var _isShutdown = false;
  String? jwtKey;

  CollectorExporter(this.uri, {http.Client? httpClient, this.jwtKey}) {
    client = httpClient ?? http.Client();
  }

  @override
  void export(List<api.Span> spans) {
    if (_isShutdown) {
      return;
    }

    if (spans.isEmpty) {
      return;
    }

    final body = pb_trace_service.ExportTraceServiceRequest(
        resourceSpans: _spansToProtobuf(spans));

    final headers = {
      'Content-Type': 'application/x-protobuf',
      if (jwtKey != null) 'Authorization': jwtKey!,
    };

    client.post(uri, body: body.writeToBuffer(), headers: headers);
  }

  /// Group and construct the protobuf equivalent of the given list of [api.Span]s.
  /// Spans are grouped by a trace provider's [sdk.Resource] and a tracer's
  /// [api.InstrumentationLibrary].
  Iterable<pb_trace.ResourceSpans> _spansToProtobuf(List<api.Span> spans) {
    // use a map of maps to group spans by resource and instrumentation library
    final rsm =
        <sdk.Resource, Map<api.InstrumentationLibrary, List<pb_trace.Span>>>{};
    for (final span in spans) {
      final il = rsm[(span as sdk.Span).resource] ??
          <api.InstrumentationLibrary, List<pb_trace.Span>>{};
      il[span.instrumentationLibrary] =
          il[span.instrumentationLibrary] ?? <pb_trace.Span>[]
            ..add(_spanToProtobuf(span));
      rsm[span.resource] = il;
    }

    final rss = <pb_trace.ResourceSpans>[];
    for (final il in rsm.entries) {
      // for each distinct resource, construct the protobuf equivalent
      final attrs = <pb_common.KeyValue>[];
      for (final attr in il.key.attributes.keys) {
        attrs.add(pb_common.KeyValue(
            key: attr,
            value: _attributeValueToProtobuf(il.key.attributes.get(attr)!)));
      }
      final rs = pb_trace.ResourceSpans(
          resource: pb_resource.Resource(attributes: attrs),
          instrumentationLibrarySpans: []);
      // for each distinct instrumentation library, construct the protobuf equivalent
      for (final ils in il.value.entries) {
        rs.instrumentationLibrarySpans.add(pb_trace.InstrumentationLibrarySpans(
            spans: ils.value,
            instrumentationLibrary: pb_common.InstrumentationLibrary(
                name: ils.key.name, version: ils.key.version!)));
      }
      rss.add(rs);
    }
    return rss;
  }

  Iterable<pb_trace.Span_Link> _spanLinksToProtobuf(List<api.SpanLink> links) {
    final pbLinks = <pb_trace.Span_Link>[];
    for (final link in links) {
      final attrs = <pb_common.KeyValue>[];
      for (final attr in link.attributes) {
        attrs.add(pb_common.KeyValue(
            key: attr.key, value: _attributeValueToProtobuf(attr.value)));
      }
      pbLinks.add(pb_trace.Span_Link(
          traceId: link.context.traceId.get(),
          spanId: link.context.spanId.get(),
          traceState: link.context.traceState.toString(),
          attributes: attrs));
    }
    return pbLinks;
  }

  pb_trace.Span _spanToProtobuf(sdk.Span span) {
    pb_trace.Status_StatusCode statusCode;
    switch (span.status.code) {
      case api.StatusCode.unset:
        statusCode = pb_trace.Status_StatusCode.STATUS_CODE_UNSET;
        break;
      case api.StatusCode.error:
        statusCode = pb_trace.Status_StatusCode.STATUS_CODE_ERROR;
        break;
      case api.StatusCode.ok:
        statusCode = pb_trace.Status_StatusCode.STATUS_CODE_OK;
        break;
    }

    pb_trace.Span_SpanKind spanKind;
    switch (span.kind) {
      case api.SpanKind.client:
        spanKind = pb_trace.Span_SpanKind.SPAN_KIND_CLIENT;
        break;
      case api.SpanKind.consumer:
        spanKind = pb_trace.Span_SpanKind.SPAN_KIND_CONSUMER;
        break;
      case api.SpanKind.internal:
        spanKind = pb_trace.Span_SpanKind.SPAN_KIND_INTERNAL;
        break;
      case api.SpanKind.producer:
        spanKind = pb_trace.Span_SpanKind.SPAN_KIND_PRODUCER;
        break;
      case api.SpanKind.server:
        spanKind = pb_trace.Span_SpanKind.SPAN_KIND_SERVER;
        break;
      default:
        spanKind = pb_trace.Span_SpanKind.SPAN_KIND_UNSPECIFIED;
    }

    return pb_trace.Span(
        traceId: span.spanContext.traceId.get(),
        spanId: span.spanContext.spanId.get(),
        parentSpanId: span.parentSpanId?.get(),
        name: span.name,
        startTimeUnixNano: span.startTime,
        endTimeUnixNano: span.endTime!,
        attributes: span.attributes.keys.map((key) => pb_common.KeyValue(
            key: key,
            value: _attributeValueToProtobuf(span.attributes.get(key)!))),
        status:
            pb_trace.Status(code: statusCode, message: span.status.description),
        kind: spanKind,
        links: _spanLinksToProtobuf(span.links));
  }

  pb_common.AnyValue _attributeValueToProtobuf(Object value) {
    switch (value.runtimeType) {
      case String:
        return pb_common.AnyValue(stringValue: value as String);
      case bool:
        return pb_common.AnyValue(boolValue: value as bool);
      case double:
        return pb_common.AnyValue(doubleValue: value as double);
      case int:
        return pb_common.AnyValue(intValue: value as Int64);
      case List:
        final list = value as List;
        if (list.isNotEmpty) {
          switch (list[0].runtimeType) {
            case String:
              final values = [] as List<pb_common.AnyValue>;
              for (final str in list) {
                values.add(pb_common.AnyValue(stringValue: str));
              }
              return pb_common.AnyValue(
                  arrayValue: pb_common.ArrayValue(values: values));
            case bool:
              final values = [] as List<pb_common.AnyValue>;
              for (final b in list) {
                values.add(pb_common.AnyValue(boolValue: b));
              }
              return pb_common.AnyValue(
                  arrayValue: pb_common.ArrayValue(values: values));
            case double:
              final values = [] as List<pb_common.AnyValue>;
              for (final d in list) {
                values.add(pb_common.AnyValue(doubleValue: d));
              }
              return pb_common.AnyValue(
                  arrayValue: pb_common.ArrayValue(values: values));
            case int:
              final values = [] as List<pb_common.AnyValue>;
              for (final i in list) {
                values.add(pb_common.AnyValue(intValue: i));
              }
              return pb_common.AnyValue(
                  arrayValue: pb_common.ArrayValue(values: values));
          }
        }
    }
    return pb_common.AnyValue();
  }

  @override
  void forceFlush() {
    return;
  }

  @override
  void shutdown() {
    _isShutdown = true;
    client.close();
  }
}
