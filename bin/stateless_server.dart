import 'package:stateless_server/identity_token.dart';
import 'package:stateless_server/server.dart';
import 'package:stateless_server/worker.dart';
import 'package:stateless_server/worker_templates.dart';

void main(List<String> arguments) async {
  final config = ServerConfig();
  final workerLaunchArgs = WorkerLaunchArgsWithAuthentication(
    start: HttpWorkerWithAuthentication.start,
    config: config,
    privateKey: generateSecureRandomKey(config.tokenKeyLength),
  );
  await StatelessServer.start(config: config, workerLaunchArgs: workerLaunchArgs);
}
