import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../utils/spacer.dart';

import '../widgets/meeting_controls/meeting_action_button.dart';
import 'meeting_screen.dart';

// Join Screen
class JoinScreen extends StatefulWidget {
  final String meetingId;
  final String token;

  const JoinScreen({
    super.key,
    required this.meetingId,
    required this.token,
  });

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  // Display Name
  String displayName = "";

  // Control Status
  bool isMicOn = true;
  bool isCameraOn = true;

  // Camera Controller
  CameraController? cameraController;

  @override
  void initState() {
    super.initState();

    // Get available cameras
    availableCameras().then((availableCameras) {
      // stores selected camera id
      int selectedCameraId = availableCameras.length > 1 ? 1 : 0;

      cameraController = CameraController(
        availableCameras[selectedCameraId],
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      cameraController!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    }).catchError((err) {
      log("Error: $err");
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Screen Title
        title: const Text("VideoSDK RTC"),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: !(cameraController?.value.isInitialized ?? false)
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    VerticalSpacer(MediaQuery.of(context).size.height / 7),

                    // Camera Preview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: (MediaQuery.of(context).size.height / 2),
                        ),
                        child: Stack(
                          // fit: StackFit.expand,
                          children: [
                            AspectRatio(
                              aspectRatio:
                                  1 / cameraController!.value.aspectRatio,
                              child: isCameraOn
                                  ? CameraPreview(cameraController!)
                                  : Container(
                                      color: Colors.black,
                                      child: const Center(
                                        child: Text(
                                          "Camera is turned off",
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,

                              // Meeting ActionBar
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // Mic Action Button
                                  MeetingActionButton(
                                    icon: isMicOn ? Icons.mic : Icons.mic_off,
                                    backgroundColor: isMicOn
                                        ? Theme.of(context).primaryColor
                                        : Colors.red,
                                    iconColor: Colors.white,
                                    radius: 30,
                                    onPressed: () => setState(
                                      () => isMicOn = !isMicOn,
                                    ),
                                  ),

                                  // Camera Action Button
                                  MeetingActionButton(
                                    backgroundColor: isCameraOn
                                        ? Theme.of(context).primaryColor
                                        : Colors.red,
                                    iconColor: Colors.white,
                                    radius: 30,
                                    onPressed: () {
                                      if (isCameraOn) {
                                        cameraController?.pausePreview();
                                      } else {
                                        cameraController?.resumePreview();
                                      }
                                      setState(() => isCameraOn = !isCameraOn);
                                    },
                                    icon: isCameraOn
                                        ? Icons.videocam
                                        : Icons.videocam_off,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalSpacer(16),

                    // Display Name TextField
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: TextField(
                        onChanged: ((value) => displayName = value),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter Name",
                          hintStyle: TextStyle(
                            color: Colors.white,
                          ),
                          prefixIcon: Icon(
                            Icons.keyboard,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const VerticalSpacer(20),

                    // Join Button
                    TextButton(
                      onPressed: () async {
                        // By default Guest is used as display name
                        if (displayName.isEmpty) {
                          displayName = "Guest";
                        }

                        // Dispose Camera Controller before leaving screen
                        await cameraController?.dispose();

                        if (!context.mounted) {
                          return;
                        }

                        // Open meeting screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MeetingScreen(
                              token: widget.token,
                              meetingId: widget.meetingId,
                              displayName: displayName,
                              micEnabled: isMicOn,
                              camEnabled: isCameraOn,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      child: const Text(
                        "JOIN",
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose Camera Controller
    cameraController?.dispose();
    super.dispose();
  }
}
