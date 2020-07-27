import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rapid_test/blocs/checkin/Bloc.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/screen/kegiatan_detail.dart';
import 'package:rapid_test/utilities/Validations.dart';

class InputNomor extends StatefulWidget {
  KodeKegiatanModel kodeKegiatanModel;
  InputNomor({this.kodeKegiatanModel});
  @override
  _InputNomorState createState() => _InputNomorState();
}

class _InputNomorState extends State<InputNomor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  CheckinBloc _checkinBloc;
  final _codeActivity = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Input Nomor Pendaftaran")),
        body: BlocProvider<CheckinBloc>(
      create: (BuildContext context) =>
          _checkinBloc = CheckinBloc(repository: _kegiatanDetailRepository),
      child: BlocListener<CheckinBloc, CheckinState>(
        listener: (context, state) {
          if (state is CheckinFailure) {
            showDialog(
                context: context,
                builder: (BuildContext context) => DialogTextOnly(
                      description: state.error.toString(),
                      buttonText: "OK",
                      onOkPressed: () {
                        Navigator.of(context).pop(); // To close the dialog
                      },
                    ));
            Scaffold.of(context).hideCurrentSnackBar();
          } else if (state is CheckinLoading) {
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
          } else if (state is CheckinLoaded) {
            CheckinLoaded checkinLoaded = state as CheckinLoaded;
            showDialog(
                context: context,
                builder: (BuildContext context) => DialogTextOnly(
                      description: checkinLoaded.checkinModel.data.name +
                          ' berhasil checkin',
                      buttonText: "OK",
                      onOkPressed: () {
                        _codeActivity.text = '';
                        Navigator.of(context).pop(); // To close the dialog
                      },
                    ));
            Scaffold.of(context).hideCurrentSnackBar();
          } else {
            Scaffold.of(context).hideCurrentSnackBar();
          }
        },
        child: BlocBuilder<CheckinBloc, CheckinState>(
          builder: (
            BuildContext context,
            CheckinState state,
          ) {
            if (state is InitialCheckinState ||
                state is CheckinLoading ||
                state is CheckinFailure ||
                state is CheckinLoaded) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      buildTextField(
                          title: 'Nomor Pendaftaran',
                          controller: _codeActivity,
                          hintText: 'Masukan nomor pendaftaran',
                          isEdit: true,
                          validation: Validations.kodeValidation,
                          textInputType: TextInputType.text),
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
                            'Checkin',
                            style: TextStyle(
                                fontFamily: FontsFamily.productSans,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                                color: Colors.white),
                          ),
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              FocusScope.of(context).unfocus();
                              _checkinBloc.add(CheckinLoad(
                                  nomorPendaftaran: _codeActivity.text,
                                  eventCode:
                                      widget.kodeKegiatanModel.data.eventCode));
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      ),
    ));
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

  @override
  void dispose() {
    _codeActivity.dispose();
    _checkinBloc.close();
    super.dispose();
  }
}
