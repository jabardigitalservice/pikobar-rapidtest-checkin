import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:rapid_test/constants/ErrorException.dart';
import 'package:rapid_test/constants/SharedPreferenceKey.dart';
import 'package:rapid_test/constants/storageKeys.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/utilities/http.dart';
import 'package:rapid_test/utilities/secure_store.dart';

import 'SharedPreferences.dart';

class LoggingInterceptors extends InterceptorsWrapper {
  @override
  Future<FutureOr> onRequest(RequestOptions options) async {
    KegiatanDetailRepository kegiatanDetailRepository =
        KegiatanDetailRepository();

    /// get data login from shared preference
    bool isFromLogin = await kegiatanDetailRepository.getIsFromLogin();
    print(isFromLogin);

    /// check user is login
    if (isFromLogin) {
      ///--- user from login----
      AuthenticationRepository authenticationRepository =
          AuthenticationRepository();

      /// get refresh token status from shared preference
      bool isGetRefreshToken =
          await Preferences.getDataBool(kIsRefresh) ?? false;
      print('Mengambil refresh token : $isGetRefreshToken');

      /// check refresh token status
      if (isGetRefreshToken) {
        ///--- bypass refresh token ---
        dio.interceptors.requestLock.lock();

        /// read token from secure storage
        String token = await SecureStore().readValue(key: kAccessTokenKey);
        if (token != null) {
          /// add token to header
          options.headers[HttpHeaders.authorizationHeader] = 'Bearer ' + token;
        }
        dio.interceptors.requestLock.unlock();
      } else {
        ///--- refresh token execute ---
        dio.interceptors.requestLock.lock();

        /// read token from secure storage
        bool hasToken = await authenticationRepository.hasTokens();

        print('Sudah login :$hasToken');
        if (hasToken) {
          ///--- token available ---
          /// check token expire time
          if (await authenticationRepository.isTokenExpired()) {
            ///--- token expired ---
            print('expired');
            dio.interceptors.requestLock.unlock();

            // await SecureStore().deleteAll();

            // navService.pushReplacementNamed(kLoginRoute,
            //     args: 'Session Anda habis, silahkan Login kembali');
            throw Exception('Token Expired');
          }
        }

        /// read token from secure storage
        String token = await SecureStore().readValue(key: kAccessTokenKey);
        if (token != null) {
          /// add token to header
          options.headers[HttpHeaders.authorizationHeader] = 'Bearer ' + token;
        }
        dio.interceptors.requestLock.unlock();
      }
    }

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
    // logging
    print(
        "<-- ${dioError.message} ${(dioError.response?.request != null ? (dioError.response.request.baseUrl + dioError.response.request.path) : 'URL')}");
    print(
        "${dioError.response != null ? dioError.response.data : 'Unknown Error'}");
    print("<-- End error");
    AuthenticationRepository authenticationRepository =
        AuthenticationRepository();
    await Preferences.setDataBool(kIsRefresh, false);

    // if (dioError.response?.statusCode == 401) {
    // dio.interceptors.requestLock.lock();
    // dio.interceptors.responseLock.lock();

    // AuthenticationRepository authenticationRepository =
    //     AuthenticationRepository();

    // TokenModel refreshToken = await authenticationRepository.refreshToken();

    // if (refreshToken != null) {
    //   // get new access token
    //   String token = await SecureStore().readValue(key: kAccessTokenKey);
    //   RequestOptions options = dioError.response.request;
    //   options.headers[HttpHeaders.authorizationHeader] = 'Bearer ' + token;

    //   // dio.interceptors.requestLock.unlock();
    //   // dio.interceptors.responseLock.unlock();

    //   return dio.request(options.path, options: options);
    // } else {
    // return dioError;
    // }
    // }
    if (dioError.response?.statusCode == 401) {
      // final data = dioError.response.data;
      // throw Exception(data['error_description']);
      throw Exception(ErrorException.unauthorizedException);
    } else if (dioError.response?.statusCode == 408) {
      throw Exception(ErrorException.timeoutException);
    } else if (dioError.response?.statusCode == 404) {
      throw Exception(ErrorException.notFoundEvent);
    } else if (dioError.response?.statusCode == 422) {
      final data = dioError.response.data;
      throw Exception(data['message']);
    } else {
      throw Exception(dioError.message);
    }

    // if (dioError.response?.statusCode == 400) {
    //   final response = dioError.response?.data;
    //   final errorMessage = response['error'];

    //   if (errorMessage == ErrorException.invalidGrant) {
    //     // delete all storages
    //     await SecureStore().deleteAll();

    //     navService.pushNamed(kLoginRoute,
    //         args: 'Session Anda habis, silahkan Login kembali');
    //   }
    // }
  }

  @override
  Future<FutureOr> onResponse(Response response) async {
    print(
        "<-- ${response.statusCode} ${(response.request != null ? (response.request.baseUrl + response.request.path) : 'URL')}");
    // get respon header
    // print("Headers:");
    // response.headers?.forEach((k, v) => print('$k: $v'));
    print("Response: ${response.data}");
    print("<-- END HTTP");
  }
}
