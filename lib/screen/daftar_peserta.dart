import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rapid_test/blocs/kode_kegiatan/Bloc.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daftar Peserta")),
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
                return SafeArea(
                    child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: kodeKegiatanLoaded
                              .kodeKegiatan.data.applicants.length ==
                          0
                      ? Center(
                          child: Text('Tidak ada data daftar peserta'),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: ListView.builder(
                                itemCount: kodeKegiatanLoaded
                                    .kodeKegiatan.data.applicants.length,
                                itemBuilder: (context, i) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 10),
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                        color: kodeKegiatanLoaded
                                                    .kodeKegiatan
                                                    .data
                                                    .applicants[i]
                                                    .attendedAt ==
                                                null
                                            ? Colors.white
                                            : Colors.green[100],
                                        border: Border.all(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 1)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text(kodeKegiatanLoaded.kodeKegiatan
                                              .data.applicants[i].name),
                                          Text(kodeKegiatanLoaded
                                                      .kodeKegiatan
                                                      .data
                                                      .applicants[i]
                                                      .attendedAt ==
                                                  null
                                              ? 'Tidak Hadir'
                                              : 'Hadir'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ));
              }
            },
          ),
        ),
      ),
    );
  }
}
