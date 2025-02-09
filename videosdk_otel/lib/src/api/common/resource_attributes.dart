// Copyright 2023 videosdk.
// Licensed under the Apache License, Version 2.0. Please see https://github.com/videosdk/videosdk_otel-dart/blob/master/LICENSE for more information

/// Common videosdk_otel attribute keys for resource information.
///
/// Keys should follow videosdk_otel's attribute semantic conventions:
/// https://github.com/open-telemetry/videosdk_otel-specification/tree/main/specification/resource/semantic_conventions
class ResourceAttributes {
  /// Name of the deployment environment or tier.
  static const String deploymentEnvironment = 'deployment.environment';

  /// Logical name of the service.
  static const String serviceName = 'service.name';

  /// A namespace for `service.name`.
  static const String serviceNamespace = 'service.namespace';

  /// The string ID of the service instance.
  static const String serviceInstanceId = 'service.instance.id';

  /// The version string of the service API or implementation.
  static const String serviceVersion = 'service.version';
}
