import './client/messaging_client.dart' as protoo_client;

class WebSocket {
  final String peerId;
  final String meetingId;
  final String token;
  final String baseUrl;
  final String mode;

  late protoo_client.Peer _protoo;
  Function()? onOpen;
  Function()? onFail;
  Function()? onDisconnected;
  Function()? onClose;
  Function(
    dynamic request,
    dynamic accept,
    dynamic reject,
  )? onRequest; // request, accept, reject
  Function(dynamic notification)? onNotification;

  protoo_client.Peer get socket => _protoo;

  WebSocket({
    required this.peerId,
    required this.meetingId,
    required this.token,
    required this.baseUrl,
    required this.mode,
  }) {
    _protoo = protoo_client.Peer(
      protoo_client.Transport(
          "wss://$baseUrl/?roomId=$meetingId&peerId=$peerId&secret=$token&mode=$mode"),
    );

    _protoo.on('open', () => onOpen?.call());
    _protoo.on('failed', () => onFail?.call());
    _protoo.on('disconnected', () => onClose?.call());
    _protoo.on('close', () => onClose?.call());
    _protoo.on('request',
        (request, accept, reject) => onRequest?.call(request, accept, reject));
    _protoo.on('notification',
        (request, accept, reject) => onNotification?.call(request));
  }

  void close() {
    _protoo.close();
  }
}
