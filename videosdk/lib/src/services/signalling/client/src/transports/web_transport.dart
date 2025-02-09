import 'dart:convert';
import 'dart:html';

import 'package:videosdk/src/core/room/open_telemetry/videosdk_log.dart';

import '../logger.dart';
import '../message.dart';
import 'transport_interface.dart';

final _logger = Logger('Logger::WebTransport');

class Transport extends TransportInterface {
  late bool _closed;
  late String _url;
  // ignore: unused_field
  late dynamic _options;
  WebSocket? _ws;

  Transport(String url, {dynamic options}) : super(url, options: options) {
    _logger.debug('constructor() [url:$url, options:$options]');
    _closed = false;
    _url = url;
    _options = options ?? {};
    _ws = null;

    _runWebSocket();
  }

  @override
  get closed => _closed;

  @override
  close() {
    _logger.debug('close()');

    _closed = true;
    safeEmit('close');

    try {
      _ws?.close();
    } catch (error) {
      //
      VideoSDKLog.createLog(
          message:
              "error in WebTransport :: closing the WebSocket \n ${error.toString()}",
          logLevel: "ERROR");
      //
      _logger.error('close() | error closing the WebSocket: $error');
    }
  }

  @override
  Future send(message) async {
    try {
      _ws?.send(jsonEncode(message));
    } catch (error) {
      //
      VideoSDKLog.createLog(
          message:
              "Error in WebTransport :: send()-${jsonEncode(message)} \n ${error.toString()}",
          logLevel: "ERROR");
      //
      _logger.warn('send() failed:$error');
    }
  }

  _runWebSocket() {
    _ws = WebSocket(_url, 'protoo');
    _ws?.onOpen.listen((e) {
      _logger.debug('onOpen');
      safeEmit('open');
    });

    _ws?.onClose.listen((e) {
      _logger.warn(
          'WebSocket "close" event [wasClean:${e.wasClean}, code:${e.code}, reason:"${e.reason}"]');
      _closed = true;

      safeEmit('close');
    });

    _ws?.onError.listen((e) {
      //
      VideoSDKLog.createLog(
          message: "Error in WebTransport :: error event \n ${e.toString()}",
          logLevel: "ERROR");
      //
      _logger.error('WebSocket "error" event');
    });

    _ws?.onMessage.listen((e) {
      final message = Message.parse(e.data);

      if (message == null) return;

      safeEmit('message', message);
    });
  }
}
