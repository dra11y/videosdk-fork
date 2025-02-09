import 'dart:convert';
import 'dart:developer';

import 'package:videosdk_room_stats/src/common/data_models.dart';

Map<String, dynamic> extractBytesSentReceived(
    Map<dynamic, dynamic> bunch, Map<String, dynamic>? previousBunch) {
  var totalKBytesReceived = (bunch[Property.bytesReceived.name] ?? 0) / 1024;

  var totalKBytesSent = (bunch[Property.bytesSent.name] ?? 0) / 1024;

  var timestamp = bunch[Property.timestamp.name] ?? DateTime.now().millisecond;
  var KBytesReceived = totalKBytesReceived -
      (previousBunch != null
          ? previousBunch['data']['total_KBytes_in'] ?? 0
          : 0);

  var KBytesSent = totalKBytesSent -
      (previousBunch != null
          ? previousBunch['data']['total_KBytes_out'] ?? 0
          : 0);

  var previousTimestamp =
      previousBunch != null ? previousBunch["timestamp"] : null;
  var deltaMs = previousTimestamp != null
      ? ((timestamp - previousTimestamp) as num).abs()
      : 0;
  var kbsSpeedReceived = deltaMs > 0
      ? ((KBytesReceived * 0.008 * 1024) / deltaMs)
      : 0; // kbs = kilo bits per second

  var kbsSpeedSent = deltaMs > 0 ? ((KBytesSent * 0.008 * 1024) / deltaMs) : 0;
  return {
    "total_KBytes_received": totalKBytesReceived,
    "total_KBytes_sent": totalKBytesSent,
    "delta_KBytes_received": KBytesReceived,
    "delta_KBytes_sent": KBytesSent,
    "kbs_speed_received": kbsSpeedReceived,
    "kbs_speed_sent": kbsSpeedSent,
  };
}

Map<String, dynamic> extractRTTBasedOnSTUNConnectivityCheck(
    Map<dynamic, dynamic> bunch,
    String kind,
    Map<String, dynamic>? previousBunch) {
  // If RTT is not part of the stat - return null value
  if (!bunch.containsKey(Property.currentRoundTripTime.name)) {
    return {
      "rtt": null,
      "totalRTT": previousBunch != null
          ? previousBunch[kind]['total_rtt_connectivity_ms'] ?? 0
          : 0,
      "totalRTTMeasurements": previousBunch != null
          ? previousBunch[kind]['total_rtt_connectivity_measure'] ?? 0
          : 0,
    };
  }

  var currentRTT = 1000 * (bunch[Property.currentRoundTripTime.name] as double);
  var currentTotalRTT = (previousBunch != null
          ? previousBunch[kind]['total_rtt_connectivity_ms'] ?? 0
          : 0) +
      currentRTT;
  var currentTotalMeasurements = (previousBunch != null
          ? previousBunch[kind]['total_rtt_connectivity_measure'] ?? 0
          : 0) +
      1;

  // If support of totalRoundTripTime
  if (bunch.containsKey(Property.totalRoundTripTime.name)) {
    currentTotalRTT = 1000 * (bunch[Property.totalRoundTripTime.name]);
  }
  // If support of responsesReceived
  if (bunch.containsKey(Property.responsesReceived.name)) {
    currentTotalMeasurements = bunch[Property.responsesReceived.name];
  }
  return {
    "rtt": currentRTT,
    "totalRTT": currentTotalRTT,
    "totalRTTMeasurements": currentTotalMeasurements,
  };
}

String extractRelayProtocolUsed(Map<dynamic, dynamic> bunch) {
  var candidateType = bunch[Property.candidateType.name];
  if (candidateType != "relay") {
    return "";
  }
  return bunch[Property.relayProtocol.name] ?? "";
}

Map<String, dynamic> extractAvailableBandwidth(bunch) {
  var kbsIncomingBandwidth =
      (bunch[Property.availableIncomingBitrate.name] ?? 0) / 1024;
  var kbsOutgoingBandwidth =
      (bunch[Property.availableOutgoingBitrate.name] ?? 0) / 1024;

  return {
    'kbs_incoming_bandwidth': kbsIncomingBandwidth,
    "kbs_outgoing_bandwidth": kbsOutgoingBandwidth,
  };
}

Map<String, dynamic>? getSSRCDataFromBunch(
    int ssrc, Map<String, dynamic>? bunch, String direction) {
  if (bunch == null) {
    return null;
  }
  Map<String, dynamic> ssrcBunch = {};
  var audioBunch = bunch[Value.audio.name][ssrc];
  audioBunch ??= direction == Direction.inbound.name
      ? {...getDefaultAudioMetricsIn()}
      : {...getDefaultAudioMetricsOut()};
  ssrcBunch[Value.audio.name] = audioBunch;

  var videoBunch = bunch[Value.video.name][ssrc];
  videoBunch ??= direction == Direction.inbound.name
      ? {...getDefaultVideoMetricIn()}
      : {...getDefaultVideoMetricOut()};
  ssrcBunch[Value.video.name] = videoBunch;
  return ssrcBunch;
}

