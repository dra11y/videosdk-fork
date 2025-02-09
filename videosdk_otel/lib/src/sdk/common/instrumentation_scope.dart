// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:videosdk_otel/api.dart' as api;

class InstrumentationScope {
  final String _name;
  final String _version;
  final String _schemaUrl;
  final List<api.Attribute> _attributes;

  InstrumentationScope(
      this._name, this._version, this._schemaUrl, this._attributes);

  String get name {
    return _name;
  }

  String get version {
    return _version;
  }

  String get schemaUrl {
    return _schemaUrl;
  }

  List<api.Attribute> get attributes {
    return _attributes;
  }
}
