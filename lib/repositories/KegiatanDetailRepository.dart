import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/constants/ErrorException.dart';
import 'package:rapid_test/constants/HttpHeaders.dart';
import 'package:rapid_test/model/CheckinModel.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';

class KegiatanDetailRepository {
  Future<CheckinModel> checkNomorPendaftaran(String kode, eventCode) async {
    await Future.delayed(Duration(seconds: 1));

    final response = await http
        .post('${EndPointPath.rdt}/check',
            headers: await HttpHeaders.headers(),
            body: json
                .encode({"registration_code": kode, "event_code": eventCode}))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      CheckinModel record = CheckinModel.fromJson(data);
      print(data);
      return record;
    } else if (response.statusCode == 401) {
      throw Exception(ErrorException.unauthorizedException);
    } else if (response.statusCode == 408) {
      throw Exception(ErrorException.timeoutException);
    } else if (response.statusCode == 404) {
      throw Exception('Silahkan cek kembali nomer yang dimasukan');
    } else {
      throw Exception('Terjadi Kesalahan');
    }
  }

  Future<KodeKegiatanModel> checkKodeKegiatan(String kode) async {
    await Future.delayed(Duration(seconds: 1));

    final response = await http
        .post('${EndPointPath.rdt}/event-check',
            headers: await HttpHeaders.headers(),
            body: json.encode({"event_code": kode}))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      KodeKegiatanModel record = KodeKegiatanModel.fromJson(data);
      print(data);
      return record;
    } else if (response.statusCode == 401) {
      throw Exception(ErrorException.unauthorizedException);
    } else if (response.statusCode == 408) {
      throw Exception(ErrorException.timeoutException);
    } else if (response.statusCode == 404) {
      throw Exception('Silahkan cek kembali nomer yang dimasukan');
    } else {
      throw Exception('Terjadi Kesalahan');
    }
  }
}
