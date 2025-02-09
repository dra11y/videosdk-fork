import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:videosdk/videosdk.dart';
import 'package:videosdk_media_effects/videosdk_media_effects.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/screen_select_dialog.dart';
import '/screens/chat_screen.dart';

import '../../navigator_key.dart';
import '../utils/spacer.dart';
import '../utils/toast.dart';
import '../widgets/meeting_controls/meeting_action_bar.dart';
import '../widgets/participant_grid_view/participant_grid_view.dart';
import 'startup_screen.dart';
import 'package:videosdk_webrtc/flutter_webrtc.dart';

// Meeting Screen
class MeetingScreen extends StatefulWidget {
  final String meetingId, token, displayName;
  final bool micEnabled, camEnabled, chatEnabled;
  const MeetingScreen({
    super.key,
    required this.meetingId,
    required this.token,
    required this.displayName,
    this.micEnabled = true,
    this.camEnabled = true,
    this.chatEnabled = true,
  });

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  // Recording Webhook
  final String recordingWebHookURL = "";

  // Meeting
  late Room meeting;
  bool _joined = false;

  // control states
  bool isRecordingOn = false;
  bool isLiveStreamOn = false;
  bool isHlsOn = false;

  bool isWhiteboardOn = false;
  late WebViewController controller;

  // List of controls
  List<VideoDeviceInfo>? cameras = [];
  List<AudioDeviceInfo>? mics = [];
  List<AudioDeviceInfo>? speakers = [];
  String? selectedMicId;
  Character? character;

  String? activePresenterId;

