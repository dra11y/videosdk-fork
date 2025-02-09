class Logger {
  // ignore: unused_field
  final String _appName;
  Logger(this._appName);

  void error(error) {
    // print('[' + _app_name + '] ERROR: ' + error);
  }

  void debug(msg) {
    // print('[' + _app_name + '] DEBUG: ' + msg);
  }

  void warn(msg) {
    // print('[' + _app_name + '] WARN: ' + msg);
  }

  void failure(error) {
    throw (error);
    // var log = '[' + _app_name + '] FAILURE: ' + error;
    // print(log);
    // throw (log);
  }
}
