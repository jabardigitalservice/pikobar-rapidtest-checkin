import 'package:flutter/material.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/Dimens.dart';

class DialogRequestPermission extends StatelessWidget {
  final String title, description, buttonText;
  final Image image;
  final Icon icon;
  final GestureTapCallback onOkPressed;
  final GestureTapCallback onCancelPressed;

  DialogRequestPermission(
      {Key key,
      this.title,
      @required this.description,
      this.buttonText,
      this.image,
      this.icon,
      @required this.onOkPressed,
      this.onCancelPressed})
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
    return Stack(
      children: <Widget>[
        //bottom card part,
        _bottomCard(context),

        //top circular image part,
        _circularImage(),
      ],
    );
  }

  _bottomCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: Dimens.avatarRadius + Dimens.padding,
        bottom: Dimens.padding,
        left: Dimens.padding,
        right: Dimens.padding,
      ),
      margin: const EdgeInsets.only(top: Dimens.avatarRadius),
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
        children: <Widget>[
          Text(
            description,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              FlatButton(
                onPressed: onCancelPressed != null
                    ? onCancelPressed
                    : () {
                        Navigator.of(context).pop(); // To close the dialog
                      },
                child: Text(
                  Dictionary.later,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
              ),
              FlatButton(
                onPressed: onOkPressed,
                child: Text(
                  Dictionary.next,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: ColorBase.green),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  _circularImage() {
    return Positioned(
      left: Dimens.padding,
      right: Dimens.padding,
      child: CircleAvatar(
          backgroundColor: ColorBase.green,
          radius: Dimens.avatarRadius,
          child: Container(
              width: 50, height: 50, child: image != null ? image : icon)),
    );
  }
}
