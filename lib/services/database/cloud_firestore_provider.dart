import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/themes/colours.dart';

class CloudFireStoreProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Get meals
  Future getAllMeals() async {
    try {
      final menuModel = _firestore
          .collection(dotenv.env['MEALSCOLLECTION']!)
          .doc()
          .withConverter<MealItemModel>(
            fromFirestore: (snapshot, _) =>
                MealItemModel.fromJson(snapshot.data()!),
            toFirestore: (meal, _) => meal.toJson(),
          );

      return await menuModel.get();

      //  return (await menuModel.get()).data();
    } catch (exception) {
      _scaffoldMessengerKey.currentState!.showSnackBar(SnackBar(
        backgroundColor: AppColours.dark,
        content: Text("Error: $exception",
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              color: Colors.white,
              fontSize: 16.0,
            )),
        duration: const Duration(seconds: 3),
      ));
    }
  }
}
