import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/screens/search/search_screen.dart';
import 'package:yummealprep/shared_widgets/choices.dart' as choices;

class MealsScreen extends StatefulWidget {
  final String? mealType;

  const MealsScreen({
    Key? key,
    this.mealType,
  }) : super(key: key);

  @override
  State<MealsScreen> createState() => MealsScreenState();
}

class MealsScreenState extends State<MealsScreen> {
  List<MealItemModel> mealTypes = choices.mealTypes2;
  List<MealItemModel> mealTypesFilteredList = [];
  String searchQuery = '';

  final CollectionReference mealsCollection =
      FirebaseFirestore.instance.collection(dotenv.env['MEALSCOLLECTION']!);

  @override
  void initState() {
    super.initState();
    // Filter mealTypes list
    mealTypesFilteredList =
        mealTypes.where((i) => i.type == widget.mealType).toList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget searchBar() {
    return TextField(
        cursorColor: Colors.grey,
        decoration: InputDecoration(
          fillColor: Colors.white,
          filled: true,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          hintText: 'Search for ${mealTypesFilteredList.first.type!} items...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),
          prefixIcon: Container(
            padding: const EdgeInsets.all(15),
            width: 18,
            child: const Icon(Icons.search),
          ),
        ),
        onChanged: (value) => setState(() {
              searchQuery = value;
            }));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              // Image header
              Positioned.fill(
                child: SingleChildScrollView(
                  child: Stack(
                    children: <Widget>[
                      Image.asset(
                        mealTypesFilteredList.first.image!,
                        height: MediaQuery.of(context).size.height / 5,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      // Viewing container
                      Positioned(
                        top: 30,
                        right: 10,
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(10.0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6.0, horizontal: 10.0),
                              color: Colors.green,
                              child: Text(
                                'VIEWING',
                                style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.only(bottom: 10),
                              height: 70.0,
                              color: Colors.black38,
                              width: MediaQuery.of(context).size.width / 2,
                              child: Text(
                                '${mealTypesFilteredList.first.type!} Meals',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Meal item list
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      const Divider(),
                      searchBar(),
                      const Divider(),
                      MealSearchList(
                          mealType: widget.mealType, searchQuery: searchQuery),
                      const SizedBox(
                        height: 10,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Back button
          Positioned(
            top: 10.0,
            left: 2.4,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 28.0,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}
