enum Direction {
  inbound,
  outbound,
}

enum Property {
  audioLevel,
  availableOutgoingBitrate,
  availableIncomingBitrate,
  bytesReceived,
  bytesSent,
  candidateType,
  channels,
  clockRate,
  codecId,
  currentRoundTripTime,
  roundTripTime,
  fractionLost,
  frameHeight,
  frameWidth,
  qualityLimitationReason,
  qualityLimitationDurations,
  qualityLimitationResolutionChanges,
  id,
  jitter,
  kind,
  mediaType,
  mimeType,
  localCandidateId,
  networkType,
  relayProtocol,
  nominated,
  packetsLost,
  packetsReceived,
  packetsSent,
  protocol,
  port,
  remoteCandidateId,
  remoteSource,
  responsesReceived,
  sdpFmtpLine,
  ssrc,
  selected,
  state,
  timestamp,
  totalRoundTripTime,
  roundTripTimeMeasurements,
  trackIdentifier,
  trackId,
  type,
  decoderImplementation,
  encoderImplementation,
  framesDecoded,
  framesEncoded,
  framesPerSecond,
  totalDecodeTime,
  totalEncodeTime,
  pliCount,
  nackCount,
  concealmentEvents,
  insertedSamplesForDeceleration,
  removedSamplesForAcceleration,
  mediaSourceId,
  pauseCount,
  totalPausesDuration,
  freezeCount,
  totalFreezesDuration
}

enum Value { succeeded, audio, video }

enum InfrastructureLabel {
  ethernet,
  cellular,
  wifi,
}

enum StatType { audio, video, network, data }

enum InfrastructureValue { ethernet, cellular5g, wifi, cellular4g, cellular }

extension InfrastructureValueExtension on InfrastructureValue {
  static const Map<int, InfrastructureValue> types = {
    0: InfrastructureValue.ethernet,
    2: InfrastructureValue.cellular5g,
    3: InfrastructureValue.wifi,
    5: InfrastructureValue.cellular4g,
    10: InfrastructureValue.cellular,
  };

  static const Map<InfrastructureValue, int> values = {
    InfrastructureValue.ethernet: 0,
    InfrastructureValue.cellular5g: 2,
    InfrastructureValue.wifi: 3,
    InfrastructureValue.cellular4g: 5,
    InfrastructureValue.cellular: 10,
  };

  static InfrastructureValue fromInt(int infrastructureValue) =>
      types[infrastructureValue]!;

  int get value => values[this]!;
}

enum Type {
  candidatePair,
  codec,
  inboundRtp,
  localCandidate,
  mediaSource,
  outboundRtp,
  remoteCandidate,
  remoteInboundRtp,
  remoteOutboundRtp,
  track,
}

extension TypeExtension on Type {
  static const Map<String, Type> types = {
    'candidate-pair': Type.candidatePair,
    'codec': Type.codec,
    'inbound-rtp': Type.inboundRtp,
    'local-candidate': Type.localCandidate,
    'media-source': Type.mediaSource,
    'outbound-rtp': Type.outboundRtp,
    'remote-candidate': Type.remoteCandidate,
    'remote-inbound-rtp': Type.remoteInboundRtp,
    'remote-outbound-rtp': Type.remoteOutboundRtp,
    'track': Type.track
  };

  static const Map<Type, String> values = {
    Type.candidatePair: 'candidate-pair',
    Type.codec: 'codec',
    Type.inboundRtp: 'inbound-rtp',
    Type.localCandidate: 'local-candidate',
    Type.mediaSource: 'media-source',
    Type.outboundRtp: 'outbound-rtp',
    Type.remoteCandidate: 'remote-candidate',
    Type.remoteInboundRtp: 'remote-inbound-rtp',
    Type.remoteOutboundRtp: 'remote-outbound-rtp',
    Type.track: 'track',
  };

  static Type fromString(String type) => types[type]!;

  String get value => values[this]!;
}

Map<String, dynamic> getDefaultAudioMetricsIn() {
  return <String, dynamic>{
    "codec_id_in": "",
    "codec_in": {"mime_type": null, "clock_rate": null, "sdp_fmtp_line": null},
    "delta_jitter_ms_in": 0,
    "delta_rtt_ms_out": null,
    "percent_packets_lost_in": 0,
    "delta_packets_in": 0,
    "delta_packets_lost_in": 0,
    "total_packets_in": 0,
    "total_packets_lost_in": 0,
    "total_KBytes_in": 0,
    "delta_KBytes_in": 0,
    "delta_kbs_in": 0,
    "timestamp_in": null,
    "ssrc": "",
    "total_concealment_events": 0,
    "delta_concealment_events": 0,
    "total_inserted_samples_for_decelaration": 0,
    "delta_inserted_samples_for_decelaration": 0,
    "total_removed_samples_for_accelaration": 0,
    "delta_removed_samples_for_accelaration": 0,
    "direction": Direction.inbound.name,
    "track_in": ""
  };
}

