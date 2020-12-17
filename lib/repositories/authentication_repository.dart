import 'package:dio/dio.dart';
import 'package:rapid_test/config/FlavorConfig.dart';
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/constants/storageKeys.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/model/TokenModel.dart';
import 'package:rapid_test/model/UserModel.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'package:rapid_test/utilities/http.dart';
import 'package:rapid_test/utilities/secure_store.dart';
import 'dart:convert';


enum TokenType { ACCESS_TOKEN, REFRESH_TOKEN }

class AuthenticationRepository {
  Response response;
  Future<TokenModel> loginUser(String username, String password) async {
    try {
      final loginBody = {
        "grant_type": "password",
        "client_id": FlavorConfig.instance.values.clientId,
        "username": username,
        "password": password
      };
      response = await dio.post(FlavorConfig.instance.values.loginUrl,
          data: loginBody,
          options: Options(contentType: Headers.formUrlEncodedContentType));

      final data = response.data;
      TokenModel record = TokenModel.fromJson(data);

      // delete all storages
      await SecureStore().deleteAll();

      // insert token to secure storage
      await SecureStore()
          .writeValue(key: kAccessTokenKey, value: record.accessToken);
      await SecureStore()
          .writeValue(key: kRefreshTokenKey, value: record.refreshToken);

      return record;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<TokenModel> refreshToken() async {
    print('--- Mengambil Access Token Yang Baru ---');
    await Preferences.setDataBool('isRefresh', true);
    dio.interceptors.requestLock.unlock();
    // get refresh token
    String refreshToken = await SecureStore().readValue(key: kRefreshTokenKey);
    try {
      final loginBody = {
        "grant_type": "refresh_token",
        "client_id": FlavorConfig.instance.values.clientId,
        "refresh_token": refreshToken
      };
      response = await dio.post(FlavorConfig.instance.values.loginUrl,
          data: loginBody,
          options: Options(contentType: Headers.formUrlEncodedContentType));
      final data = response.data;

      print('Token Baru $data');

      TokenModel record = TokenModel.fromJson(data);

      // replace token to secure storage
      await SecureStore()
          .writeValue(key: kAccessTokenKey, value: record.accessToken);
      await SecureStore()
          .writeValue(key: kRefreshTokenKey, value: record.refreshToken);
      await Preferences.setDataBool('isRefresh', false);
      return record;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<UserModel> userInfo() async {
    try {
      response = await dio.get(EndPointPath.userInfo);
      final data = response.data;
      UserModel record = UserModel.fromJson(data);
      return record;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> deleteTokens() async {
    await SecureStore().deleteAll();
    return;
  }

  Future<bool> hasTokens() async {
    await Future.delayed(Duration(seconds: 1));

    return await SecureStore().readValue(key: kAccessTokenKey) != null;
  }

  /// Decode access token
  static Future<Map<String, dynamic>> decodeToken(TokenType type) async {
    final token = type == TokenType.ACCESS_TOKEN
        ? await SecureStore().readValue(key: kAccessTokenKey)
        : await SecureStore().readValue(key: kRefreshTokenKey);
    var arrToken = token.split('.');
    String payloadToken =
        utf8.decode(base64.decode(base64.normalize(arrToken[1])));
    print(jsonDecode(payloadToken)['aud']);
    return jsonDecode(payloadToken);
  }

  /// Check if the token has expired
  ///
  /// If the access token has expired, perform refresh token.
  ///
  /// If the refresh token has expired, send an exception.
  Future<bool> isTokenExpired() async {
    print('--- Mengecek Token Expired Atau Tidak ----');
    return await decodeToken(TokenType.ACCESS_TOKEN)
        .then((value) =>
            DateTime.fromMillisecondsSinceEpoch(value['exp'] * 1000)
                .difference(DateTime.now())
                .isNegative)
        .then((isAccessTokenExpired) async {
      print('Access token expired : $isAccessTokenExpired');
      if (isAccessTokenExpired) {
        return await decodeToken(TokenType.REFRESH_TOKEN)
            .then((value) =>
                DateTime.fromMillisecondsSinceEpoch(value['exp'] * 1000)
                    .difference(DateTime.now())
                    .isNegative)
            .then((isRefreshTokenExpired) async {
          print('Refresh token expired : $isRefreshTokenExpired');

          if (isRefreshTokenExpired) {
            return true;
          } else {
            return await AuthenticationRepository()
                .refreshToken()
                .then((_) => false);
          }
        });
      } else {
        return false;
      }
    });
  }

  Future<bool> isAccessGranted() async {
    print('--- Mengecek Hak Akses ----');
    return await decodeToken(TokenType.ACCESS_TOKEN)
        .then((value) => value['aud'].toString().contains(Environment.audKey))
        .then((isGranted) async {
      print('Hak Akses : $isGranted');
      if (isGranted) {
        return true;
      } else {
        return false;
      }
    });
  }
}
