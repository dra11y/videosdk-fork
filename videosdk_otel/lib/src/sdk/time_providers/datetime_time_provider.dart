// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

import 'package:fixnum/fixnum.dart';
import 'time_provider.dart';

/// DateTimeTimeProvider retrieves timestamps using DateTime.
class DateTimeTimeProvider implements TimeProvider {
  @override
  Int64 get now =>
      Int64(DateTime.now().microsecondsSinceEpoch) *
      TimeProvider.nanosecondsPerMicrosecond;
}
