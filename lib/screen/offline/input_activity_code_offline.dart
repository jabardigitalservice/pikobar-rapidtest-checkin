import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rapid_test/blocs/offline/event_code/Bloc.dart';
import 'package:rapid_test/components/BuildTextField.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/screen/offline/detail_activity_offline.dart';
import 'package:rapid_test/utilities/Validations.dart';

class InputActivityCodeOffline extends StatefulWidget {
  @override
  _InputActivityCodeOfflineState createState() =>
      _InputActivityCodeOfflineState();
}

class _InputActivityCodeOfflineState extends State<InputActivityCodeOffline> {
  final _codeActivity = TextEditingController();
  final _location = TextEditingController();

// init repositories

  final OfflineRepository _offlineRepository = OfflineRepository();

  // init bloc

  EventCodeBloc _eventCodeBloc;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    initializeDateFormatting();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(Dictionary.testMasifOffline)),
        body: MultiBlocProvider(
          providers: [
            // bloc kegiatan
            BlocProvider<EventCodeBloc>(
              create: (BuildContext context) => _eventCodeBloc =
                  EventCodeBloc(repository: _offlineRepository),
            ),
          ],
          child: BlocListener<EventCodeBloc, EventCodeState>(
              listener: (context, state) {
                if (state is EventCodeFailure) {
                  var split = state.error.split('Exception:');
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => DialogTextOnly(
                          description: split.last.toString(),
                          buttonText: Dictionary.ok,
                          onOkPressed: () {
                            Navigator.of(context).pop(); // To close the dialog
                          }));

                  Scaffold.of(context).hideCurrentSnackBar();
                } else if (state is EventCodeLoading) {
                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      duration: Duration(minutes: 1),
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
                } else if (state is EventCodeLoaded) {
                  Scaffold.of(context).hideCurrentSnackBar();
                  EventCodeLoaded eventCodeLoaded = state as EventCodeLoaded;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ActivityOfflinePage(
                              eventCodeLoaded.eventCode,
                              eventCodeLoaded.location)));
                } else {
                  Scaffold.of(context).hideCurrentSnackBar();
                }
              },
              child: _buildContent()),
        ));
  }

  _buildContent() {
    return BlocBuilder<EventCodeBloc, EventCodeState>(
      builder: (
        BuildContext context,
        EventCodeState state,
      ) {
        if (state is InitialEventCodeState ||
            state is EventCodeLoading ||
            state is EventCodeFailure ||
            state is EventCodeLoaded ||
            state is EventCodeUnauthenticated) {
          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  BuildTextField(
                    title: Dictionary.activityCode,
                    controller: _codeActivity,
                    hintText: Dictionary.activityCodePlaceholder,
                    isEdit: true,
                    validation: Validations.kodeValidation,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  BuildTextField(
                    title: Dictionary.location,
                    controller: _location,
                    hintText: Dictionary.locationPlaceholder,
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
                        Dictionary.submit,
                        style: TextStyle(
                            fontFamily: FontsFamily.productSans,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                            color: Colors.white),
                      ),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          FocusScope.of(context).unfocus();
                          _eventCodeBloc.add(EventCodeLoad(
                              eventCode: _codeActivity.text,
                              location: _location.text));
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  // FlatButton(
                  //     onPressed: () {
                  //       Navigator.pushReplacement(
                  //           context,
                  //           MaterialPageRoute(
                  //               builder: (context) => LoginScreen()));
                  //     },
                  //     child: Center(
                  //       child: Text(
                  //         'Kembali Ke Login',
                  //         style: TextStyle(color: Colors.blue),
                  //       ),
                  //     ))
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
