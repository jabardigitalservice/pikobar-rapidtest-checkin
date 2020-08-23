import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rapid_test/blocs/kode_kegiatan/Bloc.dart';
import 'package:rapid_test/components/CustomAppBar.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/utilities/FormatDate.dart';

class DaftarPesertaPage extends StatefulWidget {
  KodeKegiatanModel kodeKegiatanModel;
  DaftarPesertaPage({this.kodeKegiatanModel});
  @override
  _DaftarPesertaPageState createState() => _DaftarPesertaPageState();
}

class _DaftarPesertaPageState extends State<DaftarPesertaPage> {
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  KodeKegiatanBloc _kodeKegiatanBloc;
  TextEditingController _searchController = TextEditingController();
  String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.bottomSearchAppBar(
          searchController: _searchController,
          title: 'Daftar Peserta',
          hintText: 'Cari Daftar Peserta',
          onChanged: updateSearchQuery,
          context: context),
      body: BlocProvider<KodeKegiatanBloc>(
        create: (BuildContext context) => _kodeKegiatanBloc =
            KodeKegiatanBloc(repository: _kegiatanDetailRepository)
              ..add(KodeKegiatanLoad(
                  kodeKegiatan: widget.kodeKegiatanModel.data.eventCode)),
        child: BlocListener<KodeKegiatanBloc, KodeKegiatanState>(
          listener: (context, state) {
            if (state is KodeKegiatanFailure) {
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
            } else {
              Scaffold.of(context).hideCurrentSnackBar();
            }
          },
          child: BlocBuilder<KodeKegiatanBloc, KodeKegiatanState>(
            builder: (
              BuildContext context,
              KodeKegiatanState state,
            ) {
              if (state is InitialKodeKegiatanState ||
                  state is KodeKegiatanLoading ||
                  state is KodeKegiatanFailure) {
                return Container();
              } else if (state is KodeKegiatanLoaded) {
                KodeKegiatanLoaded kodeKegiatanLoaded =
                    state as KodeKegiatanLoaded;
                List<Applicants> invitationsList;

                /// Checking search field
                if (searchQuery != null) {
                  /// Filtering data by search
                  invitationsList = kodeKegiatanLoaded
                      .kodeKegiatan.data.applicants
                      .where((test) =>
                          test.name
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()) ||
                          test.registrationCode
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()))
                      .toList();
                } else {
                  invitationsList =
                      kodeKegiatanLoaded.kodeKegiatan.data.applicants;
                }
                return SafeArea(
                    child: invitationsList.length == 0
                        ? Center(
                            child: Text('Tidak ada data daftar peserta'),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: LiquidPullToRefresh(
                                  showChildOpacityTransition: false,
                                  height: 50,
                                  color: ColorBase.green,
                                  onRefresh: () {
                                    _kodeKegiatanBloc.add(KodeKegiatanLoad(
                                        kodeKegiatan: widget
                                            .kodeKegiatanModel.data.eventCode));
                                  },
                                  child: ListView.builder(
                                    itemCount: invitationsList.length,
                                    itemBuilder: (context, i) {
                                      invitationsList.sort(
                                          (a, b) => a.name.compareTo(b.name));
                                      return Container(
                                        margin: EdgeInsets.only(
                                            bottom: 10,
                                            top: i == 0 ? 20 : 0,
                                            left: 20,
                                            right: 20),
                                        width:
                                            MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color:
                                                invitationsList[i].attendedAt ==
                                                        null
                                                    ? Colors.white
                                                    : Colors.green[100],
                                            border: Border.all(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                width: 1)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            children: <Widget>[
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(invitationsList[i].name),
                                                  Text(invitationsList[i]
                                                              .attendedAt ==
                                                          null
                                                      ? 'Tidak Hadir'
                                                      : 'Hadir'),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              SizedBox(
                                                height: 1,
                                                child: Container(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(
                                                    'Nomor Registrasi: ',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                  Text(
                                                      invitationsList[i]
                                                                  .registrationCode ==
                                                              null
                                                          ? ''
                                                          : invitationsList[i]
                                                              .registrationCode,
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(
                                                    'Kode Sampel: ',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                  Text(
                                                      invitationsList[i]
                                                                  .labCodeSample ==
                                                              null
                                                          ? ''
                                                          : invitationsList[i]
                                                              .labCodeSample,
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(
                                                    'Tanggal Checkin: ',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                  Text(
                                                      invitationsList[i]
                                                                  .attendedAt ==
                                                              null
                                                          ? ''
                                                          : unixTimeStampToDateTime(
                                                              invitationsList[i]
                                                                  .attendedAt),
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ));
              }
            },
          ),
        ),
      ),
    );
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
  }
}
