import 'package:collection/collection.dart';
import 'package:videosdk_webrtc/flutter_webrtc.dart';

import '../../handlers/sdp/media_section.dart';
import '../../rtp_parameters.dart';
import '../../sdp_object.dart';
import '../../transport.dart';

class PlainRtpUtils {
  static PlainRtpParameters extractPlainRtpParameters(
    SdpObject sdpObject,
    RTCRtpMediaType kind,
  ) {
    final mtype = RTCRtpMediaTypeExtension.value(kind);
    MediaObject? mediaObject = sdpObject.media.firstWhere(
      (MediaObject m) => m.type == mtype,
      orElse: () => throw 'cannot find media with type $mtype',
    );

    Connection connectionObject =
        (mediaObject.connection ?? sdpObject.connection)!;

    PlainRtpParameters result = PlainRtpParameters(
      ip: connectionObject.ip,
      ipVersion: connectionObject.version,
      port: mediaObject.port!,
    );

    return result;
  }

  static List<RtpEncodingParameters> getRtpEncodings(
    SdpObject sdpObject,
    RTCRtpMediaType kind,
  ) {
    MediaObject? mediaObject = sdpObject.media.firstWhereOrNull(
      (MediaObject m) => m.type == RTCRtpMediaTypeExtension.value(kind),
    );

    if (mediaObject?.ssrcs != null && mediaObject!.ssrcs!.isNotEmpty) {
      Ssrc ssrc = mediaObject.ssrcs!.first;
      RtpEncodingParameters result = RtpEncodingParameters(ssrc: ssrc.id);

      return <RtpEncodingParameters>[result];
    }

    return <RtpEncodingParameters>[];
  }
}
