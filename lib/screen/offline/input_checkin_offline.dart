import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rapid_test/blocs/offline/checkin_offline/Bloc.dart';
import 'package:rapid_test/components/BuildTextField.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/utilities/Validations.dart';

class InputCheckinOffline extends StatefulWidget {
  @override
  _InputCheckinOfflineState createState() => _InputCheckinOfflineState();
}

class _InputCheckinOfflineState extends State<InputCheckinOffline> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final OfflineRepository _offlineRepository = OfflineRepository();
  CheckinOfflineBloc _checkinBloc;
  final _codeActivity = TextEditingController();
  final _codeSampleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(Dictionary.inputRegistrationCOde)),
        body: MultiBlocProvider(
          providers: [
            BlocProvider<CheckinOfflineBloc>(
                create: (BuildContext context) => _checkinBloc =
                    CheckinOfflineBloc(repository: _offlineRepository)),
          ],
          child: MultiBlocListener(
            listeners: [
              BlocListener<CheckinOfflineBloc, CheckinOfflineState>(
                  listener: (context, state) {
                if (state is CheckinOfflineFailure) {
                  var split = state.error.split('Exception:');
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) => DialogTextOnly(
                            description: split.last.toString(),
                            buttonText: Dictionary.ok,
                            onOkPressed: () {
                              Navigator.of(context)
                                  .pop(); // To close the dialog
                            },
                          ));

                  Scaffold.of(context).hideCurrentSnackBar();
                } else if (state is CheckinOfflineLoading) {
                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Theme.of(context).primaryColor,
                      content: Row(
                        children: <Widget>[
                          CircularProgressIndicator(),
                          Container(
                            margin: EdgeInsets.only(left: 15.0),
                            child: Text(Dictionary.pleaseWait),
                          )
                        ],
                      ),
                    ),
                  );
                } else if (state is CheckinOfflineLoaded) {
                  Navigator.of(context).pop();
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => DialogTextOnly(
                            description: Dictionary.checkinSuccessOffline,
                            buttonText: Dictionary.ok,
                            onOkPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context)
                                  .pop(); // To close the dialog
                            },
                          ));
                  Scaffold.of(context).hideCurrentSnackBar();
                } else if (state is GetNameLoaded) {
                  GetNameLoaded getNameLoaded = state as GetNameLoaded;
                  _buildConfirmDialog(getNameLoaded.labCode,
                      getNameLoaded.registrationCode, getNameLoaded.name);
                  Scaffold.of(context).hideCurrentSnackBar();
                } else {
                  Scaffold.of(context).hideCurrentSnackBar();
                }
              }),
            ],
            child: BlocBuilder<CheckinOfflineBloc, CheckinOfflineState>(
              builder: (
                BuildContext context,
                CheckinOfflineState state,
              ) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        BuildTextField(
                            title: Dictionary.registrationCode,
                            controller: _codeActivity,
                            hintText: Dictionary.registrationCodePlaceholder,
                            isEdit: true,
                            validation: Validations.kodeValidation,
                            textInputType: TextInputType.text),
                        SizedBox(
                          height: 10,
                        ),
                        BuildTextField(
                            title: Dictionary.labCode,
                            controller: _codeSampleController,
                            validation: Validations.kodeSampleValidation,
                            hintText: Dictionary.labCodePlaceholder,
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
                              Dictionary.checkin,
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

  _buildConfirmDialog(String labCode, registrationCode, name) {
    showDialog(
        context: context,
        builder: (BuildContext context) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.30,
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Nama Anda : '),
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
                            height: MediaQuery.of(context).size.height * 0.04,
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
                            height: MediaQuery.of(context).size.height * 0.04,
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
                                _checkinBloc.add(CheckinOfflineLoad(
                                    labCodeSample: labCode,
                                    nomorPendaftaran: registrationCode));
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

  @override
  void dispose() {
    _codeActivity.dispose();
    _codeSampleController.dispose();
    _checkinBloc.close();
    super.dispose();
  }
}
