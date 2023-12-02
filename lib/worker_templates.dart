import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:stateless_server/identity_token.dart';
import 'package:stateless_server/worker.dart';
import 'package:uuid/uuid.dart';

class HttpWorker implements Worker {
  final HttpServer _server;

  HttpWorker._(this._server, Router router) {
    router.all('/', _handler);
  }

  static Future<Worker> start(WorkerLaunchArgs args, {String? debugName}) async {
    final router = Router();
    final handler = Pipeline().addMiddleware(logRequests()).addHandler(router.call);
    final server = await serve(handler, args.config.address, args.config.port, shared: true);

    return HttpWorker._(server, router);
  }

  FutureOr<Response> _handler(Request request) {
    return Response.ok('Hello, World!');
  }

  @override
  Future shutdown() async {
    await _server.close();
  }
}

class HttpWorkerWithAuthentication implements Worker {
  final HttpServer _server;

  final IdentityTokenAuthority _identityTokenAuthority;

  HttpWorkerWithAuthentication._(this._server, this._identityTokenAuthority, Router router) {
    router
      ..all('/', _handler)
      ..put('/login', _loginHandler)
      ..get('/uid', _getUsernameHandler);
  }

  static Future<Worker> start(WorkerLaunchArgs args, {String? debugName}) async {
    if (args is! WorkerLaunchArgsWithAuthentication) throw Exception('HttpWorkerWithAuthentication must be started with WorkerLaunchArgsWithAuthentication');

    final identityTokenAuthority = IdentityTokenAuthority.initialize(args.config, args.privateKey);

    final router = Router();
    final handler = Pipeline().addMiddleware(logRequests(logger: debugName != null ? (message, isError) => print('[$debugName] $message') : null)).addHandler(router.call);
    final server = await serve(handler, args.config.address, args.config.port, shared: true);

    return HttpWorkerWithAuthentication._(server, identityTokenAuthority, router);
  }

  FutureOr<Response> _handler(Request request) {
    return Response.ok('Hello, World!');
  }

  FutureOr<Response> _loginHandler(Request request) {
    final userId = Uuid().v4();
    final clientAddress = (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)?.remoteAddress;
    final identityToken = IdentityToken(userId, clientAddress);
    final encodedToken = _identityTokenAuthority.signAndEncodeToken(identityToken);

    return Response.ok('Success', headers: {'token': encodedToken});
  }

  FutureOr<Response> _getUsernameHandler(Request request) {
    final encodedToken = request.headers['token'];
    if (encodedToken == null) return Response.forbidden('Authentication error');
    final identityToken = _identityTokenAuthority.verifyAndDecodeToken(encodedToken);
    if (identityToken == null) return Response.forbidden('Authentication error');

    return Response.ok('Your userId is: ${identityToken.userId}');
  }

  @override
  Future shutdown() async {
    await _server.close();
  }
}
