library videosdk_room_stats;

import 'package:events2/events2.dart';
import 'package:videosdk_room_stats/src/monitoring_object.dart';

import 'probe.dart';

class VideoSDKMetricsConfig {
  int refreshEvery; // Default - generate a report every 2s (in ms). Min 1s.
  int startAfter; // Default - Duration (in ms) to wait before starting to grab the stats. 0 starts immediately
  int stopAfter; // Default - Max duration (in ms) for grabbing the stats. -1 means until calling stop().
  String peerId;
  String roomId;
  String name;
  EventEmitter eventEmitter;
  VideoSDKMetricsConfig(
      {this.refreshEvery = 2000,
      this.startAfter = 0,
      this.stopAfter = -1,
      this.peerId = "peerId",
      this.roomId = "roomId",
      this.name = "name",
      required this.eventEmitter});
}

class VideoSDKMetrics {
  final VideoSDKMetricsConfig _config;
  final Map<String, Probe> _probes = {};

  VideoSDKMetrics(this._config);
  Map<String, Probe> getProbes() {
    return _probes;
  }

  Probe addNewProbe(MonitoringObject monitoring, String name) {
    Probe probe = Probe(monitoring, _config);
    _probes.putIfAbsent(probe.id, () => probe);
    return probe;
  }

  void removeExistingProbe(Probe probe) {
    probe.stop();
    _probes.remove(probe.id);
  }

  void startAllProbes() {
    for (var probe in _probes.values) {
      probe.start();
    }
  }

  void stopAllProbes() {
    for (var probe in _probes.values) {
      probe.stop();
    }
  }
}
