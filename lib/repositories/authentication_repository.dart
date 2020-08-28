import 'package:dio/dio.dart';
import 'package:rapid_test/model/TokenModel.dart';
import 'package:rapid_test/model/UserModel.dart';
import 'package:rapid_test/utilities/http.dart';

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

      response = await dio.post(
          "https://keycloak.digitalservice.id/auth/realms/jabarprov/protocol/openid-connect/token",
          data: loginBody,
          options: Options(contentType: Headers.formUrlEncodedContentType));
      final data = response.data;
      TokenModel record = TokenModel.fromJson(data);
      return record;
    } catch (e) {
      print(e);
      throw Exception('Terjadi Kesalahan');
    }
  }

  Future<UserModel> userInfo() async {
    try {
      response = await dio.post(
          "https://keycloak.digitalservice.id/auth/realms/jabarprov/protocol/openid-connect/token",
          options: Options(contentType: Headers.formUrlEncodedContentType));
      final data = response.data;
      UserModel record = UserModel.fromJson(data);
      return record;
    } catch (e) {
      print(e);
      throw Exception('Terjadi Kesalahan');
    }
  }
}