  // Streams
  Stream? shareStream;
  Stream? videoStream;
  Stream? audioStream;
  Stream? remoteParticipantShareStream;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    // Create instance of Room (Meeting)
    initMeeting();
  }

  initMeeting() async {
    // //Creating Custom Video Track

    VideoSDK.on(Events.error, (error) {
      print(
          "VIDEOSDK ERROR :: ${error['code']}  :: ${error['name']} :: ${error['message']}");
    });

    CustomTrack? videoTrack = await VideoSDK.createCameraVideoTrack(
      encoderConfig: CustomVideoTrackConfig.h360p_w480p,
      multiStream: false,
    );

    //Creating Custom Audio Track
    CustomTrack? audioTrack = await VideoSDK.createMicrophoneAudioTrack(
      encoderConfig: CustomAudioTrackConfig.high_quality,
    );

    Room room = VideoSDK.createRoom(
      roomId: widget.meetingId,
      token: widget.token,
      displayName: widget.displayName,
      micEnabled: widget.micEnabled,
      camEnabled: widget.camEnabled,
      maxResolution: 'hd',
      defaultCameraIndex: 0,
      multiStream: false,
      mode: Mode.SEND_AND_RECV,
      customCameraVideoTrack: videoTrack, // custom video track :: optional
      customMicrophoneAudioTrack: audioTrack, // custom audio track :: optional
      notification: const NotificationInfo(
        title: "Video SDK",
        message: "Video SDK is sharing screen in the meeting",
        icon: "notification_share", // drawable icon name
      ),
    );

    // Register meeting events
    registerMeetingEvents(room);

    // Join meeting
    room.join();
  }

  @override
  Widget build(BuildContext context) {
    //Get statusbar height
    final statusbarHeight = MediaQuery.of(context).padding.top;

    log("Meeting Data: ${widget.meetingId} ${widget.token}");
    return PopScope(
      onPopInvokedWithResult: (didPop, result) => _onWillPopScope(),
      child: _joined
          ? Scaffold(
              backgroundColor: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: 0.8),
              floatingActionButton: MeetingActionBar(
                isMicEnabled: audioStream != null,
                isCamEnabled: videoStream != null,
                isScreenShareEnabled: shareStream != null,
                isScreenShareButtonDisabled:
                    remoteParticipantShareStream != null,
                // Called when Call End button is pressed
                onCallEndButtonPressed: () {
                  meeting.leave();
                },
                // Called when mic button is pressed
                onMicButtonPressed: () async {
                  if (meeting.micEnabled) {
                    meeting.muteMic();
                  } else {
                    //Create Custom Audio track
                    // CustomTrack? audioTrack =
                    //     await VideoSDK.createMicrophoneAudioTrack(
                    //         encoderConfig: CustomAudioTrackConfig.high_quality);
                    meeting.unmuteMic();
                  }
                },
                // Called when camera button is pressed
                onCameraButtonPressed: () async {
                  if (meeting.camEnabled) {
                    meeting.disableCam();
                  } else {
                    //Create Custom Video track
                    CustomTrack? track = await VideoSDK.createCameraVideoTrack(
                      encoderConfig: CustomVideoTrackConfig.h720p_w960p,
                      multiStream: false,
                    );
                    meeting.enableCam(track);
                  }
                },
                // Called when switch camera button is pressed
                onSwitchCameraButtonPressed: () async {
                  final selectedCam = meeting.selectedCam;

                  VideoDeviceInfo deviceToSwitch = cameras!.firstWhere(
                    (cam) => cam.deviceId != selectedCam?.deviceId,
                  );

                  meeting.changeCam(deviceToSwitch);
                },

                // Called when ScreenShare button is pressed
                onScreenShareButtonPressed: () {
                  if (shareStream != null) {
                    meeting.disableScreenShare();
                  } else {
                    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
                      selectScreenSourceDialog(context).then((value) => {
                            if (value != null)
                              {meeting.enableScreenShare(value)}
                          });
                    } else {
                      meeting.enableScreenShare();
                    }
                  }
                },

                // Called when more options button is pressed
                onMoreButtonPressed: () {
                  // Showing more options dialog box
                  showDialog<void>(
                    context: navigatorKey.currentContext!,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text("More options"),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ElevatedButton(
                              child: const Text('CHANGE INPUT AUDIO DEVICE'),
                              onPressed: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title:
                                        const Text("Select input Audio Device"),
                                    content: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        SingleChildScrollView(
                                          reverse: true,
                                          child: Column(
                                            children: mics!
                                                .map(
                                                  (e) => ElevatedButton(
                                                    child: Text(
                                                        "${e.label}  ${e.deviceId}"),
                                                    onPressed: () => {
                                                      meeting.changeMic(e),
                                                      Navigator.pop(context)
                                                    },
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            ElevatedButton(
                              child: const Text('CHANGE OUTPUT AUDIO DEVICE'),
                              onPressed: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text(
                                        "Select output Audio Device"),
                                    content: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        SingleChildScrollView(
                                          reverse: true,
                                          child: Column(
                                            children: speakers!
                                                .map(
                                                  (e) => ElevatedButton(
                                                    child: Text(
                                                        "${e.label} ${e.deviceId}"),
                                                    onPressed: () => {
                                                      meeting
                                                          .switchAudioDevice(e),
                                                      Navigator.pop(context)
                                                    },
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            ElevatedButton(
                              child: const Text('CHANGE Video DEVICE'),
                              onPressed: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Select Video Device"),
                                    content: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        SingleChildScrollView(
                                          reverse: true,
                                          child: Column(
                                            children: cameras!
                                                .map(
                                                  (e) => ElevatedButton(
                                                    child: Text(e.label),
                                                    onPressed: () async => {
                                                      meeting.changeCam(e),
                                                      Navigator.pop(context)
                                                    },
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Add Character'),
                              onPressed: () {
                                CharacterConfig characterConfig =
                                    CharacterConfig.newInteraction(
                                        characterId: "shivani-v1",
                                        displayName: "MyCharacter",
                                        characterMode: CharacterMode.AUTO_PILOT,
                                        metaData: {"abcd": "xyz"});
                                character = meeting.createCharacter(
                                    characterConfig: characterConfig);
                                registerCharacterEvents(character!);
                                character?.join();

                                Navigator.pop(context);
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Send Message to Character'),
                              onPressed: () {
                                character?.sendMessage(message: "Hey there");

                                Navigator.pop(context);
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Leave Character'),
                              onPressed: () {
                                character?.leave();

                                Navigator.pop(context);
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Interrupt Character'),
                              onPressed: () {
                                character?.interrupt();

                                Navigator.pop(context);
                              },
                            ),

                            //Change Mode
                            ElevatedButton(
                              child: const Text('Change Mode'),
                              onPressed: () async {
                                if (meeting.localParticipant.mode ==
                                    Mode.SEND_AND_RECV) {
                                  meeting.changeMode(Mode.RECV_ONLY);
                                } else if (meeting.localParticipant.mode ==
                                    Mode.RECV_ONLY) {
                                  meeting.changeMode(Mode.SEND_AND_RECV);
                                }
                                Navigator.pop(context);
                              },
                            ),
                            // Chat
                            ElevatedButton(
                              child: const Text('Chat'),
                              onPressed: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height -
                                              statusbarHeight),
                                  isScrollControlled: true,
                                  builder: (context) =>
                                      ChatScreen(meeting: meeting),
                                );
                              },
                            ),

                            // Recording button
                            ElevatedButton(
                              child: Text(
                                isRecordingOn
                                    ? 'Stop Recording'
                                    : 'Start Recording',
                              ),
                              onPressed: () {
                                if (isRecordingOn) {
                                  meeting.stopRecording();
                                } else {
                                  meeting.startRecording();
                                }

                                Navigator.pop(context);
                              },
                            ),

                            ElevatedButton(
                              child: Text(
                                isWhiteboardOn
                                    ? 'Stop Whiteboard'
                                    : 'Start Whiteboard',
                              ),
                              onPressed: () {
                                if (isWhiteboardOn) {
                                  meeting.stopWhiteboard();
                                } else {
                                  meeting.startWhiteboard();
                                }

                                Navigator.pop(context);
                              },
                            ),

                            // Recording button
                            ElevatedButton(
                              child: Text(
                                isHlsOn ? 'Stop HLS' : 'Start HLS',
                              ),
                              onPressed: () {
                                if (isHlsOn) {
                                  meeting.stopHls();
                                } else {
                                  meeting.startHls(config: {
                                    'layout': {
                                      'type': 'GRID',
                                      'priority': 'SPEAKER',
                                      'gridSize': 4,
                                    },
                                    'theme': "LIGHT",
                                    "mode": "video-and-audio"
                                  });
                                }

                                Navigator.pop(context);
                              },
                            ),

                            // LiveStream button
                            ElevatedButton(
                              child: Text(
                                isLiveStreamOn
                                    ? 'Stop Livestream'
                                    : 'Start Livestream',
                              ),
                              onPressed: () {
                                List liveStreamOptions = [];

                                if (isLiveStreamOn) {
                                  meeting.stopLivestream();
                                } else {
                                  if (liveStreamOptions.isNotEmpty) {
                                    meeting.startLivestream(liveStreamOptions);
                                  } else {
                                    toastMsg(
                                      "Failed to start livestream. Please add live stream options.",
                                    );
                                  }
                                }

                                Navigator.pop(context);
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Selected devices'),
                              onPressed: () async {
                                print(
                                    "selected mic id ${meeting.selectedMic?.deviceId} ${meeting.selectedMic?.label}");
                                print(
                                    "selected Camera id${meeting.selectedCam!.deviceId}");
                                print(
                                    "selected speaker ${meeting.selectedSpeaker?.deviceId} ${meeting.selectedSpeaker?.label}");
                                Navigator.pop(context);
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Apply Package Background'),
                              onPressed: () {
                                Uri backgroundImageUri = Uri.parse(
                                    "https://st.depositphotos.com/2605379/52364/i/450/depositphotos_523648932-stock-photo-concrete-rooftop-night-city-view.jpg");
                                VideosdkMediaEffects.applyVirtualBackground(
                                    backgroundSource: backgroundImageUri);
                                // VideoSDK.applyVideoProcessor(videoProcessorName: "VirtualBGProcessor");

                                Navigator.pop(context);
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Change Virtual Background'),
                              onPressed: () {
                                Uri backgroundImageUri = Uri.parse(
                                    "https://wallpapers.com/images/featured/abstract-background-6m6cjbifu3zpfv84.jpg");
                                VideosdkMediaEffects.changeVirtualBackground(
                                    backgroundSource: backgroundImageUri);

                                Navigator.pop(context);
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Remove Virtual Background'),
                              onPressed: () {
                                // VideoSDK.removeVideoProcessor();
                                VideosdkMediaEffects.removeVirtualBackground();
                                Navigator.pop(context);
                              },
                            ),

                            ElevatedButton(
                              child: const Text('Low Resolution'),
                              onPressed: () {
                                meeting.participants.forEach((key, value) {
                                  value.setQuality('low');
                                });

                                Navigator.pop(context);
                              },
                            ),

                            ElevatedButton(
                              child: const Text('Med Resolution'),
                              onPressed: () {
                                meeting.participants.forEach((key, value) {
                                  value.setQuality('med');
                                });

                                Navigator.pop(context);
                              },
                            ),

                            ElevatedButton(
                              child: const Text('High Resolution'),
                              onPressed: () {
                                meeting.participants.forEach((key, value) {
                                  value.setQuality('high');
                                });

                                Navigator.pop(context);
                              },
                            ),

                            //check selected devices
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              appBar: AppBar(
                title: Text(widget.meetingId),
                actions: [
                  // Recording status
                  if (isRecordingOn)
                    SvgPicture.asset("assets/recording_on.svg"),

                  // Copy meeting id button
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.meetingId));
                      toastMsg("Meeting ID has been copied.");
                    },
                  ),
                ],
              ),
              body: Padding(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: Column(
                    children: [
                      if (remoteParticipantShareStream != null ||
                          shareStream != null)
                        SizedBox(
                          height: 200,
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              height: 300,
                              color: Colors.black,
                              child: RTCVideoView(
                                remoteParticipantShareStream != null
                                    ? remoteParticipantShareStream!.renderer!
                                    : shareStream!.renderer!,
                              ),
                            ),
                          ),
                        ),
                      if (isWhiteboardOn)
                        SizedBox(
                          height: 300,
                          width: 350,
                          child: WebViewWidget(
                            controller: controller,
                          ),
                        ),
                      Expanded(
                        child: ParticipantGridView(meeting: meeting),
                      ),
                    ],
                  )))
          : Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    VerticalSpacer(10),
                    Text("waiting to join meeting"),
                  ],
                ),
              ),
            ),
    );
  }

  void registerCharacterEvents(Character character) {
    character.on(Events.characterJoined, (Character character) {
      print(
          "Character Joined in character event with config $character ${character.runtimeType}");
    });

    character.on(Events.characterLeft, (Character character) {
      print(
          "Character left in character event with config $character ${character.runtimeType}");
    });

    character.on(Events.characterMessage, (CharacterMessage message) {
      print(
          "character Message ${message.text} ${message.characterId} ${message.characterName} ${message.runtimeType}");
    });

    character.on(Events.userMessage, (UserMessage message) {
      print(
          "user Message ${message.text} ${message.participantId} ${message.participantName} ${message.runtimeType}");
    });

    character.on(Events.characterStateChanged, (CharacterState state) {
      print("character state changed $state ${state.runtimeType}");
    });

    character.on(Events.streamEnabled, (data) {
      print("stream come $data");
    });
  }

  void registerMeetingEvents(Room meeting) {
    VideoSDK.on(Events.deviceChanged, () async {
      cameras = await VideoSDK.getVideoDevices();
      List<AudioDeviceInfo>? audioDeviceInfo = await VideoSDK.getAudioDevices();

      mics = [];
      speakers = [];

      if (audioDeviceInfo != null) {
        for (var device in audioDeviceInfo) {
          if (device.kind == 'audioinput') {
            mics?.add(device);
          } else {
            speakers?.add(device);
          }
        }
      }
    });
    // Called when joined in meeting
    meeting.on(
      Events.roomJoined,
      () async {
        setState(() {
          meeting = meeting;
          _joined = true;
        });

        // Holds available cameras info
        cameras = await VideoSDK.getVideoDevices();
        List<AudioDeviceInfo>? audioDeviceInfo =
            await VideoSDK.getAudioDevices();

        if (audioDeviceInfo != null) {
          for (var device in audioDeviceInfo) {
            if (device.kind == 'audioinput') {
              mics?.add(device);
            } else {
              speakers?.add(device);
            }
          }
        }
      },
    );

    // Called when meeting is ended
    meeting.on(Events.roomLeft, (String? errorMsg) {
      if (errorMsg != null) {
        toastMsg("Meeting left due to $errorMsg !!");
      }
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const StartupScreen()),
          (route) => false);
    });

    meeting.on(Events.roomStateChanged, (RoomState state) {
      switch (state) {
        case RoomState.connecting:
          print('Meeting is Connecting');
          break;
        case RoomState.connected:
          print('Meeting is Connected');
          break;
        case RoomState.disconnected:
          print('Meeting connection disconnected abruptly');
          break;
        case RoomState.failed:
          print('Meeting connection failed');
          break;
        case RoomState.closing:
          print('Meeting is closing');
          break;
        case RoomState.closed:
          print('Meeting connection closed');
          break;
      }
    });

    // Called when recording is started
    meeting.on(Events.recordingStarted, () {
      toastMsg("Meeting recording started.");

      setState(() {
        isRecordingOn = true;
      });
    });

    meeting.on(Events.recordingStateChanged, (String status) {
      toastMsg("Meeting recording status : $status");
    });

    // Called when recording is stopped
    meeting.on(Events.recordingStopped, () {
      toastMsg("Meeting recording stopped.");

      setState(() {
        isRecordingOn = false;
      });
    });

    meeting.on(Events.whiteboardStarted, (url) {
      toastMsg("Whiteboard started $url .");
      print("Whiteboard url: $url");

      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(
          Uri.parse(url),
        );

      setState(() {
        isWhiteboardOn = true;
      });
    });

    // Called when recording is stopped
    meeting.on(Events.whiteboardStopped, () {
      toastMsg("Whiteboard stopped.");

      setState(() {
        isWhiteboardOn = false;
      });
    });

    // Called when LiveStreaming is started
    meeting.on(Events.liveStreamStarted, () {
      toastMsg("Meeting live streaming started.");

      setState(() {
        isLiveStreamOn = true;
      });
    });

    meeting.on(Events.error, (error) {
      print(
          "VIDEOSDK ERROR :: ${error['code']}  :: ${error['name']} :: ${error['message']}");
    });

    // Called when LiveStreaming is stopped
    meeting.on(Events.liveStreamStopped, () {
      toastMsg("Meeting live streaming stopped.");

      setState(() {
        isLiveStreamOn = false;
      });
    });

    meeting.on(Events.liveStreamStateChanged, (String status) {
      toastMsg("Meeting live streaming status : $status");
    });

    // Called when HLS is started
    meeting.on(Events.hlsStarted, (downstreamUrl) {
      toastMsg("Meeting HLS started.");
      log("DOWNSTREAM URL -- $downstreamUrl");
      setState(() {
        isHlsOn = true;
      });
    });

    // Called when LiveStreaming is stopped
    meeting.on(Events.hlsStopped, () {
      toastMsg("Meeting HLS stopped.");
      setState(() {
        isHlsOn = false;
      });
    });

    meeting.on(Events.hlsStateChanged, (Map<String, dynamic> data) {
      toastMsg("Meeting HLS status : ${data['status']}");
      if (data['status'] == "HLS_STARTED") {
        log("DOWNSTREAM URL -- ${data['downstreamUrl']}");
      }
    });

    // Called when mic is requested
    meeting.on(Events.micRequested, (data) {
      log("_data => $data");
      dynamic accept = data['accept'];
      dynamic reject = data['reject'];

      log("accept => $accept reject => $reject");

      // Mic Request Dialog
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: const Text("Mic requested?"),
          content: const Text("Do you want to turn on your mic? "),
          actions: [
            TextButton(
              onPressed: () {
                reject();

                Navigator.of(context).pop();
              },
              child: const Text("Reject"),
            ),
            TextButton(
              onPressed: () {
                accept();

                Navigator.of(context).pop();
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      );
    });

    // Called when camera is requested
    meeting.on(Events.cameraRequested, (data) {
      log("_data => $data");
      dynamic accept = data['accept'];
      dynamic reject = data['reject'];

      log("accept => $accept reject => $reject");

      // camera Request Dialog
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: const Text("Camera requested?"),
          content: const Text("Do you want to turn on your Camera? "),
          actions: [
            TextButton(
              onPressed: () {
                reject();

                Navigator.of(context).pop();
              },
              child: const Text("Reject"),
            ),
            TextButton(
              onPressed: () {
                accept();

                Navigator.of(context).pop();
              },
              child: const Text("Accept"),
            ),
          ],
        ),
      );
    });

    // Called when stream is enabled
    meeting.localParticipant.on(Events.streamEnabled, (Stream stream) {
      if (stream.kind == 'video') {
        setState(() {
          videoStream = stream;
        });
      } else if (stream.kind == 'audio') {
        setState(() {
          audioStream = stream;
        });
      } else if (stream.kind == 'share') {
        setState(() {
          shareStream = stream;
        });
      }
    });

    // Called when stream is disabled
    meeting.localParticipant.on(Events.streamDisabled, (Stream stream) {
      if (stream.kind == 'video' && videoStream?.id == stream.id) {
        setState(() {
          videoStream = null;
        });
      } else if (stream.kind == 'audio' && audioStream?.id == stream.id) {
        setState(() {
          audioStream = null;
        });
      } else if (stream.kind == 'share' && shareStream?.id == stream.id) {
        setState(() {
          shareStream = null;
        });
      }
    });

    // Called when presenter is changed
    meeting.on(Events.presenterChanged, (activePresenterId) {
      Participant? activePresenterParticipant =
          meeting.participants[activePresenterId];

      // Get Share Stream
      Stream? stream = activePresenterParticipant?.streams.values
          .singleWhere((e) => e.kind == "share");

      setState(() => remoteParticipantShareStream = stream);
    });

    //Entry Event
    meeting.on(Events.entryRequested, (data) {
      // var participantId = data['participantId'];
      var name = data["name"];
      var allow = data["allow"];
      var deny = data["deny"];

      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: const Text("Join Request"),
          content: Text("Do you want to allow $name to join meeting?"),
          actions: [
            TextButton(
              onPressed: () {
                deny();
                Navigator.of(context).pop();
              },
              child: const Text("Deny"),
            ),
            TextButton(
              onPressed: () {
                allow();

                Navigator.of(context).pop();
              },
              child: const Text("Allow"),
            ),
          ],
        ),
      );
    });

    meeting.on(Events.entryResponded, (data) {
      var id = data['id'];
      var decision = data['decision'];
      if (id == meeting.localParticipant.id) {
        if (decision == 'allowed') {
          toastMsg("Allowed to join the meeting.");
        } else {
          toastMsg("Denied to join the meeting.");
          Navigator.of(context).pop();
        }
      }
    });

    meeting.on(Events.error, (error) {
      log("VIDEOSDK ERROR :: ${error['code']}  :: ${error['name']} :: ${error['message']}");
      toastMsg("VIDEOSDK ERROR :: ${error['message']}");
    });
  }

  Future<bool> _onWillPopScope() async {
    meeting.leave();
    return true;
  }

  Future<DesktopCapturerSource?> selectScreenSourceDialog(
      BuildContext context) async {
    final source = await showDialog<DesktopCapturerSource>(
      context: context,
      builder: (context) => ScreenSelectDialog(
        meeting: meeting,
      ),
    );
    return source;
  }
}