Map<String, dynamic> extractAudioVideoPacketReceived(
  Map<dynamic, dynamic> bunch,
  String kind,
  Map<String, dynamic>? previousBunch,
) {
  if (!bunch.containsKey(Property.packetsReceived.name) ||
      !bunch.containsKey(Property.packetsLost.name) ||
      !bunch.containsKey(Property.bytesReceived.name)) {
    return {
      "percent_packets_lost":
          previousBunch?[kind]?['percent_packets_lost_in'] ?? 0,
      "packetsReceived": previousBunch?[kind]?['total_packets_in'] ?? 0,
      "packetsLost": previousBunch?[kind]?['total_packets_lost_in'] ?? 0,
      "bytesReceived": previousBunch?[kind]?['total_KBytes_in'] ?? 0,
    };
  }

  var packetsReceived = bunch[Property.packetsReceived.name] ?? 0;
  var packetsLost = bunch[Property.packetsLost.name] ?? 0;
  var deltaPacketsLost =
      packetsLost - (previousBunch?[kind]?['total_packets_lost_in'] ?? 0);
  var deltaPacketsReceived =
      packetsReceived - (previousBunch?[kind]?['total_packets_in'] ?? 0);
  var percentPacketsLost =
      packetsReceived != (previousBunch?[kind]?['total_packets_in'] ?? 0)
          ? (deltaPacketsLost * 100) / (deltaPacketsLost + deltaPacketsReceived)
          : 0.0;
  var KBytesReceived = (bunch[Property.bytesReceived.name] ?? 0) / 1024;
  var deltaKBytesReceived =
      KBytesReceived - (previousBunch?[kind]?['total_KBytes_in'] ?? 0);
  var timestamp = bunch[Property.timestamp.name] ?? DateTime.now().millisecond;
  var previousTimestamp = previousBunch?['timestamp'];

  var deltaMs = previousTimestamp != null
      ? ((timestamp - previousTimestamp) as num).abs()
      : 0;
  var kbsReceived = deltaMs > 0
      ? ((deltaKBytesReceived * 0.008 * 1024) / deltaMs)
      : 0; // kbs = kilo bits per second

  return {
    'percentPacketsLost': percentPacketsLost,
    'packetsReceived': packetsReceived,
    'deltaPacketsReceived': deltaPacketsReceived,
    'packetsLost': packetsLost,
    'deltaPacketsLost': deltaPacketsLost,
    'KBytesReceived': KBytesReceived,
    'deltaKBytesReceived': deltaKBytesReceived,
    'kbsReceived': kbsReceived,
  };
}

double? extractLastJitter(Map<dynamic, dynamic> bunch, String kind,
    Map<String, dynamic>? previousBunch) {
  if (!bunch.containsKey(Property.jitter.name)) {
    return null;
  }

  return 1000 * (bunch[Property.jitter.name] ?? 0) as double;
}

Map<String, dynamic> extractAudioEventsData(
  Map<dynamic, dynamic> bunch,
  String kind,
  Map<String, dynamic>? previousBunch,
) {
  var totalConcealmentEvents = bunch[Property.concealmentEvents.name] ?? 0;
  var deltaConcealmentEvents = totalConcealmentEvents -
      (previousBunch?[kind]?['total_concealment_events'] ?? 0);

  var totalInsertedSamplesForDecelaration =
      bunch[Property.insertedSamplesForDeceleration.name] ?? 0;
  var deltaInsertedSamplesForDecelaration =
      totalInsertedSamplesForDecelaration -
          (previousBunch?[kind]?['total_inserted_samples_for_decelaration'] ??
              0);

  var totalRemovedSamplesForAccelaration =
      bunch[Property.removedSamplesForAcceleration.name] ?? 0;
  var deltaRemovedSampleForAccelaration = totalRemovedSamplesForAccelaration -
      (previousBunch?[kind]?['total_removed_samples_for_accelaration'] ?? 0);

  return {
    "totalConcealmentEvents": totalConcealmentEvents,
    "deltaConcealmentEvents": deltaConcealmentEvents,
    "totalInsertedSamplesForDecelaration": totalInsertedSamplesForDecelaration,
    "deltaInsertedSamplesForDecelaration": deltaInsertedSamplesForDecelaration,
    "totalRemovedSamplesForAccelaration": totalRemovedSamplesForAccelaration,
    "deltaRemovedSampleForAccelaration": deltaRemovedSampleForAccelaration,
  };
}

