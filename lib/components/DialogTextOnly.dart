import 'package:flutter/material.dart';
import 'package:rapid_test/constants/Dimens.dart';

class DialogTextOnly extends StatelessWidget {
  final String title, description, buttonText;
  final GestureTapCallback onOkPressed;
  final CrossAxisAlignment crossAxisAlignment;
  final AlignmentGeometry buttonAlignment;
  final Color descriptionColor, titleColor;

  DialogTextOnly(
      {Key key,
      this.title,
      this.titleColor,
      @required this.description,
      this.descriptionColor,
      @required this.buttonText,
      @required this.onOkPressed,
      this.crossAxisAlignment,
      this.buttonAlignment})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.padding),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _dialogContent(context),
    );
  }

  _dialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimens.padding),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(Dimens.padding),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // To make the card compact
        crossAxisAlignment: crossAxisAlignment != null
            ? crossAxisAlignment
            : CrossAxisAlignment.center,
        children: <Widget>[
          title != null
              ? Text(
                  title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: titleColor),
                )
              : Text(""),
          const SizedBox(height: 16),
          Text(
            description != null ? description : "",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 16, color: descriptionColor),
          ),
          const SizedBox(height: 24),
          Container(
            alignment: buttonAlignment,
            child: FlatButton(
              onPressed: onOkPressed,
              child: Text(
                buttonText,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