Map<String, dynamic> getDefaultAudioMetricsOut() {
  return <String, dynamic>{
    "codec_id_out": "",
    "codec_out": {"mime_type": null, "clock_rate": null, "sdp_fmtp_line": null},
    "delta_jitter_ms_out": 0,
    "delta_rtt_ms_out": null,
    "percent_packets_lost_out": 0,
    "delta_packets_out": 0,
    "delta_packets_lost_out": 0,
    "total_packets_out": 0,
    "total_packets_lost_out": 0,
    "total_KBytes_out": 0,
    "delta_KBytes_out": 0,
    "delta_kbs_out": 0,
    "timestamp_out": null,
    "ssrc": "",
    "direction": Direction.outbound.name,
    "track_out": ""
  };
}

Map<String, dynamic> getDefaultVideoMetricIn() {
  return <String, dynamic>{
    "codec_id_in": "",
    "size_in": {"width": null, "height": null, "framerate": null},
    "codec_in": {"mime_type": null, "clock_rate": null},
    "delta_jitter_ms_in": 0,
    "percent_packets_lost_in": 0,
    "delta_packets_in": 0,
    "delta_packets_lost_in": 0,
    "total_packets_in": 0,
    "total_packets_lost_in": 0,
    "total_KBytes_in": 0,
    "delta_KBytes_in": 0,
    "delta_kbs_in": 0,
    "ssrc": "",
    "direction": Direction.inbound.name,
    "track_in": ""
  };
}

Map<String, dynamic> getDefaultVideoMetricOut() {
  return <String, dynamic>{
    "codec_id_out": "",
    "size_out": {"width": null, "height": null, "framerate": null},
    "codec_out": {"mime_type": null, "clock_rate": null},
    "delta_jitter_ms_out": 0,
    "delta_rtt_ms_out": null,
    "percent_packets_lost_out": 0,
    "delta_packets_out": 0,
    "delta_packets_lost_out": 0,
    "total_packets_out": 0,
    "total_packets_lost_out": 0,
    "total_KBytes_out": 0,
    "delta_KBytes_out": 0,
    "delta_kbs_out": 0,
    "limitation_out": {
      "reason": null,
      "durations": null,
      "resolutionChanges": 0
    },
    "timestamp_out": null,
    "ssrc": "",
    "direction": Direction.outbound.name,
    "track_out": ""
  };
}

Map<String, dynamic> getDefaultMetrics(Map<String, dynamic>? previousStats) {
  const Map<String, dynamic> defaultMetrics = {
    "name": "",
    "roomId": "",
    "peerId": "",
    "timestamp": null,
    "count": 0,
    "audio": {},
    "video": {},
    "network": {
      "infrastructure": 3,
    },
    "data": {
      "delta_kbs_bandwidth_in": 0,
      "delta_kbs_bandwidth_out": 0,
      "delta_rtt_connectivity_ms": null,
      "total_rtt_connectivity_ms": 0,
    },
  };

  if (previousStats != null) {
    var metrics = {
      ...previousStats,
      "audio": {},
      "video": {},
      "data": {...(previousStats["data"] as Map)},
      "network": {...(previousStats["network"] as Map)},
    };
    for (var ssrc in (previousStats["audio"] as Map).keys) {
          metrics["audio"][ssrc] = {...(previousStats["audio"][ssrc] as Map)};
        }
    for (var ssrc in (previousStats["video"] as Map).keys) {
          metrics["video"][ssrc] = {...(previousStats["video"][ssrc] as Map)};
        }
    return metrics;
  }
  return {
    ...defaultMetrics,
    "audio": {},
    "video": {},
    "data": {...(defaultMetrics["data"] as Map)},
    "network": {...(defaultMetrics["network"] as Map)}
  };
}

Map<String, dynamic> getDefaultSSRCMetric(kind, reportType) {
  if (kind == Value.audio.name) {
    if (reportType == Type.inboundRtp.value) {
      return {...getDefaultAudioMetricsIn()};
    }
    return {...getDefaultAudioMetricsOut()};
  }

  if (reportType == Type.inboundRtp.value) {
    return {...getDefaultVideoMetricIn()};
  }
  return {...getDefaultVideoMetricOut()};
}
