// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

/// Represents versioning metadata for this library within applications
/// which use multiple implementations of videosdk_otel.
// See https://github.com/open-telemetry/oteps/blob/main/text/0083-component.md#instrumentationlibrary
abstract class InstrumentationLibrary {
  String get name;
  String? get version;
}
