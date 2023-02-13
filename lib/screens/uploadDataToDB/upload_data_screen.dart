import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import 'package:yummealprep/repositories/app_repository.dart';
import 'package:yummealprep/services/database/firebase_authentication.dart';
import 'package:yummealprep/shared_widgets/bottom_navbar_widget.dart';
import 'package:yummealprep/themes/colours.dart';

class DBDataUploadScreen extends StatefulWidget {
  const DBDataUploadScreen({Key? key}) : super(key: key);

  @override
  State<DBDataUploadScreen> createState() => DBDataUploadScreenState();
}

class DBDataUploadScreenState extends State<DBDataUploadScreen> {
  final FirebaseAuthentication _auth = FirebaseAuthentication();
  @override
  Widget build(BuildContext context) {
    Flushbar showFlushBar(String value) {
      return Flushbar(
        backgroundColor: AppColours.dark,
        messageText: Text(value,
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              color: Colors.white,
              fontSize: 16.0,
            )),
        icon: Icon(value.contains('success') ? Icons.check_box : Icons.close,
            size: 28.0,
            color: value.contains('success')
                ? Colors.green[300]
                : Colors.red[500]),
        leftBarIndicatorColor:
            value.contains('success') ? Colors.green[300] : Colors.red[500],
        duration: const Duration(seconds: 5),
        onStatusChanged: (status) {
          // if (status == FlushbarStatus.SHOWING && value != 'Meal added') {
          //   Future.delayed(const Duration(seconds: 3), () {
          //     Navigator.of(context).pushNamed(Constants.editProfileScreen);
          //   });
          // }
        },
      )..show(this.context);
    }

    ElevatedButton showButton(String btntext, Color btnColour) =>
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: btnColour,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)))),
          onPressed: () async {
            try {
              _auth.signsUserInAnonymously();
              debugPrint(
                  'Is current user anonymous?: ${FirebaseAuth.instance.currentUser!.isAnonymous}');
              btntext.contains('Recipes')
                  ? AppRepository().recipeData()
                  : AppRepository().mealItemsData();
              showFlushBar('Data has successfully uploaded');
            } catch (error) {
              showFlushBar(error.toString());
            }
          },
          child: Text(
            btntext,
            style: GoogleFonts.lato(color: Colors.white, fontSize: 25),
          ),
        );

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 93, 115, 155),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('DB Data Upload'),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            icon: const Icon(FontAwesome.home),
            color: Colors.white,
            onPressed: () {
              pushNewScreen(
                context,
                screen: const BottomNavBar(),
                withNavBar: true,
                pageTransitionAnimation: PageTransitionAnimation.cupertino,
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Meals Button
          showButton(
              'Upload Meals\' data', const Color.fromARGB(255, 180, 115, 17)),
          const Divider(
              indent: 60, endIndent: 60, thickness: 3, color: Colors.grey),
          // Recipe Button
          showButton(
              'Upload Recipes\' data', const Color.fromARGB(255, 13, 135, 192)),
        ],
      ),
    );
  }
}