Map<String, dynamic> extractDecodeTime(
    Map<dynamic, dynamic> bunch, Map<String, dynamic>? previousBunch) {
  if (!bunch.containsKey(Property.framesDecoded.name) ||
      !bunch.containsKey(Property.totalDecodeTime.name)) {
    return {
      "delta_ms_decode_frame":
          previousBunch?[Value.video.name]?['delta_ms_decode_frame_in'] ?? 0,
      "frames_decoded":
          previousBunch?[Value.video.name]?['total_frames_decoded_in'] ?? 0,
      "total_decode_time":
          previousBunch?[Value.video.name]?['total_time_decoded_in'] ?? 0,
    };
  }

  var decodedFrames = bunch[Property.framesDecoded.name];
  var totalDecodeTime = bunch[Property.totalDecodeTime.name];

  var decodeTimeDelta = totalDecodeTime -
          previousBunch?[Value.video.name]?['total_time_decoded_in'] ??
      0;
  var frameDelta = decodedFrames -
          previousBunch?[Value.video.name]?['total_frames_decoded_in'] ??
      0;

  return {
    "delta_ms_decode_frame":
        frameDelta > 0 ? (decodeTimeDelta * 1000) / frameDelta : 0,
    "frames_decoded": decodedFrames,
    "total_decode_time": totalDecodeTime,
  };
}

Map<String, dynamic> extractVideoSize(Map<dynamic, dynamic> bunch) {
  // if (!bunch.containsKey(Property.frameHeight.name) ||
  //     !bunch.containsKey(Property.frameWidth.name)) {
  //   return {"width": null, "height": null, "framerate": null};
  // }

  return {
    "width": bunch[Property.frameWidth.name],
    "height": bunch[Property.frameHeight.name],
    "framerate": bunch[Property.framesPerSecond.name],
  };
}

Map<String, dynamic> extractNackAndPliCountSentWhenReceiving(
  Map<dynamic, dynamic> bunch,
  Map<String, dynamic>? previousReport,
) {
  if (!bunch.containsKey(Property.pliCount.name) ||
      !bunch.containsKey(Property.nackCount.name)) {
    return {
      "pliCount": previousReport?['total_pli_sent_in'] ?? 0,
      "nackCount": previousReport?['total_nack_sent_in'] ?? 0,
      "deltaPliCount": 0,
      "deltaNackCount": 0,
    };
  }

  var pliCount = bunch[Property.pliCount.name] ?? 0;
  var nackCount = (bunch[Property.nackCount.name] ?? 0);

  return {
    'pliCount': pliCount,
    'nackCount': nackCount,
    "deltaPliCount": pliCount -
        (previousReport?[Value.video.name]['total_pli_sent_in'] ?? 0),
    "deltaNackCount": nackCount -
        (previousReport?[Value.video.name]['total_nack_sent_in'] ?? 0),
  };
}

Map<String, dynamic> extractAudioVideoPacketSent(Map<dynamic, dynamic> bunch,
    String kind, Map<String, dynamic>? previousBunch) {
  if (!bunch.containsKey(Property.packetsSent.name) ||
      !bunch.containsKey(Property.bytesSent.name)) {
    return {
      "packetsSent": previousBunch?[kind]?['total_packets_out'] ?? 0,
      "packetsLost": previousBunch?[kind]?['total_packets_lost_out'] ?? 0,
      "bytesSent": previousBunch?[kind]?['total_KBytes_out'] ?? 0,
    };
  }

  var packetsSent = (bunch[Property.packetsSent.name] ?? 0);
  var deltaPacketsSent =
      packetsSent - (previousBunch?[kind]?['total_packets_out'] ?? 0);
  var KBytesSent = (bunch[Property.bytesSent.name] ?? 0) / 1024;
  var deltaKBytesSent =
      (KBytesSent - (previousBunch?[kind]?['total_KBytes_out'] ?? 0));
  var timestamp = bunch[Property.timestamp.name] ?? DateTime.now().millisecond;
  var previousTimestamp = previousBunch?['timestamp'];

  var deltaMs = previousTimestamp != null
      ? ((timestamp - previousTimestamp) as num).abs()
      : 0;
  var kbsSent = deltaMs > 0
      ? ((deltaKBytesSent * 0.008 * 1024) / deltaMs)
      : 0; // kbs = kilo bits per second

  return {
    'packetsSent': packetsSent,
    'deltaPacketsSent': deltaPacketsSent,
    'KBytesSent': KBytesSent,
    'deltaKBytesSent': deltaKBytesSent,
    'kbsSent': kbsSent,
  };
}

