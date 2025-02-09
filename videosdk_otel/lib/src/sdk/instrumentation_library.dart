// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import '../../api.dart' as api;

// Represents the instrumentation library.
class InstrumentationLibrary implements api.InstrumentationLibrary {
  final String _name;
  final String _version;

  InstrumentationLibrary(this._name, String? version)
      : _version = version ?? '';

  @override
  String get name => _name;

  @override
  String get version => _version;
}
