import 'dart:async';
import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/widgets/stats/call_stats_bottom_sheet.dart';

class CallStats extends StatefulWidget {
  final Participant participant;

  const CallStats({super.key, required this.participant});

  @override
  State<CallStats> createState() => _CallStatsState();
}

class _CallStatsState extends State<CallStats> {
  Timer? statsTimer;
  bool showFullStats = false;
  int? score;
  PersistentBottomSheetController? bottomSheetController;

  @override
  void initState() {
    statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      updateStats();
    });
    super.initState();
    updateStats();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: score != null && !showFullStats
          ? GestureDetector(
              onTap: () {
                setState(() {
                  showFullStats = !showFullStats;
                });
                bottomSheetController = showBottomSheet(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    context: context,
                    builder: (_) {
                      return CallStatsBottomSheet(
                          participant: widget.participant);
                    });
                bottomSheetController?.closed.then((value) {
                  setState(() {
                    showFullStats = !showFullStats;
                  });
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: score! > 7
                      ? Colors.green
                      : score! > 4
                          ? Colors.yellow
                          : Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.network_cell,
                  size: 17,
                ),
              ),
            )
          : null,
    );
  }

  void updateStats() {
    if (widget.participant.streams.isEmpty) {
      bottomSheetController?.close();
    }
    var audioStats = widget.participant.getAudioStats();
    var videoStats = widget.participant.getVideoStats();
    dynamic vStats;
    videoStats?.forEach((stat) {
      if (vStats == null) {
        vStats = stat;
      } else {
        if (stat['size']['width'] != "null" &&
            stat['size']['width'] != null &&
            vStats['size']['width'] != null) {
          if (stat['size']['width'] > vStats['size']['width']) {
            vStats = stat;
          }
        }
      }
    });
    var stats = {};
    if (audioStats != null) {
      if (audioStats.isNotEmpty) stats = audioStats[0];
    }
    if (vStats != null) {
      stats = vStats;
    }
    double packetLossPercent =
        (stats['packetsLost'] ?? 0.0) / (stats['totalPackets'] ?? 1);
    if (packetLossPercent.isNaN) {
      packetLossPercent = 0;
    }
    num jitter = stats['jitter'] ?? 0;
    num rtt = stats['rtt'] ?? 0;
    double? score = stats.isNotEmpty ? 100 : null;
    if (score != null) {
      score -= packetLossPercent * 50 > 50 ? 50 : packetLossPercent * 50;
      score -= ((jitter / 30) * 25 > 25 ? 25 : (jitter / 30) * 25);
      score -= ((rtt / 300) * 25 > 25 ? 25 : (rtt / 300) * 25);
    }
    setState(() {
      score = score != null ? (score! / 10).roundToDouble() : null;
    });
  }

  @override
  void dispose() {
    if (statsTimer != null) {
      statsTimer?.cancel();
    }
    if (widget.participant.streams.isEmpty) {
      bottomSheetController?.close();
    }
    super.dispose();
  }
}
