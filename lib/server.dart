import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:stateless_server/worker.dart';

class StatelessServer {
  final ServerConfig config;
  final WorkerLaunchArgs workerLaunchArgs;

  final List<WorkerManager> _workerManagers;

  StatelessServer._(this.config, this.workerLaunchArgs, this._workerManagers);

  static Future<StatelessServer> start({required ServerConfig config, required WorkerLaunchArgs workerLaunchArgs}) async {
    final workerManagers = await Future.wait(Iterable.generate(config.numWorkers, (index) => WorkerManager.start(workerLaunchArgs, debugName: 'Worker $index')));
    return StatelessServer._(config, workerLaunchArgs, workerManagers);
  }

  Future<void> shutdown() async {
    await Future.wait(_workerManagers.map((e) => e.shutdown()));
  }
}

class ServerConfig {
  /// The number of workers spawned to serve requests
  final int numWorkers = 8;

  /// The IP to bind workers to
  final address = InternetAddress.anyIPv4;

  /// The Port to bind workers to
  final port = 8081;

  /// The max duration of a session
  final tokenLifetime = Duration(hours: 8);

  /// The hashing algorithm used to sign identity tokens
  final tokenHashAlg = sha256;

  /// The length in bytes of the random keys generated for identity tokens
  final tokenKeyLength = 256 ~/ 8;
}
