// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:videosdk_otel/api.dart' as api;
import 'package:videosdk_otel/src/experimental_api.dart' as api;
import 'package:videosdk_otel/src/experimental_sdk.dart' as sdk;
import 'package:logging/logging.dart';
import 'package:videosdk_otel/src/sdk/common/instrumentation_scope.dart';
import 'package:videosdk_otel/src/sdk/metrics/state/meter_provider_shared_state.dart';

const invalidMeterNameMessage = 'Invalid Meter Name';

class MeterProvider implements api.MeterProvider {
  final _logger = Logger('videosdk_otel.sdk.metrics.meterprovider');
  final _shutdown = false;
  final MeterProviderSharedState _sharedState;

  sdk.Resource? get resource => _sharedState.resource;

  MeterProvider({sdk.Resource? resource})
      : _sharedState = MeterProviderSharedState(resource);

  @override
  api.Meter get(String name,
      {String version = '',
      String schemaUrl = '',
      List<api.Attribute> attributes = const []}) {
    if (name == '') {
      name = '';
      _logger.warning(invalidMeterNameMessage, '', StackTrace.current);
    }

    if (_shutdown) {
      _logger.warning('A shutdown MeterProvider cannot provide a Meter', '',
          StackTrace.current);
      return api.NoopMeter();
    }

    return _sharedState
        .getMeterSharedState(
            InstrumentationScope(name, version, schemaUrl, attributes))
        .meter;
  }
}
