import 'dart:io';

import 'package:crypto/crypto.dart';

// class StatelessServer {
//   static Future<StatelessServer> start(ServerConfig config) {

//   }
// }

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
