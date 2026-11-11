import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'package:poem_studio/core/config/app_config.dart';

@injectable
class PoemApiKeyInterceptor extends Interceptor {
  PoemApiKeyInterceptor(this._config);

  static const headerName = 'X-Poems-Key';

  final AppConfig _config;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[headerName] = _config.poemsApiKey;
    handler.next(options);
  }
}
