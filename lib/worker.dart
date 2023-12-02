import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:stateless_server/server.dart';

class WorkerManager {
  final Isolate _isolate;
  final Stream<dynamic> _fromIsolatePort;
  final SendPort _toIsolatePort;

  late final StreamSubscription _fromIsolateSubscription;

  WorkerManager._(this._isolate, this._fromIsolatePort, this._toIsolatePort) {
    _fromIsolateSubscription = _fromIsolatePort.listen((message) {});
  }

  static Future<WorkerManager> start(WorkerLaunchArgs args, {String? debugName}) async {
    final fromIsolatePort = ReceivePort();
    final fromIsolatePortBroadcast = fromIsolatePort.asBroadcastStream();
    final isolate = await Isolate.spawn<(SendPort, WorkerLaunchArgs, String?)>(
      (message) => WorkerIsolate.spawn(message.$1, message.$2, debugName: message.$3),
      (fromIsolatePort.sendPort, args, debugName),
      debugName: debugName,
    );
    final toIsolatePort = await fromIsolatePortBroadcast.first;
    return WorkerManager._(isolate, fromIsolatePortBroadcast, toIsolatePort);
  }

  Future<void> shutdown() async {
    _toIsolatePort.send('shutdown');
  }
}

class WorkerIsolate {
  final Worker _worker;
  final ReceivePort _fromManagerPort;
  final SendPort _toManagerPort;

  late final StreamSubscription _fromManagerSubscription;

  WorkerIsolate._(this._worker, this._fromManagerPort, this._toManagerPort) {
    _fromManagerSubscription = _fromManagerPort.listen((message) {
      switch (message) {
        case 'shutdown':
          _shutdown();
          break;
      }
    });
  }

  static Future<WorkerIsolate> spawn(SendPort toManagerPort, WorkerLaunchArgs args, {String? debugName}) async {
    final fromManagerPort = ReceivePort();
    toManagerPort.send(fromManagerPort.sendPort);

    final worker = await args.start(args, debugName: debugName);

    return WorkerIsolate._(worker, fromManagerPort, toManagerPort);
  }

  Future<void> _shutdown() async {
    _worker.shutdown();
    _fromManagerSubscription.cancel();
  }
}

abstract interface class Worker {
  Future<void> shutdown();
}

class WorkerLaunchArgs {
  Future<Worker> Function(WorkerLaunchArgs args, {String? debugName}) start;
  final ServerConfig config;

  WorkerLaunchArgs({required this.start, required this.config});
}

class WorkerLaunchArgsWithAuthentication extends WorkerLaunchArgs {
  final Uint8List privateKey;

  WorkerLaunchArgsWithAuthentication({required super.start, required super.config, required this.privateKey});
}
