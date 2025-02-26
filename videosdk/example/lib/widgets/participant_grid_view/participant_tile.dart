import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_flutter_example/widgets/stats/call_stats.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../utils/toast.dart';

class ParticipantTile extends StatefulWidget {
  final Participant participant;
  final ParticipantPinState pinState;
  final bool isLocalParticipant;
  const ParticipantTile({
    super.key,
    required this.participant,
    required this.pinState,
    this.isLocalParticipant = false,
  });

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  Stream? shareStream;
  Stream? videoStream;
  Stream? audioStream;
  String? quality = "high";
  String currentQuality = "";
  bool shouldRenderVideo = true;
  bool isPinned = false;

  @override
  void initState() {
    _initStreamListeners();
    super.initState();

    widget.participant.streams.forEach((key, Stream stream) {
      setState(() {
        if (stream.kind == 'video') {
          videoStream = stream;
          widget.participant.setQuality(quality);
        } else if (stream.kind == 'audio') {
          audioStream = stream;
        } else if (stream.kind == 'share') {
          shareStream = stream;
        }
      });
    });
    isPinned = widget.pinState.cam || widget.pinState.share;
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key("tile_${widget.participant.id}"),
      onVisibilityChanged: (visibilityInfo) {
        // if (visibilityInfo.visibleFraction > 0 && !shouldRenderVideo) {
        //   if (videoStream?.track.paused ?? true) {
        //     // videoStream?.track.resume();
        //   }
        //   // setState(() => shouldRenderVideo = true);
        // } else if (visibilityInfo.visibleFraction == 0 && shouldRenderVideo) {
        //   // videoStream?.track.pause();
        //   setState(() => shouldRenderVideo = false);
        // }
      },
      child: Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 1),
          border: Border.all(
            color: Colors.white38,
          ),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Stack(
              children: [
                videoStream != null && shouldRenderVideo
                    ? RTCVideoView(
                        videoStream?.renderer as RTCVideoRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.person,
                          size: 180.0,
                          color: Color.fromARGB(140, 255, 255, 255),
                        ),
                      ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white24,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        "${widget.participant.displayName} : ${widget.participant.mode.name}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: InkWell(
                    onTap: widget.isLocalParticipant
                        ? null
                        : () {
                            if (audioStream != null) {
                              widget.participant.muteMic();
                            } else {
                              toastMsg("Mic requested");
                              widget.participant.unmuteMic();
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: audioStream != null
                            ? Theme.of(context).scaffoldBackgroundColor
                            : Colors.red,
                      ),
                      child: Icon(
                        audioStream != null ? Icons.mic : Icons.mic_off,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: widget.isLocalParticipant
                        ? null
                        : () {
                            if (videoStream != null) {
                              widget.participant.disableCam();
                            } else {
                              toastMsg("Camera requested");
                              widget.participant.enableCam();
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: videoStream != null
                            ? Theme.of(context).scaffoldBackgroundColor
                            : Colors.red,
                      ),
                      child: videoStream != null
                          ? const Icon(
                              Icons.videocam,
                              size: 16,
                            )
                          : const Icon(
                              Icons.videocam_off,
                              size: 16,
                            ),
                    ),
                  ),
                ),
                if (!widget.isLocalParticipant)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        child: const Icon(
                          Icons.logout,
                          size: 16,
                        ),
                      ),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: const Text("Are you sure ?"),
                                  actions: [
                                    TextButton(
                                      child: const Text("Yes"),
                                      onPressed: () {
                                        widget.participant.remove();
                                        toastMsg("Participant removed");
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text("No"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  ],
                                ));
                      },
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  child: InkWell(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.pinState.cam || widget.pinState.share
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          child: Icon(
                            Icons.push_pin,
                            size: 16,
                            color: widget.pinState.cam || widget.pinState.share
                                ? Colors.black
                                : Colors.white54,
                          ),
                        ),
                        Text(
                            "${widget.pinState.cam ? "CAM " : ""} ${widget.pinState.share ? "SHARE" : ""}")
                      ],
                    ),
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: const Text("Pin / Unpin"),
                                actions: [
                                  TextButton(
                                    child: const Text("SHARE"),
                                    onPressed: () {
                                      if (widget.pinState.cam ||
                                          widget.pinState.share) {
                                        widget.participant.unpin(PinType.SHARE);
                                      } else {
                                        widget.participant.pin(PinType.SHARE);
                                      }
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text("CAM"),
                                    onPressed: () {
                                      if (widget.pinState.cam ||
                                          widget.pinState.share) {
                                        widget.participant.unpin(PinType.CAM);
                                      } else {
                                        widget.participant.pin(PinType.CAM);
                                      }
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text("SHARE AND CAM"),
                                    onPressed: () {
                                      if (widget.pinState.cam ||
                                          widget.pinState.share) {
                                        widget.participant.unpin();
                                      } else {
                                        widget.participant.pin();
                                      }
                                      Navigator.of(context).pop();
                                    },
                                  )
                                ],
                              ));
                    },
                  ),
                ),
                Positioned(
                    bottom: 4,
                    right: 4,
                    child: CallStats(participant: widget.participant)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _initStreamListeners() {
    widget.participant.on(Events.streamEnabled, (Stream stream) {
      setState(() {
        if (stream.kind == 'video') {
          videoStream = stream;
          widget.participant.setQuality(quality);
        } else if (stream.kind == 'audio') {
          audioStream = stream;
        } else if (stream.kind == 'share') {
          shareStream = stream;
        }
      });
    });

    widget.participant.on(Events.streamDisabled, (Stream stream) {
      setState(() {
        if (stream.kind == 'video' && videoStream?.id == stream.id) {
          videoStream = null;
        } else if (stream.kind == 'audio' && audioStream?.id == stream.id) {
          audioStream = null;
        } else if (stream.kind == 'share' && shareStream?.id == stream.id) {
          shareStream = null;
        }
      });
    });

    widget.participant.on(Events.streamPaused, (Stream stream) {
      setState(() {
        if (stream.kind == 'video' && videoStream?.id == stream.id) {
          videoStream = stream;
        } else if (stream.kind == 'audio' && audioStream?.id == stream.id) {
          audioStream = stream;
        } else if (stream.kind == 'share' && shareStream?.id == stream.id) {
          shareStream = stream;
        }
      });
    });

    widget.participant.on(Events.streamResumed, (Stream stream) {
      setState(() {
        if (stream.kind == 'video' && videoStream?.id == stream.id) {
          videoStream = stream;
          widget.participant.setQuality(quality);
        } else if (stream.kind == 'audio' && audioStream?.id == stream.id) {
          audioStream = stream;
        } else if (stream.kind == 'share' && shareStream?.id == stream.id) {
          shareStream = stream;
        }
      });
    });

    widget.participant.on(Events.videoQualityChanged, (data) {
      setState(
        () => currentQuality = data["currentQuality"],
      );
    });
  }
}
