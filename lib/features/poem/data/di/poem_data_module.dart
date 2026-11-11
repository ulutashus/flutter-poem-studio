import 'package:dio/dio.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

import 'package:poem_studio/core/config/app_config.dart';
import 'package:poem_studio/core/network/retry_interceptor.dart';
import 'package:poem_studio/features/poem/data/datasources/local/poem_database.dart';
import 'package:poem_studio/features/poem/data/datasources/remote/poem_api_key_interceptor.dart';
import 'package:poem_studio/features/poem/data/datasources/remote/poem_remote_datasource.dart';

const poemsDio = Named('poemsDio');

@module
abstract class PoemDataModule {
  @poemsDio
  @LazySingleton(dispose: closeDio)
  Dio dio(AppConfig config, PoemApiKeyInterceptor apiKeyInterceptor) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.poemsBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
      ),
    );
    return dio
      ..interceptors.addAll([apiKeyInterceptor, RetryInterceptor(dio: dio)]);
  }

  @lazySingleton
  PoemRemoteDataSource poemRemoteDataSource(@poemsDio Dio dio) =>
      PoemRemoteDataSource(dio);

  @LazySingleton(dispose: closePoemDatabase)
  PoemDatabase poemDatabase() => PoemDatabase(
    driftDatabase(
      name: 'poems',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );
}

void closeDio(Dio dio) => dio.close();

Future<void> closePoemDatabase(PoemDatabase db) => db.close();
