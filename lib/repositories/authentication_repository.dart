import 'package:dio/dio.dart';
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/constants/storageKeys.dart';
import 'package:rapid_test/model/TokenModel.dart';
import 'package:rapid_test/model/UserModel.dart';
import 'package:rapid_test/utilities/http.dart';
import 'package:rapid_test/utilities/secure_store.dart';

class AuthenticationRepository {
  Response response;
  Future<TokenModel> loginUser(String username, String password) async {
    try {
      final loginBody = {
        "grant_type": "password",
        "client_id": "tes-masif-checkin",
        "username": username,
        "password": password
      };

      response = await dio.post(EndPointPath.authToken,
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
      throw Exception('Terjadi Kesalahan');
    }
  }

  Future<TokenModel> refreshToken() async {
    // add token
    String refreshToken = await SecureStore().readValue(key: kRefreshTokenKey);

    try {
      final loginBody = {
        "grant_type": "refresh_token",
        "client_id": "tes-masif-checkin",
        "refresh_token": refreshToken
      };

      response = await dio.post(EndPointPath.authToken,
          data: loginBody,
          options: Options(contentType: Headers.formUrlEncodedContentType));

      final data = response.data;
      TokenModel record = TokenModel.fromJson(data);

      // replace token to secure storage
      await SecureStore()
          .writeValue(key: kAccessTokenKey, value: record.accessToken);

      return record;
    } catch (e) {
      throw Exception('Terjadi Kesalahan');
    }
  }

  Future<UserModel> userInfo() async {
    try {
      response = await dio.get(EndPointPath.userInfo);
      final data = response.data;
      UserModel record = UserModel.fromJson(data);
      return record;
    } catch (e) {
      throw Exception('Terjadi Kesalahan');
    }
  }
}
