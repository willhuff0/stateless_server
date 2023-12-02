import 'package:stateless_server/identity_token.dart';
import 'package:stateless_server/server.dart';
import 'package:stateless_server/worker.dart';
import 'package:stateless_server/worker_templates.dart';

void main(List<String> arguments) async {
  final config = ServerConfig();
  final args = WorkerLaunchArgsWithAuthentication(
    start: HttpWorkerWithAuthentication.start,
    config: config,
    privateKey: makeSecureRandomKey(config.tokenKeyLength),
  );
  final workers = await Future.wait(Iterable.generate(config.numWorkers, (index) => WorkerManager.start(args, debugName: 'Worker $index')));

  while (true) {
    await Future.delayed(Duration(days: 1));
  }
}
