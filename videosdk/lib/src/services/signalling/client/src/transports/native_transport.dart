import 'dart:convert';
import 'dart:io';

import 'package:videosdk/src/core/room/open_telemetry/videosdk_log.dart';

import '../logger.dart';
import '../message.dart';
import 'transport_interface.dart';

final _logger = Logger('Logger::NativeTransport');

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
              "error in Transport :: closing the WebSocket \n ${error.toString()}",
          logLevel: "ERROR");
      //
      _logger.error('close() | error closing the WebSocket: $error');
    }
  }

  @override
  Future send(message) async {
    try {
      _ws?.add(jsonEncode(message));
    } catch (error) {
      //
      VideoSDKLog.createLog(
          message: "Error in Transport :: send() \n ${error.toString()}",
          logLevel: "ERROR");
      //
      _logger.warn('send() failed:$error');
    }
  }

  _onOpen() {
    _logger.debug('onOpen');
    safeEmit('open');
  }

  // _onClose(event) {
  //   logger.warn(
  //       'WebSocket "close" event [wasClean:${e.wasClean}, code:${e.code}, reason:"${e.reason}"]');
  //   this._closed = true;

  //   this.safeEmit('close');
  // }

  _onError(err) {
    //
    VideoSDKLog.createLog(
        message: "Error in Transport :: error event \n ${err.toString()}",
        logLevel: "ERROR");
    //
    _logger.error('WebSocket "error" event');
  }

  _runWebSocket() async {
    WebSocket.connect(_url, protocols: ['protoo']).then((ws) {
      if (ws.readyState == WebSocket.open) {
        _ws = ws;
        _onOpen();

        ws.listen((event) {
          final message = Message.parse(event);

          if (message == null) return;

          safeEmit('message', message);
        }, onError: _onError);
      } else {
        _logger.warn(
            'WebSocket "close" event code:${ws.closeCode}, reason:"${ws.closeReason}"]');
        _closed = true;

        safeEmit('close');
      }
    });
    // this._ws.listen((e) {
    //   logger.debug('onOpen');
    //   this.safeEmit('open');
    // });

    // this._ws.onClose.listen((e) {
    //   logger.warn(
    //       'WebSocket "close" event [wasClean:${e.wasClean}, code:${e.code}, reason:"${e.reason}"]');
    //   this._closed = true;

    //   this.safeEmit('close');
    // });

    // this._ws.onError.listen((e) {
    //   logger.error('WebSocket "error" event');
    // });

    // this._ws.onMessage.listen((e) {
    //   final message = Message.parse(e.data);

    //   if (message == null) return;

    //   this.safeEmit('message', message);
    // });
  }
}
