import 'package:videosdk_webrtc/flutter_webrtc.dart';

enum Permissions { audio, video, audio_video }

class DeviceInfo extends MediaDeviceInfo {
  DeviceInfo(
      {required super.deviceId,
      super.groupId,
      super.kind,
      required super.label});
}

class VideoDeviceInfo extends DeviceInfo {
  VideoDeviceInfo(
      {required super.deviceId,
      super.groupId,
      super.kind,
      required super.label});
}

class AudioDeviceInfo extends DeviceInfo {
  AudioDeviceInfo(
      {required super.deviceId,
      super.groupId,
      super.kind,
      required super.label});
}
