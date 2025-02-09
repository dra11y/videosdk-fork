// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:videosdk_otel/src/sdk/common/instrumentation_scope.dart';

import 'package:videosdk_otel/src/experimental_sdk.dart' as sdk;

import 'meter_provider_shared_state.dart';

class MeterSharedState {
  // ignore: unused_field
  final MeterProviderSharedState _meterProviderSharedState;
  // ignore: unused_field
  final InstrumentationScope _instrumentationScope;
  late sdk.Meter meter;

  MeterSharedState(this._meterProviderSharedState, this._instrumentationScope) {
    meter = sdk.Meter(this);
  }
}
