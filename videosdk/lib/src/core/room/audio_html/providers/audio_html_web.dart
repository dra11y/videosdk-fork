import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:dart_webrtc/dart_webrtc.dart';
import 'package:videosdk/src/core/room/audio_html/audio_html_interface.dart';
// ignore: implementation_imports
import 'package:dart_webrtc/src/media_stream_track_impl.dart';
import 'package:videosdk/src/core/webrtc/webrtc_client.dart';
import 'package:web/web.dart' as web;

class AudioHTMLWeb implements AudioHTMLInterface {
  final Map<String, web.Element> _audioElements = {};

  @override
  Future<dynamic> startAudio(Consumer? audioConsumer) async {
    if (audioConsumer == null) {
      return;
    }

    MediaStreamTrack track = audioConsumer.track;

    if (track is! MediaStreamTrackWeb) {
      return;
    }

    final elementId = "audio_${track.id}";
    var audioElement = web.document.getElementById(elementId);
    if (audioElement == null) {
      audioElement = web.HTMLAudioElement()
        ..id = elementId
        ..autoplay = true;
      findOrCreateAudioContainer().append(audioElement);
      _audioElements[track.id!] = audioElement;
    }

    if (!audioElement.isA<web.HTMLAudioElement>()) {
      return;
    }
    audioElement = audioElement as web.HTMLAudioElement;
    var srcObject = audioConsumer.stream as MediaStreamWeb;
    if (audioConsumer.stream.getAudioTracks().isNotEmpty) {
      final audioStream = web.MediaStream();
      for (final track in srcObject.jsStream.getAudioTracks().toDart) {
        audioStream.addTrack(track);
      }
      audioElement.srcObject = audioStream;
      return audioElement.play();
    }
  }

  web.HTMLDivElement findOrCreateAudioContainer() {
    var div = web.document.getElementById("videosdk_audio_container");
    if (div != null) {
      return div as web.HTMLDivElement;
    }

    div = web.HTMLDivElement()
      ..id = "videosdk_audio_container"
      ..style.display = 'none';
    web.document.body?.append(div);
    return div as web.HTMLDivElement;
  }

  @override
  void stopAudio(String id) {
    final audioElement = web.document.getElementById("audio_$id");
    if (audioElement != null) {
      if (audioElement.isA<web.HTMLAudioElement>()) {
        (audioElement as web.HTMLAudioElement).srcObject = null;
      }
      _audioElements.remove(id);
      audioElement.remove();
    }
  }

  @override
  void setAudioOutputDevice(String deviceId) {
    web.HTMLCollection audioElements =
        web.document.getElementsByTagName('audio');

    for (var i = 0; i < audioElements.length; i++) {
      if ((audioElements.item(i)!).hasProperty("setSinkId".toJS).toDart) {
        audioElements.item(i)!.callMethod("setSinkId".toJS, [deviceId].jsify());
      }
    }
  }
}

AudioHTMLInterface getInterface() => AudioHTMLWeb();
