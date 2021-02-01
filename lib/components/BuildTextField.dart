import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rapid_test/constants/Colors.dart';

class BuildTextField extends StatefulWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final validation;
  final TextInputType textInputType;
  final TextStyle textStyle;
  final bool isEdit;
  final int maxLines;
  final bool qrIcon;
  final TextCapitalization textCapitalization;
  final bool obsecureText;

  /// @params
  /// * [title] type String must not be null.
  /// * [hintText] type String must not be null.
  /// * [controller] type from class TextEditingController must not be null.
  /// * [validation] type from class Validation.
  /// * [textInputType] type from class TextInputType.
  /// * [textStyle] type from class TextStyle.
  /// * [isEdit] type bool.
  BuildTextField(
      {this.title,
      this.hintText,
      this.controller,
      this.validation,
      this.textInputType,
      this.textStyle,
      this.isEdit,
      this.maxLines,
      this.qrIcon = false,
      this.textCapitalization = TextCapitalization.characters,
      this.obsecureText = false});

  @override
  _BuildTextFieldState createState() => _BuildTextFieldState();
}

class _BuildTextFieldState extends State<BuildTextField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                widget.title,
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
                  maxLines: widget.maxLines != null ? widget.maxLines : 1,
                  style: widget.isEdit
                      ? TextStyle(
                          color: Colors.black,
                        )
                      : TextStyle(color: Color(0xffBDBDBD)),
                  enabled: widget.isEdit,
                  validator: widget.validation,
                  textCapitalization: widget.textCapitalization,
                  obscureText: widget.obsecureText,
                  controller: widget.controller,
                  decoration: InputDecoration(
                      hintText: widget.hintText,
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
                  keyboardType: widget.textInputType != null
                      ? widget.textInputType
                      : TextInputType.text,
                ),
              ),
              SizedBox(
                width: 5,
              ),
              widget.qrIcon
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
                              widget.controller.text = barcode.rawContent;
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
}
