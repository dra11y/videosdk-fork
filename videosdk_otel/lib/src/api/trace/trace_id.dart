// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import '../../../api.dart' as api;

/// Class representing an ID for a single Trace.
/// See https://www.w3.org/TR/trace-context/#trace-id for full specification.
class TraceId {
  static const sizeBits = 32;
  static const sizeBytes = 16;

  List<int> _id;

  TraceId(this._id);

  factory TraceId.fromIdGenerator(api.IdGenerator generator) {
    return TraceId(generator.generateTraceId());
  }

  factory TraceId.fromString(String id) {
    final _id = <int>[];
    final idString = id.padLeft(TraceId.sizeBits, '0');

    for (var i = 0; i < idString.length; i += 2) {
      _id.add(int.parse('${idString[i]}${idString[i + 1]}', radix: 16));
    }
    return TraceId(_id);
  }

  TraceId.invalid() : this(List<int>.filled(sizeBytes, 0));

  /// Retrieve this TraceId as a list of byte values.
  List<int> get() => _id;

  /// Whether this ID represents a valid Trace.
  bool get isValid => !_id.every((i) => i == 0);

  /// Retrieve this SpanId as a human-readable ID.
  @override
  String toString() =>
      _id.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}
