import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rapid_test/blocs/account_profile/account_profile_bloc.dart';
import 'package:rapid_test/blocs/kode_kegiatan/Bloc.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dimens.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/kegiatan_detail.dart';
import 'package:rapid_test/utilities/Validations.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _codeActivity = TextEditingController();
  final _location = TextEditingController();

// init repositories
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();

  // init bloc
  AccountProfileBloc _accountProfileBloc;
  KodeKegiatanBloc _kodeKegiatanBloc;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    initializeDateFormatting();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Tes Masif Checkin")),
        body: MultiBlocProvider(
          providers: [
            // bloc get account user
            BlocProvider<AccountProfileBloc>(
              create: (BuildContext context) => _accountProfileBloc =
                  AccountProfileBloc(_authenticationRepository)
                    ..add(AccountProfileLoad()),
            ),

            // bloc kegiatan
            BlocProvider<KodeKegiatanBloc>(
              create: (BuildContext context) => _kodeKegiatanBloc =
                  KodeKegiatanBloc(repository: _kegiatanDetailRepository)
                    ..add(AppStart()),
            ),
          ],
          child: BlocListener<KodeKegiatanBloc, KodeKegiatanState>(
              listener: (context, state) {
                if (state is KodeKegiatanFailure) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => DialogTextOnly(
                            description: state.error.toString(),
                            buttonText: "OK",
                            onOkPressed: () {
                              Navigator.of(context)
                                  .pop(); // To close the dialog
                            },
                          ));
                  Scaffold.of(context).hideCurrentSnackBar();
                } else if (state is KodeKegiatanLoading) {
                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Theme.of(context).primaryColor,
                      content: Row(
                        children: <Widget>[
                          CircularProgressIndicator(),
                          Container(
                            margin: EdgeInsets.only(left: 15.0),
                            child: Text('Tunggu Sebentar'),
                          )
                        ],
                      ),
                      duration: Duration(seconds: 5),
                    ),
                  );
                } else if (state is KodeKegiatanLoaded) {
                  KodeKegiatanLoaded kodeKegiatanLoaded =
                      state as KodeKegiatanLoaded;
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => KegiatanPage(
                                kodeKegiatanModel:
                                    kodeKegiatanLoaded.kodeKegiatan,
                              )));
                } else {
                  Scaffold.of(context).hideCurrentSnackBar();
                }
              },
              child: _buildContent()),
        ));
  }

  _buildContent() {
    return BlocBuilder<KodeKegiatanBloc, KodeKegiatanState>(
      builder: (
        BuildContext context,
        KodeKegiatanState state,
      ) {
        if (state is InitialKodeKegiatanState ||
            state is KodeKegiatanLoading ||
            state is KodeKegiatanFailure ||
            state is KodeKegiatanLoaded ||
            state is KodeKegiatanUnauthenticated) {
          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  BlocBuilder<AccountProfileBloc, AccountProfileState>(
                    builder: (context, state) => state is AccountProfileLoading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : state is AccountProfileLoaded
                            ? Center(
                                child: Text(
                                state.user.name,
                                style: TextStyle(fontSize: 18),
                              ))
                            : Container(),
                  ),
                  SizedBox(height: 25),
                  buildTextField(
                    title: 'Kode Kegiatan',
                    controller: _codeActivity,
                    hintText: 'Masukan kode kegiatan',
                    isEdit: true,
                    validation: Validations.kodeValidation,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  buildTextField(
                    title: 'Lokasi',
                    controller: _location,
                    hintText: 'Masukan lokasi',
                    isEdit: true,
                    validation: Validations.locationValidation,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 40.0,
                    child: RaisedButton(
                      splashColor: Colors.lightGreenAccent,
                      padding: EdgeInsets.all(0.0),
                      color: ColorBase.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                            fontFamily: FontsFamily.productSans,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                            color: Colors.white),
                      ),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          FocusScope.of(context).unfocus();
                          _kodeKegiatanBloc.add(KodeKegiatanLoad(
                              kodeKegiatan: _codeActivity.text,
                              location: _location.text));
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget buildTextField(
      {String title,
      TextEditingController controller,
      String hintText,
      validation,
      TextInputType textInputType,
      TextStyle textStyle,
      bool isEdit,
      int maxLines}) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 18.0, color: Color(0xff828282)),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          TextFormField(
            maxLines: maxLines != null ? maxLines : 1,
            style: isEdit
                ? TextStyle(
                    color: Colors.black,
                  )
                : TextStyle(color: Color(0xffBDBDBD)),
            enabled: isEdit,
            validator: validation,
            textCapitalization: TextCapitalization.characters,
            controller: controller,
            decoration: InputDecoration(
                hintText: hintText,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Color(0xffE0E0E0), width: 1.5)),
                disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Color(0xffE0E0E0), width: 1.5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Color(0xffE0E0E0), width: 1.5))),
            keyboardType:
                textInputType != null ? textInputType : TextInputType.text,
          )
        ],
      ),
    );
  }
}