Map<String, dynamic> extractAudioVideoPacketLost(Map<dynamic, dynamic> bunch,
    String kind, Map<String, dynamic>? previousBunch) {
  var packetsLost = previousBunch?[kind]?['total_packets_lost_out'] ?? 0;
  var deltaPacketsLost = 0;
  double fractionLost = 0;
  if (bunch.containsKey(Property.packetsLost.name)) {
    packetsLost = bunch[Property.packetsLost.name] ?? 0;
    deltaPacketsLost =
        packetsLost - (previousBunch?[kind]?['total_packets_lost_out'] ?? 0);
  }

  if (bunch.containsKey(Property.fractionLost.name)) {
    fractionLost = (100 * bunch[Property.fractionLost.name]) as double;
  }
  return {
    'packetsLost': packetsLost,
    'deltaPacketsLost': deltaPacketsLost,
    'fractionLost': fractionLost,
  };
}

String _convertToJsonStringQuotes({required String raw}) {
  /// remove space
  String jsonString = raw.replaceAll(" ", "");

  /// add quotes to json string
  jsonString = jsonString.replaceAll('{', '{"');
  jsonString = jsonString.replaceAll(':', '": "');
  jsonString = jsonString.replaceAll(',', '", "');
  jsonString = jsonString.replaceAll('}', '"}');

  /// remove quotes on object json string
  jsonString = jsonString.replaceAll('"{"', '{"');
  jsonString = jsonString.replaceAll('"}"', '"}');

  /// remove quotes on array json string
  jsonString = jsonString.replaceAll('"[{', '[{');
  jsonString = jsonString.replaceAll('}]"', '}]');

  return jsonString;
}

Map<String, dynamic> extractQualityLimitation(Map<dynamic, dynamic> bunch) {
  var reason = bunch.containsKey(Property.qualityLimitationReason.name)
      ? bunch[Property.qualityLimitationReason.name]
      : null;
  var resolutionChanges =
      bunch.containsKey(Property.qualityLimitationResolutionChanges.name)
          ? bunch[Property.qualityLimitationResolutionChanges.name]
          : null;

  Map<dynamic, dynamic>? durations = null;
  if (bunch.containsKey(Property.qualityLimitationDurations.name)) {
    String jsonString = _convertToJsonStringQuotes(
        raw: bunch[Property.qualityLimitationDurations.name].toString());
    durations = json.decode(jsonString);
    durations!.forEach((key, value) {
      durations![key] = double.parse(value);
    });
  }

  if (durations != null) {
    durations.keys.forEach((key) => {
          if (durations![key] > 1000) {durations[key] = durations[key] / 1000}
        });
  }
  return {
    'reason': reason,
    "durations": durations,
    'resolutionChanges': resolutionChanges
  };
}

Map<String, dynamic> extractAudioCodec(bunch) {
  return {
    "channels": bunch[Property.channels.name],
    "clock_rate": bunch[Property.clockRate.name],
    "mime_type": bunch[Property.mimeType.name],
    "sdp_fmtp_line": bunch[Property.sdpFmtpLine.name],
  };
}

Map<String, dynamic> extractVideoCodec(bunch) {
  return {
    "clock_rate": bunch[Property.clockRate.name],
    "mime_type": bunch[Property.mimeType.name],
  };
}

Map<String, dynamic> extractRTTBasedOnRTCP(Map<dynamic, dynamic> bunch,
    String kind, Map<String, dynamic>? previousBunch) {
  var supportOfMeasure = false;
  var previousRTT = previousBunch?[kind]?['total_rtt_ms_out'] ?? 0;
  var previousNbMeasure = previousBunch?[kind]?['total_rtt_measure_out'] ?? 0;

  var returnedValuesByDefault = {
    "rtt": null,
    "totalRTT": previousRTT,
    "totalRTTMeasurements": previousNbMeasure,
  };

  if (bunch[Property.timestamp.name] ==
      (previousBunch?[kind]?['timestamp_out'] ?? 0)) {
    return returnedValuesByDefault;
  }

  // If RTT is not part of the stat - return
  if (!bunch.containsKey(Property.roundTripTime.name)) {
    return returnedValuesByDefault;
  }

  // If no measure yet or no new measure - return
  if (bunch.containsKey(Property.roundTripTime.name)) {
    supportOfMeasure = true;
    if (bunch[Property.roundTripTimeMeasurements.name] == 0 ||
        bunch[Property.roundTripTimeMeasurements.name] == previousNbMeasure) {
      return returnedValuesByDefault;
    }
  }

  var currentRTT = 1000 * bunch[Property.roundTripTime.name];
  var currentTotalRTT = previousRTT + currentRTT;
  var currentTotalMeasurements = previousNbMeasure + 1;

  // If support of totalRoundTripTime
  if (supportOfMeasure) {
    currentTotalRTT = 1000 * bunch[Property.roundTripTime.name];
    currentTotalMeasurements = bunch[Property.roundTripTimeMeasurements.name];
  }

  return {
    "rtt": currentRTT,
    "totalRTT": currentTotalRTT,
    "totalRTTMeasurements": currentTotalMeasurements,
  };
}

