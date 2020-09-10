import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  final _codeSampleController = TextEditingController();

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
                            _codeSampleController.text = '';
                            Navigator.of(context).pop();
                            Navigator.of(context).pop(); // To close the dialog
                          },
                        ));
                Scaffold.of(context).hideCurrentSnackBar();
              }else if (state is GetNameLoaded) {
                    GetNameLoaded getNameLoaded = state as GetNameLoaded;
                    _buildConfirmDialog(
                        getNameLoaded.registrationCode,
                        getNameLoaded.labCode,
                        getNameLoaded.eventCode,
                        getNameLoaded.name);
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
                            height: 10,
                          ),
                          buildTextField(
                              title: 'Kode Sampel',
                              controller: _codeSampleController,
                              validation: Validations.kodeSampleValidation,
                              hintText: 'Masukan atau scan kode sampel',
                              isEdit: true,
                              qrIcon: true,
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
                                   _checkinBloc.add(GetNameLoad(
                                    registrationCode: _codeActivity.text,
                                    eventCode: widget.kodeKegiatanModel.data.eventCode,
                                    labCode: _codeSampleController.text));
                                }
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                
              },
            ),
          ),
        ));
  }

  _buildConfirmDialog(String registrationCode, labCode, eventCode, name) {
    showDialog(
        context: context,
        builder: (BuildContext context) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.28,
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Nama : '),
                          Expanded(
                              child: Text(name,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('No Registrasi Anda : '),
                          Expanded(
                              child: Text(registrationCode,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Kode Sample : '),
                          Expanded(
                              child: Text(labCode,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                          'Pastikan data sudah benar sebelum menekan tombol submit'),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: RaisedButton(
                              splashColor: Colors.lightGreenAccent,
                              padding: EdgeInsets.all(0.0),
                              color: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                    fontFamily: FontsFamily.productSans,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                    color: Colors.white),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.3,
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
                                _checkinBloc.add(CheckinLoad(
                                    nomorPendaftaran: registrationCode,
                                    eventCode: eventCode,
                                    labCodeSample: labCode));
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
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
      int maxLines,
      bool qrIcon = false}) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 14.0, color: Color(0xff828282)),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
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
                          borderSide: BorderSide(
                              color: Color(0xffE0E0E0), width: 1.5))),
                  keyboardType: textInputType != null
                      ? textInputType
                      : TextInputType.text,
                ),
              ),
              SizedBox(
                width: 5,
              ),
              qrIcon
                  ? Container(
                      height: 60,
                      width: 60,
                      child: RaisedButton(
                        elevation: 0,
                        color: Colors.white,
                        shape: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Color(0xffE0E0E0), width: 1.5)),
                        onPressed: () async {
                          var barcode = await BarcodeScanner.scan();
                          if (barcode.rawContent != '') {
                            setState(() {
                              controller.text = barcode.rawContent;
                            });
                          }
                        },
                        child: Icon(
                          FontAwesomeIcons.qrcode,
                          color: ColorBase.green,
                        ),
                      ),
                    )
                  : Container()
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeActivity.dispose();
    _codeSampleController.dispose();
    _checkinBloc.close();
    super.dispose();
  }
}
