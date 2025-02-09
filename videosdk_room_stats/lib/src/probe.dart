import 'dart:async';

import 'package:videosdk_room_stats/src/monitoring_object.dart';
import 'package:videosdk_room_stats/src/collector.dart';
import 'package:videosdk_room_stats/src/common/utils.dart';
import 'package:videosdk_room_stats/src/videosdk_metrics.dart';

class Probe {
  late String id;
  final MonitoringObject monitoringObject;
  final VideoSDKMetricsConfig config;
  Timer? collectorInterval;
  late Collector collector;

  Probe(this.monitoringObject, this.config) {
    id = generateRandomString(12);
    collector = Collector(monitoringObject, id, config.name, config.roomId,
        config.peerId, config.eventEmitter);
  }

  void start() {
    if (collectorInterval != null) {
      return;
    }
    collectorInterval = Timer.periodic(
      Duration(milliseconds: config.refreshEvery),
      (timer) {collector.collectStats();},
    );
  }

  void stop() {
    if (collectorInterval != null) {
      // log("STOPPING PROBE");
      collectorInterval!.cancel();
      collectorInterval = null;
    }
  }
}