List<Map<String, dynamic>> extract(Map<dynamic, dynamic> bunch,
    Map<String, dynamic>? previousBunch, String type, String id, String name) {
  switch (type) {
    case 'candidate-pair':
      {
        var selectedPair = false;
        if (bunch[Property.nominated.name] &&
            bunch[Property.state.name] == Value.succeeded.name) {
          selectedPair = true;

          // FF: Do not use candidate-pair with selected=false
          if (bunch.containsKey(Property.selected.name) &&
              !bunch[Property.selected.name]) {
            selectedPair = false;
          }
        }
        if (selectedPair) {
          var valueSentReceived =
              extractBytesSentReceived(bunch, previousBunch);
          var bandwidth = extractAvailableBandwidth(bunch);
          var rttConnectivity = extractRTTBasedOnSTUNConnectivityCheck(
              bunch, "data", previousBunch);
          return [
            {
              "type": StatType.data.name,
              "value": {
                "total_KBytes_in": valueSentReceived["total_KBytes_received"]
              },
            },
            {
              "type": StatType.data.name,
              "value": {
                "total_KBytes_out": valueSentReceived["total_KBytes_sent"]
              },
            },
            {
              "type": StatType.data.name,
              "value": {
                "delta_KBytes_in": valueSentReceived["delta_KBytes_received"]
              },
            },
            {
              "type": StatType.data.name,
              "value": {
                "delta_KBytes_out": valueSentReceived["delta_KBytes_sent"]
              },
            },
            {
              "type": StatType.data.name,
              "value": {
                "delta_kbs_in": valueSentReceived["kbs_speed_received"]
              },
            },
            {
              "type": StatType.data.name,
              "value": {"delta_kbs_out": valueSentReceived["kbs_speed_sent"]},
            },
            {
              "type": StatType.data.name,
              "value": {"delta_rtt_connectivity_ms": rttConnectivity["rtt"]},
            },
          ];
        }
      }

      break;

    case "local-candidate":
      try {
        if (previousBunch != null) {
          if (id == previousBunch['network']['local_candidate_id']) {
            return [
              {
                "type": StatType.network.name,
                "value": {"infrastructure": bunch[Property.networkType.name]},
              },
              {
                "type": StatType.network.name,
                "value": {
                  "local_candidate_protocol":
                      bunch[Property.protocol.name] ?? ""
                },
              },
              {
                "type": StatType.network.name,
                "value": {
                  "local_candidate_relay_protocol":
                      extractRelayProtocolUsed(bunch),
                },
              },
            ];
          }
        }
      } catch (error) {
        // log("ERROR:: LOCAL_CANDIDATE" + error.toString());
      }
      break;

    case 'inbound-rtp':
      try {
        // get SSRC and associated data
        var ssrc = bunch[Property.ssrc.name];
        var previousSSRCBunch =
            getSSRCDataFromBunch(ssrc, previousBunch, Direction.inbound.name);
        if (previousSSRCBunch != null && previousBunch != null) {
          previousSSRCBunch['timestamp'] = previousBunch['timestamp'];
        }

        if (bunch[Property.mediaType.name] == Value.audio.name) {
          // Packets stats and Bytes
          var data = extractAudioVideoPacketReceived(
              bunch, Value.audio.name, previousSSRCBunch);

          // Jitter stats
          var jitter =
              extractLastJitter(bunch, Value.audio.name, previousSSRCBunch);

          // Codec stats
          var audioInputCodecId = bunch[Property.codecId.name] ?? "";

          var audioData = extractAudioEventsData(
              bunch, Value.audio.name, previousSSRCBunch);

          return [
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"direction": Direction.inbound.name},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"codec_id_in": audioInputCodecId},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"total_packets_in": data['packetsReceived']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"delta_packets_in": data['deltaPacketsReceived']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"total_packets_lost_in": data['packetsLost']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"delta_packets_lost_in": data['deltaPacketsLost']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"percent_packets_lost_in": data['percentPacketsLost']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"total_KBytes_in": data['KBytesReceived']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"delta_KBytes_in": data['deltaKBytesReceived']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"delta_kbs_in": data['kbsReceived']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {"delta_jitter_ms_in": jitter},
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {
                "total_concealment_events": audioData['totalConcealmentEvents'],
              },
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {
                "delta_concealment_events": audioData['deltaConcealmentEvents'],
              },
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {
                "total_inserted_samples_for_decelaration":
                    audioData['totalInsertedSamplesForDecelaration'],
              },
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {
                "delta_inserted_samples_for_decelaration":
                    audioData['deltaInsertedSamplesForDecelaration'],
              },
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {
                "total_removed_samples_for_accelaration":
                    audioData['totalRemovedSamplesForAccelaration'],
              },
            },
            {
              "ssrc": ssrc,
              "type": StatType.audio.name,
              "value": {
                "delta_removed_samples_for_accelaration":
                    audioData['deltaRemovedSampleForAccelaration'],
              },
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"track_in": bunch[Property.trackId.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"track_id_in": bunch[Property.trackIdentifier.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"media_source_id": bunch[Property.mediaSourceId.name]},
            },
          ];
        }

        if (bunch[Property.mediaType.name] == Value.video.name) {
          // Decode time stats
          // var data = extractDecodeTime(bunch, previousSSRCBunch);

          // Packets stats and Bytes
          var packetsData = extractAudioVideoPacketReceived(
              bunch, Value.video.name, previousSSRCBunch);
          // Jitter stats
          var jitter =
              extractLastJitter(bunch, Value.video.name, previousSSRCBunch);

          // Codec stats
          // var decoderImplementation = bunch[Property.decoderImplementation];
          var videoInputCodecId = bunch[Property.codecId.name] ?? "";

          // Video size
          var inputVideo = extractVideoSize(bunch);

          // Nack & Pli stats
          // var nackPliData =
          //     extractNackAndPliCountSentWhenReceiving(bunch, previousSSRCBunch);

          return [
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {"direction": Direction.inbound.name},
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {"codec_id_in": videoInputCodecId},
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {"total_packets_in": packetsData['packetsReceived']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {
                "delta_packets_in": packetsData['deltaPacketsReceived']
              },
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {"total_packets_lost_in": packetsData['packetsLost']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {
                "delta_packets_lost_in": packetsData['deltaPacketsLost']
              },
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {
                "percent_packets_lost_in": packetsData['percentPacketsLost']
              },
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {"total_KBytes_in": packetsData['KBytesReceived']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {"delta_KBytes_in": packetsData['deltaKBytesReceived']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {"delta_kbs_in": packetsData['kbsReceived']},
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {"delta_jitter_ms_in": jitter},
            },
            {
              "ssrc": ssrc,
              "type": StatType.video.name,
              "value": {"size_in": inputVideo},
            },
            {
              'ssrc': ssrc,
              'type': StatType.video.name,
              'value': {"track_in": bunch[Property.trackId.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.video.name,
              'value': {"track_id_in": bunch[Property.trackIdentifier.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.video.name,
              'value': {"media_source_id": bunch[Property.mediaSourceId.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.video.name,
              'value': {"pause_count": bunch[Property.pauseCount.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.video.name,
              'value': {"total_pauses_duration": bunch[Property.totalPausesDuration.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.video.name,
              'value': {"freeze_count": bunch[Property.freezeCount.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.video.name,
              'value': {"total_freezes_duration": bunch[Property.totalFreezesDuration.name]},
            },
          ];
        }
      } catch (error) {
        // log("ERROR:: INBOUND RTP" + error.toString());
      }
      break;

    case 'outbound-rtp':
      try {
        // get SSRC and associated data
        var ssrc = bunch[Property.ssrc.name];
        var previousSSRCBunch =
            getSSRCDataFromBunch(ssrc, previousBunch, Direction.outbound.name);
        if (previousSSRCBunch != null) {
          previousSSRCBunch['timestamp'] = previousBunch?['timestamp'] ?? 0;
        }
        if (bunch[Property.mediaType.name] == Value.audio.name) {
          var audioOutputCodecId = bunch[Property.codecId];

          // packets and bytes
          var data = extractAudioVideoPacketSent(
              bunch, Value.audio.name, previousSSRCBunch);
          return [
            {
              'ssrc': ssrc,
              "type": StatType.audio.name,
              "value": {"codec_id_out": audioOutputCodecId},
            },
            {
              'ssrc': ssrc,
              "type": StatType.audio.name,
              "value": {"total_packets_out": data['packetsSent']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.audio.name,
              "value": {"delta_packets_out": data['deltaPacketsSent']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.audio.name,
              "value": {"total_KBytes_out": data['KBytesSent']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.audio.name,
              "value": {"delta_KBytes_out": data['deltaKBytesSent']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.audio.name,
              "value": {"delta_kbs_out": data['kbsSent']},
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"track_out": bunch[Property.trackId.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"track_id_out": bunch[Property.trackIdentifier.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"media_source_id": bunch[Property.mediaSourceId.name]},
            },
          ];
        }
        if (bunch[Property.mediaType.name] == Value.video.name) {
          var videoOutputCodecId = bunch[Property.codecId.name];

          // Video size
          var outputVideo = extractVideoSize(bunch);

          // limitations
          var limitationOut = extractQualityLimitation(bunch);

          // packets and bytes
          var dataSent = extractAudioVideoPacketSent(
              bunch, Value.video.name, previousSSRCBunch);

          return [
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"codec_id_out": videoOutputCodecId},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"total_packets_out": dataSent['packetsSent']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"delta_packets_out": dataSent['deltaPacketsSent']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"total_KBytes_out": dataSent['KBytesSent']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"delta_KBytes_out": dataSent['deltaKBytesSent']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"delta_kbs_out": dataSent['kbsSent']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"size_out": outputVideo},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"limitation_out": limitationOut},
            },
            {
              'ssrc': ssrc,
              'type': StatType.video.name,
              'value': {"track_out": bunch[Property.trackId.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.video.name,
              'value': {"track_id_out": bunch[Property.trackIdentifier.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.video.name,
              'value': {"media_source_id": bunch[Property.mediaSourceId.name]},
            },
          ];
        }
      } catch (error) {
        log("ERROR:: outbound-rtp" + error.toString());
      }
      break;

    case 'codec':
      List<Map<String, dynamic>> result = [];
      // Check for Audio codec
      try {
        (previousBunch?[Value.audio.name] as Map<dynamic, dynamic>)
            .keys
            .forEach((ssrc) {
          var ssrcAudioBunch = previousBunch?[Value.audio.name][ssrc] ?? {};
          if (ssrcAudioBunch['codec_id_in'] == id ||
              ssrcAudioBunch['codec_id_out'] == id) {
            var codec = extractAudioCodec(bunch);
            if (id == ssrcAudioBunch['codec_id_in']) {
              result.add(<String, dynamic>{
                "ssrc": ssrcAudioBunch['ssrc'],
                'type': StatType.audio.name,
                'value': {'codec_in': codec},
              });
            } else if (id == ssrcAudioBunch['codec_id_out']) {
              result.add(<String, dynamic>{
                "ssrc": ssrcAudioBunch['ssrc'],
                'type': StatType.audio.name,
                'value': {'codec_out': codec},
              });
            }
          }
        });

        // Check for Video codec
        (previousBunch?[Value.video.name] as Map<dynamic, dynamic>)
            .keys
            .forEach((ssrc) {
          var ssrcVideoBunch = previousBunch?[Value.video.name][ssrc] ?? {};
          if (ssrcVideoBunch['codec_id_in'] == id ||
              ssrcVideoBunch['codec_id_out'] == id) {
            var codec = extractVideoCodec(bunch);
            if (id == ssrcVideoBunch['codec_id_in']) {
              result.add(<String, dynamic>{
                "ssrc": ssrcVideoBunch['ssrc'],
                "type": StatType.video.name,
                "value": {"codec_in": codec},
              });
            } else {
              result.add(<String, dynamic>{
                "ssrc": ssrcVideoBunch['ssrc'],
                "type": StatType.video.name,
                "value": {"codec_out": codec},
              });
            }
          }
        });
      } catch (error) {
        // log("ERROR CODEC :: " + error.toString());
      }

      return result;
    case 'remote-inbound-rtp':
      try {
        // get SSRC and associated data
        var ssrc = bunch[Property.ssrc.name];
        var previousSSRCBunch =
            getSSRCDataFromBunch(ssrc, previousBunch, Direction.inbound.name);
        if (bunch[Property.kind.name] == Value.audio.name) {
          // Round Trip Time based on RTCP
          var data =
              extractRTTBasedOnRTCP(bunch, Value.audio.name, previousSSRCBunch);

          // Jitter (out)
          var jitter =
              extractLastJitter(bunch, Value.audio.name, previousSSRCBunch);

          // Packets lost
          var packets = extractAudioVideoPacketLost(
              bunch, Value.audio.name, previousSSRCBunch);

          return [
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"delta_rtt_ms_out": data['rtt']},
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"delta_jitter_ms_out": jitter},
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"timestamp_out": bunch[Property.timestamp.name]},
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"total_packets_lost_out": packets['packetsLost']},
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"delta_packets_lost_out": packets['deltaPacketsLost']},
            },
            {
              'ssrc': ssrc,
              'type': StatType.audio.name,
              'value': {"percent_packets_lost_out": packets['fractionLost']},
            },
          ];
        }

        if (bunch[Property.kind.name] == Value.video.name) {
          // Round Trip Time based on RTCP
          var data =
              extractRTTBasedOnRTCP(bunch, Value.video.name, previousSSRCBunch);

          // Jitter (out)
          var jitter =
              extractLastJitter(bunch, Value.video.name, previousSSRCBunch);

          // Packets lost
          var packets = extractAudioVideoPacketLost(
              bunch, Value.video.name, previousSSRCBunch);

          return [
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"delta_rtt_ms_out": data['rtt']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"delta_jitter_ms_out": jitter},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"timestamp_out": bunch[Property.timestamp.name]},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"total_packets_lost_out": packets['packetsLost']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.video.name,
              "value": {"delta_packets_lost_out": packets['deltaPacketsLost']},
            },
          ];
        }
      } catch (error) {
        // log("ERROR :: remote-inbound-rtp" + error.toString());
      }
      break;
    case 'remote-outbound-rtp':
      try {
        // get SSRC and associated data
        var ssrc = bunch[Property.ssrc.name];
        var previousSSRCBunch =
            getSSRCDataFromBunch(ssrc, previousBunch, Direction.outbound.name);
        if (bunch[Property.kind.name] == Value.audio.name) {
          // Round Trip Time based on RTCP
          var data =
              extractRTTBasedOnRTCP(bunch, Value.audio.name, previousSSRCBunch);

          return [
            {
              'ssrc': ssrc,
              "type": StatType.audio.name,
              "value": {"delta_rtt_ms_in": data['rtt']},
            },
            {
              'ssrc': ssrc,
              "type": StatType.audio.name,
              "value": {"timestamp_in": bunch[Property.timestamp.name]},
            },
          ];
        }
      } catch (error) {
        // log("ERROR :: remote-outbound-rtp" + error.toString());
      }
      break;
    case 'media-source':
      List<Map<String, dynamic>> result = [];
      try {
        (previousBunch?[Value.audio.name] as Map<dynamic, dynamic>)
            .keys
            .forEach((ssrc) {
          var ssrcAudioBunch = previousBunch?[Value.audio.name][ssrc] ?? {};
          if (ssrcAudioBunch['media_source_id'] == id) {
            var trackId = bunch[Property.trackIdentifier.name];
            result.add(<String, dynamic>{
              "ssrc": ssrcAudioBunch['ssrc'],
              'type': StatType.audio.name,
              'value': {'track_id_out': trackId},
            });
          }
        });

        (previousBunch?[Value.video.name] as Map<dynamic, dynamic>)
            .keys
            .forEach((ssrc) {
          var ssrcVideoBunch = previousBunch?[Value.video.name][ssrc] ?? {};
          if (ssrcVideoBunch['media_source_id'] == id) {
            var trackId = bunch[Property.trackIdentifier.name];
            result.add(<String, dynamic>{
              "ssrc": ssrcVideoBunch['ssrc'],
              'type': StatType.video.name,
              'value': {'track_id_out': trackId},
            });
          }
        });
      } catch (error) {
        // log("ERROR media-source :: " + error.toString());
      }
      return result;
      break;
    case 'track':
      List<Map<String, dynamic>> result = [];
      try {
        (previousBunch?[Value.audio.name] as Map<dynamic, dynamic>)
            .keys
            .forEach((ssrc) {
          var ssrcAudioBunch = previousBunch?[Value.audio.name][ssrc] ?? {};
          if (ssrcAudioBunch['track_in'] == id ||
              ssrcAudioBunch['track_out'] == id) {
            var trackId = bunch[Property.trackIdentifier.name];
            if (id == ssrcAudioBunch['track_in']) {
              result.add(<String, dynamic>{
                "ssrc": ssrcAudioBunch['ssrc'],
                'type': StatType.audio.name,
                'value': {'track_id_in': trackId},
              });
            } else if (id == ssrcAudioBunch['track_out']) {
              result.add(<String, dynamic>{
                "ssrc": ssrcAudioBunch['ssrc'],
                'type': StatType.audio.name,
                'value': {'track_id_out': trackId},
              });
            }
          }
        });
        (previousBunch?[Value.video.name] as Map<dynamic, dynamic>)
            .keys
            .forEach((ssrc) {
          var ssrcVideoBunch = previousBunch?[Value.video.name][ssrc] ?? {};
          if (ssrcVideoBunch['track_in'] == id ||
              ssrcVideoBunch['track_out'] == id) {
            var trackId = bunch[Property.trackIdentifier.name];
            if (id == ssrcVideoBunch['track_in']) {
              result.add(<String, dynamic>{
                "ssrc": ssrcVideoBunch['ssrc'],
                'type': StatType.video.name,
                'value': {'track_id_in': trackId},
              });
            } else if (id == ssrcVideoBunch['track_out']) {
              result.add(<String, dynamic>{
                "ssrc": ssrcVideoBunch['ssrc'],
                'type': StatType.video.name,
                'value': {'track_id_out': trackId},
              });
            }
          }
        });
      } catch (error) {
        // log("ERROR CODEC :: " + error.toString());
      }

      return result;
      break;
    default:
      return [{}];
  }
  return [{}];
}
