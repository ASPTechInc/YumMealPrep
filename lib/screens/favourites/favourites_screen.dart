import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/models/recipe_model.dart';
import 'package:yummealprep/screens/meals/meal_details_screen.dart';
import 'package:yummealprep/screens/recipes/recipe_details_screen.dart';
import 'package:yummealprep/themes/colours.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/ui_helpers.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<FavouritesScreen> createState() => MealItemCardState();
}

class MealItemCardState extends State<FavouritesScreen> {
  String favouritesType = 'Recipes';
  bool isFavouriteType = true;

  Future<void> removeItemFromFavourites(itemID) async {
    // setState(() {})); - refreshes/reloads the screen when an item is deleted
    if (isFavouriteType) {
      return await FirebaseFirestore.instance
          .collection(dotenv.env['RECIPESCOLLECTION']!)
          .doc(itemID)
          .update({'isRecipeLiked': false}).then((value) => setState(() {}));
    } else {
      return await FirebaseFirestore.instance
          .collection(dotenv.env['MEALSCOLLECTION']!)
          .doc(itemID)
          .update({'isMealLiked': false}).then((value) => setState(() {}));
    }
  }

  AnimatedToggleSwitch toggleSwitch() => AnimatedToggleSwitch<bool>.dual(
        current: isFavouriteType,
        first: false,
        second: true,
        dif: 50.0,
        borderColor: Colors.transparent,
        borderWidth: 5.0,
        height: 55,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1.5),
          ),
        ],
        onChanged: (b) => setState(() {
          isFavouriteType = b;
          isFavouriteType
              ? favouritesType = 'Recipes'
              : favouritesType = 'Meals';
        }),
        colorBuilder: (b) => b ? Colors.blueAccent : Colors.deepOrange,
        iconBuilder: (value) =>
            value ? const Icon(Icons.list) : const Icon(Icons.restaurant_menu),
        textBuilder: (value) => value
            ? Center(
                child: Text(
                  'Recipes',
                  style: GoogleFonts.lato(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              )
            : Center(
                child: Text(
                  'Meals',
                  style: GoogleFonts.lato(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
      );

  @override
  void initState() {
    super.initState();
    // favouritesType = 'Recipes';
  }

  @override
  Widget build(BuildContext context) {
    void navigateToDetailsScreen(data) {
      isFavouriteType
          ? pushNewScreen(
              context,
              screen: RecipeDetailsScreen(recipes: data),
              withNavBar: true,
              pageTransitionAnimation: PageTransitionAnimation.cupertino,
            )
          : pushNewScreen(
              context,
              screen: MealDetailsScreen(meals: data),
              withNavBar: true,
              pageTransitionAnimation: PageTransitionAnimation.cupertino,
            );
    }

    Dismissible buildContent(data) => Dismissible(
          key: Key(data!.id!),
          // Swipe from right to left to remove item from favourites
          direction: DismissDirection.endToStart,
          background: Container(
              margin: const EdgeInsets.only(left: 10),
              alignment: Alignment.centerRight,
              color: Colors.red,
              child: Container(
                  margin: const EdgeInsets.only(right: 50),
                  child: const Text('Remove',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)))),
          onDismissed: (direction) => removeItemFromFavourites(data!.id!),
          child: GestureDetector(
            onTap: () => navigateToDetailsScreen(data),
            child: Container(
              margin: const EdgeInsets.all(10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.white,
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 2.0,
                        )
                      ],
                    ),
                    child: Image.network(
                      data!.image!,
                      height: 80.0,
                      width: 80.0,
                      fit: BoxFit.fill,
                    ),
                  ),
                  UIHelper.horizontalSpaceSmall(),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          data!.name!,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(fontSize: 15.0),
                        ),
                        Text(data!.description!,
                            maxLines: 3,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(
                                    color: Colors.grey[600], fontSize: 13.5)),
                        UIHelper.verticalSpaceSmall(),
                        Row(
                          children: <Widget>[
                            isFavouriteType
                                ? Icon(
                                    Icons.favorite,
                                    size: 14.0,
                                    color: data!.isRecipeLiked!
                                        ? Colors.red[800]
                                        : Colors.grey[600],
                                  )
                                : Icon(
                                    Icons.favorite,
                                    size: 14.0,
                                    color: data!.isMealLiked!
                                        ? Colors.red[800]
                                        : Colors.grey[600],
                                  )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: UIHelper.openDrawer(context),
      appBar: AppBar(
        // backgroundColor: const Color(0x44000000),
        shadowColor: Colors.transparent,

        centerTitle: true,
        title: toggleSwitch(),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: isFavouriteType
              ? FirebaseFirestore.instance
                  .collection(dotenv.env['RECIPESCOLLECTION']!)
                  .where('isRecipeLiked', isEqualTo: true)
                  .orderBy('name')
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection(dotenv.env['MEALSCOLLECTION']!)
                  .where('isMealLiked', isEqualTo: true)
                  .orderBy('name')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                // Empty
                return Center(
                  child: Image.asset(
                    Constants.noDataImage,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Image.asset(
                        Constants.errorImage,
                      ),
                    ),
                  ),
                );
              } else {
                // Has data
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = isFavouriteType
                        ? RecipeModel.fromJson(
                            snapshot.data!.docs[index].data())
                        : MealItemModel.fromJson(
                            snapshot.data!.docs[index].data());
                    return buildContent(data);
                  },
                );
              }
            } else if (snapshot.hasError) {
              // Error
              return const Center(
                  child: Text('An error has occurred!',
                      maxLines: 3,
                      style: TextStyle(
                          color: Colors
                              .black))); //isDarkTheme ? Colors.white : Colors.black)));
            } else {
              // Loading
              return Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColours.primaryColour)
                      //isDarkTheme ? Colors.blue : AppColours.primaryColour),
                      ));
            }
          },
        ),
      ),
    );
  }
}
