import 'package:events2/events2.dart';
import 'package:videosdk_room_stats/src/common/data_models.dart';
import 'package:videosdk_room_stats/src/extractor.dart';
import 'package:videosdk_room_stats/src/monitoring_object.dart';

class Collector {
  final MonitoringObject monitoringObject;
  final String probeId;
  final String roomId;
  final String name;
  final String peerId;
  final EventEmitter eventEmitter;
  List<Map<String, dynamic>> statsReports = List.empty(growable: true);

  Collector(this.monitoringObject, this.probeId, this.name, this.roomId,
      this.peerId, this.eventEmitter);

  void collectStats() async {
    List<dynamic> reports = await monitoringObject.getStats();
    var report = analyze(
      reports,
      statsReports.isNotEmpty ? statsReports.last : null,
    );
    // log("DEBUG :: REPORT ::" + report.toString());
    statsReports.add(report);

    try {
      var finalReport = formatCollectedStats(report);
      eventEmitter.emit("stats-collected-$probeId", finalReport);
    } catch (error) {
      // log("COLLECT ERROR :: " + error.toString());
    }
  }

  Map<String, dynamic> analyze(
      List<dynamic> stats, Map<String, dynamic>? previousReport) {
    var report = getDefaultMetrics(previousReport);
    report['name'] = name;
    report['roomId'] = roomId;
    report['peerId'] = peerId;
    report["count"] = previousReport != null ? previousReport["count"] + 1 : 1;

    int? timestamp = DateTime.now().millisecond;
    stats.forEach((stat) {
      // timestamp = stat.timestamp;
      List<Map<String, dynamic>> values =
          extract(stat.values, report, stat.type, stat.id, report['name']);

      values.forEach((data) {
        try {
          if (data.containsKey('value') && data.containsKey('type')) {
            if (data.containsKey('ssrc')) {
              var ssrcReport = report[data['type']][data['ssrc']];
              if (ssrcReport == null) {
                ssrcReport =
                    getDefaultSSRCMetric(data['type'], stat.values['type']);
                if (!ssrcReport.containsKey('ssrc')) {
                  ssrcReport['ssrc'] = {};
                }
                ssrcReport['ssrc'] = data['ssrc'];
                if (!report.containsKey(data['type'])) {
                  report[data['type']] = {};
                }
                report[data['type']][data['ssrc']] = ssrcReport;
              }
              data['value'].forEach((key, value) {
                if (data['value'][key] != null) {
                  ssrcReport?[key] = value;
                }
              });
            } else {
              data['value'].forEach((key, value) {
                if (data['value'][key] != null) {
                  report[data['type']][key] = data['value'][key];
                }
              });
            }
          }
        } catch (error) {
          // log("AFTER ANALYZE :: " + error.toString());
        }
      });
    });
    report['timestamp'] = timestamp;
    return report;
  }

  Map<String, dynamic> formatCollectedStats(Map<String, dynamic> report) {
    var stat = <String, dynamic>{};
    stat['roomId'] = report['roomId'];
    stat['peerId'] = report['peerId'];
    stat['name'] = report['name'];
    stat['audio'] = [];
    stat['video'] = [];
    report['audio'].forEach((key, audioStat) {
      var finalAudioStats = {};
      finalAudioStats['network'] = InfrastructureValueExtension.fromInt(
              report['network']?['infrastructure'] ?? 3)
          .name;
      finalAudioStats['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      if (audioStat['direction'] == Direction.inbound.name) {
        finalAudioStats['codec'] = audioStat['codec_in']?['mime_type'] ?? "";
        finalAudioStats['jitter'] = audioStat['delta_jitter_ms_in'];
        finalAudioStats['bitrate'] = audioStat['delta_kbs_in'];
        finalAudioStats['packetsLost'] = audioStat['delta_packets_lost_in'];
        finalAudioStats['rtt'] =
            report['data']['delta_rtt_connectivity_ms'] ?? 0;
        finalAudioStats['totalPackets'] = audioStat['delta_packets_in'];
        finalAudioStats['concealmentEvents'] =
            audioStat['delta_concealment_events'];
        finalAudioStats['removedSampleForAccelaration'] =
            audioStat['delta_removed_samples_for_accelaration'];
        finalAudioStats['insertedSamplesForDecelaration'] =
            audioStat['delta_inserted_samples_for_decelaration'];
        finalAudioStats['trackId'] = audioStat['track_id_in'];
      } else if (audioStat['direction'] == Direction.outbound.name) {
        finalAudioStats['codec'] = audioStat['codec_out']?['mime_type'] ?? "";
        finalAudioStats['jitter'] = audioStat['delta_jitter_ms_out'];
        finalAudioStats['bitrate'] = audioStat['delta_kbs_out'];
        finalAudioStats['packetsLost'] = audioStat['delta_packets_lost_out'];
        finalAudioStats['rtt'] =
            report['data']['delta_rtt_connectivity_ms'] ?? 0;
        finalAudioStats['totalPackets'] = audioStat['delta_packets_out'];
        finalAudioStats['trackId'] = audioStat['track_id_out'];
      }
      stat['audio'].add(finalAudioStats);
    });

    report['video'].forEach((key, videoStat) {
      if (key == 1234) return;
      var finalVideoStat = {};
      finalVideoStat['network'] = InfrastructureValueExtension.fromInt(
              report['network']?['infrastructure'] ?? 3)
          .name;
      finalVideoStat['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      if (videoStat['direction'] == Direction.inbound.name) {
        finalVideoStat['codec'] = videoStat['codec_in']?['mime_type'] ?? "";
        finalVideoStat['jitter'] = videoStat['delta_jitter_ms_in'];
        finalVideoStat['bitrate'] = videoStat['delta_kbs_in'];
        finalVideoStat['packetsLost'] = videoStat['delta_packets_lost_in'];
        finalVideoStat['rtt'] =
            report['data']['delta_rtt_connectivity_ms'] ?? 0;
        finalVideoStat['totalPackets'] = videoStat['delta_packets_in'];
        finalVideoStat['trackId'] = videoStat['track_id_in'];
        finalVideoStat['size'] = videoStat['size_in'];
        finalVideoStat['pauseCount'] = videoStat['pause_count'];
        finalVideoStat['totalPausesDuration'] = videoStat['total_pauses_duration'];
        finalVideoStat['freezeCount'] = videoStat['freeze_count'];
        finalVideoStat['totalFreezesDuration'] = videoStat['total_freezes_duration'];
      } else if (videoStat['direction'] == Direction.outbound.name) {
        finalVideoStat['codec'] = videoStat['codec_out']?['mime_type'] ?? "";
        finalVideoStat['jitter'] = videoStat['delta_jitter_ms_out'];
        finalVideoStat['bitrate'] = videoStat['delta_kbs_out'];
        finalVideoStat['packetsLost'] = videoStat['delta_packets_lost_out'];
        finalVideoStat['rtt'] =
            report['data']['delta_rtt_connectivity_ms'] ?? 0;
        finalVideoStat['totalPackets'] = videoStat['delta_packets_out'];
        finalVideoStat['limitation'] = videoStat['limitation_out'];
        finalVideoStat['size'] = videoStat['size_out'];
        finalVideoStat['trackId'] = videoStat['track_id_out'];
      }
      stat['video'].add(finalVideoStat);
    });
    return stat;
  }
}
