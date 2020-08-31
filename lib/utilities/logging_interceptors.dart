import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:rapid_test/constants/storageKeys.dart';
import 'package:rapid_test/model/TokenModel.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/utilities/http.dart';
import 'package:rapid_test/utilities/secure_store.dart';

class LoggingInterceptors extends InterceptorsWrapper {
  @override
  Future<FutureOr> onRequest(RequestOptions options) async {
    dio.interceptors.requestLock.lock();

    // get access token
    String token = await SecureStore().readValue(key: kAccessTokenKey);
    if (token != null) {
      options.headers[HttpHeaders.authorizationHeader] = 'Bearer ' + token;
    }

    dio.interceptors.requestLock.unlock();

    // logging
    print(
        "--> ${options.method != null ? options.method.toUpperCase() : 'METHOD'} ${"" + (options.baseUrl ?? "") + (options.path ?? "")}");
    print("Headers:");
    options.headers.forEach((k, v) => print('$k: $v'));
    if (options.queryParameters != null) {
      print("queryParameters:");
      options.queryParameters.forEach((k, v) => print('$k: $v'));
    }
    if (options.data != null) {
      print("Body: ${options.data}");
    }
    print(
        "--> END ${options.method != null ? options.method.toUpperCase() : 'METHOD'}");

    return options;
  }

  @override
  Future<FutureOr> onError(DioError dioError) async {
    if (dioError.response?.statusCode == 401) {
      // dio.interceptors.requestLock.lock();
      // dio.interceptors.responseLock.lock();

      // get refresh token
      String token = await SecureStore().readValue(key: kRefreshTokenKey);

      AuthenticationRepository authenticationRepository =
          AuthenticationRepository();

      TokenModel refreshToken = await authenticationRepository.refreshToken();

      if (refreshToken != null) {
        RequestOptions options = dioError.response.request;
        options.headers[HttpHeaders.authorizationHeader] = 'Bearer ' + token;
        // dio.interceptors.requestLock.unlock();
        // dio.interceptors.responseLock.unlock();

        return dio.request(options.path, options: options);
      } else {
        super.onError(dioError);
      }

      return dioError;
    }

    // logging
    print(
        "<-- ${dioError.message} ${(dioError.response?.request != null ? (dioError.response.request.baseUrl + dioError.response.request.path) : 'URL')}");
    print(
        "${dioError.response != null ? dioError.response.data : 'Unknown Error'}");
    print("<-- End error");
  }

  @override
  Future<FutureOr> onResponse(Response response) async {
    print(
        "<-- ${response.statusCode} ${(response.request != null ? (response.request.baseUrl + response.request.path) : 'URL')}");
    print("Headers:");
    response.headers?.forEach((k, v) => print('$k: $v'));
    print("Response: ${response.data}");
    print("<-- END HTTP");
  }
}
