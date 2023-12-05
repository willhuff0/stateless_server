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
  final int numWorkers;

  /// The IP to bind workers to
  final InternetAddress address;

  /// The Port to bind workers to
  final int port;

  /// The max duration of a session
  final Duration tokenLifetime;

  /// The hashing algorithm used to sign identity tokens
  final Hash tokenHashAlg;

  /// The length in bytes of the random keys generated for identity tokens
  final int tokenKeyLength;

  ServerConfig({
    this.numWorkers = 8,
    InternetAddress? address,
    this.port = 8081,
    this.tokenLifetime = const Duration(hours: 8),
    this.tokenHashAlg = sha256,
    this.tokenKeyLength = 256 ~/ 8,
  }) : address = address ?? InternetAddress.anyIPv4;
}
